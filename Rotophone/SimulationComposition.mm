//
//  SimulationComposition.m
//  Rotophone
//
//  Created by z on 11/27/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import <AudioToolbox/AudioToolbox.h>
#import "SimulationComposition.h"
#include "htree/Tree.hpp"
#include "htree/RandomBasicGenerator.hpp"
#include "htree/Golden.hpp"
#include "htree/RegionIterator.hpp"
#include "htree/Geometry.hpp"
#include <vector>
#include <set>
#include <random>

#import "AudioMidiSettingsManager.h"

#include "MidiCore.hpp"
#include "MidiOutCore.hpp"
#include "MidiFileSequenceReader.hpp"
#include "MidiDeviceJuno106.hpp"
#include "MidiDeviceYamahaXG.hpp"

Juno106Patch my_patch(0);


@interface MidiMixerInput() {
  unsigned int _numChannels;
  unsigned char _volumes[16];
}

@end
@implementation MidiMixerInput

- (instancetype)initWithNumChannels:(unsigned int)numChannels
{
  if (self = [super init]) {
    _numChannels = numChannels > 16 ? 16 : numChannels;
    for (int i = 0; i < _numChannels; i++) {
      _volumes[i] = 0;
    }
  }
  
  return self;
}

- (unsigned int)numChannels
{
  return _numChannels;
}

- (bool)setVolume:(float)volume forChannel:(unsigned int)channel
{
  if (channel >= _numChannels) {
    return false;
  }
  
  if (volume > 1) volume = 1;
  else if (volume < 0) volume = 0;
  
  unsigned char v = volume * 0x7F;
  if (v != _volumes[channel]) {
    _volumes[channel] = v;
    return true;
  }
  
  return false;
}

- (void)copyVolumes:(unsigned char*)dst forNumChannels:(unsigned int)numChannels
{
  unsigned int size = numChannels > 16 ? 16 : numChannels;
  memcpy(dst, &_volumes[0], size * sizeof(unsigned char));
}

- (void)copyMix:(MidiMixerInput *)mixerInput
{
  _numChannels = mixerInput->_numChannels;
  memcpy(_volumes, mixerInput->_volumes, 16 * sizeof(unsigned char));
}


@end



class MidiSequenceScrubber {
public:
  MidiSequenceScrubber()
  :position_(-1),
   dir_(0)
  {}
  
  void SetSequence(const MidiMessageSequence& seq)
  {
    seq_ = seq;
    seq_inv_ = MidiMessageSequenceBuilder::Invert(seq_);
  }
  
  int64_t Position() const
  {
    return position_;
  }
 
  int64_t Duration() const
  {
    return seq_.Duration();
  }
  
  MidiMessageSequence::EventList Update(int64_t position)
  {
    MidiMessageSequence::EventList events;
    
    const int64_t last_position = position_;
    const int last_dir = dir_;
    position_ = position;

    if (position_ == last_position || last_position == -1) {
      return events;
    }
    
    // Decide the direction we are going in, it is the shortest path between position_ and position
    // If the direction changed then start from the current position
    // otherwise the current position was already played so start
    // one tick in.
    const int64_t duration = Duration();
    int64_t start = last_position;
    int64_t end = position_;

    // If the distance traveled is longer than half the sequence
    // then we should go the other way
    const int64_t dist = (end < start ? (end + duration) : end) - start;
    dir_ = (dist > duration / 2) ? -1 : 1;
    
    // If its going in the same direction as last time, then the note is already played
    if (last_dir == dir_) {
      start = (start + 1) % duration;
    }
    
    const MidiMessageSequence* seq = &seq_;
    if (dir_ == -1) {
      seq = &seq_inv_;
      start = duration - start;
      end = duration - end;
    }
  
    if (end < start) {
      MidiMessageSequence::EventList end_events = seq->GetEventsInRange(start, duration);
      MidiMessageSequence::EventList start_events = seq->GetEventsInRange(0, end);
      events.insert(events.end(), end_events.begin(), end_events.end());
      events.insert(events.end(), start_events.begin(), start_events.end());
    } else {
      MidiMessageSequence::EventList elapsed_events = seq->GetEventsInRange(start, end);
      events.insert(events.end(), elapsed_events.begin(), elapsed_events.end());
    }
    
    // Filter out repetitive events
    for (auto it = events.begin(); it != events.end();) {
      const MidiMessage& message = (*it)->Message();
      if (message.IsNoteOn() || message.IsNoteOff()) {
        auto oit = std::find_if(it + 1, events.end(), [&message](const std::shared_ptr<const MidiMessageEvent>& event) {
          return message.IsMatchingNote(event->Message());
        });
        
        if (oit != events.end()) {
          if (oit->get()->Message().IsNoteOn() != message.IsNoteOn()) {
            // We can delete both since they offset eachother,
            // delete the second item first
            events.erase(oit);
          }
          it = events.erase(it);
          continue;
        }
      }
      
      ++it;
    }

    return events;
  }
  
private:
  int64_t position_;
  int dir_;
  MidiMessageSequence seq_;
  MidiMessageSequence seq_inv_;
};



class TreeCompositionSectionBuilder {
public:
  TreeCompositionSectionBuilder(htree::RatioSourcePtr ratio_source, std::mt19937_64 rng)
  :ratio_source_(ratio_source),
   rng_(rng)
  {}

  void Reset()
  {
    trees_.clear();
  }

  void AddBlock(double ratio, int num_repeats, int64_t seed, int min_leaves, int max_leaves) noexcept(false)
  {
    std::uniform_int_distribution<> leaf_dist(min_leaves, max_leaves);
    for (int i = 0; i < num_repeats; i++) {
      int num_leaves = leaf_dist(rng_);
      htree::RandomBasicGenerator generator(ratio_source_, ratio, num_leaves, seed);
      trees_.push_back(generator.Generate());
    }
  }

  std::vector<std::unique_ptr<htree::Tree>> Build()
  {
    std::vector<std::unique_ptr<htree::Tree>> trees(std::move(trees_));
    return trees;
  }

private:
  htree::RatioSourcePtr ratio_source_;
  std::mt19937_64 rng_;
  std::vector<std::unique_ptr<htree::Tree>> trees_;
};

class TreeCompositionSection {
public:
  TreeCompositionSection(std::vector<std::unique_ptr<htree::Tree>> trees, double timescale)
  :trees_(std::move(trees))
  {}
  
  double Length() const
  {
    double len = 0;
    for (auto& tree : trees_) {
      const htree::Ratios& ratios = tree->RatioSource()->Ratios();
      len += ratios[tree->RatioIndexXY()];
    }
    return len;
  }
  
private:
  std::vector<std::unique_ptr<htree::Tree>> trees_;
};

enum RegionEventType {
  kRegionEventTypeStart,
  kRegionEventTypeEnd
};


struct RegionEvent {
  RegionEvent(RegionEventType type, htree::NodeID id, double time, double vpos)
  :type(type),
   id(id),
   time(time),
   vpos(vpos)
  {}
  
  RegionEventType type;
  htree::NodeID id;
  double time;
  double vpos;
};

std::vector<RegionEvent> GetTreeRegionEvents(const htree::Tree& tree)
{
  // Simplify regions to start and end
  std::vector<RegionEvent> events;
  //const htree::Ratios& ratios = tree.RatioSource()->Ratios();
  
  // We know the dimensions of the tree
  //double width = ratios[tree.RatioIndexXY()];
  //double height = 1.0;
  
  htree::RegionIterator region_it(tree, htree::Vector(0, 0, 0), 1.0);
  while (region_it.HasNext()) {
    htree::NodeRegion node_region = region_it.Next();
    htree::NodeID node_id = node_region.node->ID();
    // If the node is a leaf, then we add it
    if (node_region.node->Branch() == nullptr) {
      const htree::AlignedBox& aligned_box = node_region.region.AlignedBox();
      events.emplace_back(kRegionEventTypeStart, node_id, aligned_box.min().x(), aligned_box.min().y());
      events.emplace_back(kRegionEventTypeEnd, node_id, aligned_box.max().x(), aligned_box.min().y());
    }
  }
  
  std::sort(events.begin(), events.end(), [](const RegionEvent& a, const RegionEvent& b) -> bool {
    return a.time < b.time || (a.time == b.time && a.type != kRegionEventTypeStart);
  });
  
  return events;
}

const size_t kMidiDataBufferSize = 2048;
struct MidiSharedData {
  std::mutex lock;
  bool reset;
  MidiMessageSequence seq;
  Byte buffer[kMidiDataBufferSize];
  MidiBufferBuilder builder;
  Juno106SysExBuilder juno;
  unsigned char volumes[16];
  unsigned char last_volumes[16];
  MidiOutCore *midi_out;
};
// function that gets called by AUGraph before (and after) a render cycle
// this is where midi notes are given to the midi processing unit
static OSStatus GraphRenderNotify (  void *              inRefCon,
                                   AudioUnitRenderActionFlags *     ioActionFlags,
                                   const AudioTimeStamp *      inTimeStamp,
                                   UInt32              inBusNumber,
                                   UInt32              inNumberFrames,
                                   AudioBufferList *        ioData)
{
    OSStatus err = noErr;
    if (*ioActionFlags & kAudioUnitRenderAction_PreRender)
    {
      MidiSharedData *data = static_cast<MidiSharedData *>(inRefCon);
      
      
      ByteCount listSize = sizeof(data->buffer);
      MIDIPacketList *packet_list = (MIDIPacketList*)data->buffer;
      
      unsigned char volumes[16];
      
      
      // Render out the current sequence into the buffer packet list
      data->lock.lock();
      bool reset = data->reset;
      data->reset = false;
      
      // Whiel locked lets copy in the volumes
      memcpy(&volumes[0], &data->volumes[0], sizeof(volumes));
      
      MIDIPacket *seq_packet = MIDIPacketListInit(packet_list);
      
      if (reset) {
        // Select the proper programs
        
        
        data->builder.SetAllNotesOff(1);
        seq_packet = MidiOutCore::PacketListAddBuffer(packet_list, listSize, seq_packet, 0, data->builder);
        data->builder.SetProgramChange(1, 64 + 8 * (7-1) + (8-1.));
        seq_packet = MidiOutCore::PacketListAddBuffer(packet_list, listSize, seq_packet, 0, data->builder);
        
        const XGVoice& voice = kXGGtDistGtr2;
        data->builder.SetAllNotesOff(0);
        seq_packet = MidiOutCore::PacketListAddBuffer(packet_list, listSize, seq_packet, 0, data->builder);
        data->builder.SetProgramChange(0, voice.program_num, 0, voice.bank_num);
        seq_packet = MidiOutCore::PacketListAddBuffer(packet_list, listSize, seq_packet, 0, data->builder);
      }
      
      int64_t duration = data->seq.Duration();
      if (duration > 0) {
        int64_t start = ((int64_t)inTimeStamp->mSampleTime) % (duration + 1);
        int64_t end = (start + inNumberFrames - 1) % (duration + 1);
        
        // Get each item
        if (end >= start) {
          auto range = data->seq.GetEventsInRangeIterator(start, end);
          for (auto it = range.first; it != range.second; ++it) {
            const MidiMessage& message = it->get()->Message();
            seq_packet = MidiOutCore::PacketListAdd(packet_list, listSize, seq_packet, it->get()->Timestamp() - start, message.Data().size(), &message.Data()[0]);
          }
        } else {
          auto range = data->seq.GetEventsInRangeIterator(start, duration);
          for (auto it = range.first; it != range.second; ++it) {
            const MidiMessage& message = it->get()->Message();
            seq_packet = MidiOutCore::PacketListAdd(packet_list, listSize, seq_packet, it->get()->Timestamp() - start, message.Data().size(), &message.Data()[0]);
          }
          
          range = data->seq.GetEventsInRangeIterator(0, end);
          for (auto it = range.first; it != range.second; ++it) {
            const MidiMessage& message = it->get()->Message();
            seq_packet = MidiOutCore::PacketListAdd(packet_list, listSize, seq_packet, it->get()->Timestamp() + (duration - start) + 1, message.Data().size(), &message.Data()[0]);
          }
        }
        
      }
      data->lock.unlock();
      
      if (packet_list->numPackets) {
        //MidiOutCore::PacketListMerge(merge_plist, kMidiDataBufferSize, seq_plist, ctrl_plist);
        data->midi_out->SendPacketList(packet_list);
      }
      
      // Render any control data
      const int num_points = 1;

      for (int i = 0; i < 16; i++) {
        if (volumes[i] != data->last_volumes[i]) {
          MIDIPacket *ctrl_packet = MIDIPacketListInit(packet_list);
          for (int s = 0; s < num_points; s++) {
            // We need to render a volume change for this channel
            double position = (double)s / num_points; // 2 positions would be 0.0, 0.5
            double scale = num_points <= 1 ? 1 : ((double)s / (num_points - 1));
            int64_t frame = inNumberFrames * position;
            unsigned char next_vol = data->last_volumes[i] + ((double)volumes[i] - data->last_volumes[i]) * scale;
            MidiBufferBuilder* builder = nullptr;
            
            if (i == 0) {
              builder = &data->builder;
              data->builder.SetChannelVolume(i, next_vol);
            } else if (i == 1) {
              builder = &data->juno;
              data->juno.SetControlChange(i, kJuno106ControlVCFFreq, next_vol);
            }
            
            if (builder != nullptr) {
              seq_packet = MidiOutCore::PacketListAddBuffer(packet_list, listSize, seq_packet, 0, *builder);
            }
          }
          data->midi_out->SendPacketList(packet_list);
          data->last_volumes[i] = volumes[i];
        }
      }
    }
    return noErr;
}

class TreeComposition {
public:
  TreeComposition()
  :rng_(rd_()),
   graph_(nullptr)
  {
    OSStatus status = NewAUGraph(&graph_);
  }
  
  ~TreeComposition()
  {
    DisposeAUGraph(graph_);
  }
  
  void AddFreq(double freq)
  {
    freqs_.push_back(freq);
  }
  
  MidiSharedData* Storage()
  {
    return &midi_data_;
  }
  
  void Init(MidiOutCore *midi_out) {
  /*
    kJuno106ControlLFORate = 0x00,
  kJuno106ControlLFODelayTime = 0x01,
  kJuno106ControlDCOLFO = 0x02,
  kJuno106ControlDCOPWM = 0x03,
  kJuno106ControlDCONoise = 0x04,
  kJuno106ControlVCFFreq = 0x05,
  kJuno106ControlVCFRes = 0x06,
  kJuno106ControlVCFEnv = 0x07,
  kJuno106ControlVCFLFO = 0x08,
  kJuno106ControlVCFKybd = 0x09,
  kJuno106ControlVCALevel = 0x0A,
  kJuno106ControlEnvAttack = 0x0B,
  kJuno106ControlEnvDecay = 0x0C,
  kJuno106ControlEnvSustain = 0x0D,
  kJuno106ControlEnvRelease = 0x0E,
  kJuno106ControlDCOSub = 0x0F,
  kJuno106ControlSwitch1 = 0x10,
  kJuno106ControlSwitch2 = 0x11,
};
*/
    my_patch.values[kJuno106ControlLFORate] = 0x38;
    my_patch.values[kJuno106ControlLFODelayTime] = 0x43;
    my_patch.values[kJuno106ControlDCOLFO] = 0x06;
    my_patch.values[kJuno106ControlDCOPWM] = 0x09;
    my_patch.values[kJuno106ControlDCONoise] = 0x3D;
    my_patch.values[kJuno106ControlVCFFreq] = 0x67;
    my_patch.values[kJuno106ControlVCFRes] = 0x00;
    my_patch.values[kJuno106ControlVCFEnv] = 0x1E;
    my_patch.values[kJuno106ControlVCFLFO] = 0x00;
    my_patch.values[kJuno106ControlVCFKybd] = 0x40;
    my_patch.values[kJuno106ControlVCALevel] = 0x34;
    my_patch.values[kJuno106ControlEnvAttack] = 0x00;
    my_patch.values[kJuno106ControlEnvDecay] = 0x1C;
    my_patch.values[kJuno106ControlEnvSustain] = 0x4C;
    my_patch.values[kJuno106ControlEnvRelease] = 0x32;
    my_patch.values[kJuno106ControlDCOSub] = 0x7F;
    my_patch.values[kJuno106ControlSwitch1] = 0x2A;
    my_patch.values[kJuno106ControlSwitch2] = 0x1A;
    

    for (int i = 0; i < 16; i++) {
      midi_data_.volumes[i] = 0;
      midi_data_.last_volumes[i] = 0;
    }
    midi_data_.midi_out = midi_out;
    midi_data_.reset = true;
    
    AUNode out_node = NULL;
    AudioComponentDescription out_desc{ kAudioUnitType_Output, kAudioUnitSubType_DefaultOutput, kAudioUnitManufacturer_Apple, 0, 0};
    OSStatus status = AUGraphAddNode(graph_, &out_desc, &out_node);
    status = AUGraphOpen(graph_);
    status = AUGraphAddRenderNotify(graph_, GraphRenderNotify, &midi_data_);
    status = AUGraphInitialize(graph_);
    status = AUGraphStart(graph_);
    
    for (int i = 0; i < 2; i++) {
      sections_.push_back(CreateSection());
    }
    
    scrubber_.SetSequence(BuildSequence());
  }
  

  int64_t Position() const
  {
    return scrubber_.Position();
  }
  
  int64_t Duration() const
  {
    return scrubber_.Duration();
  }
  
  MidiMessageSequence::EventList Update(int64_t playhead)
  {
    return scrubber_.Update(playhead);
  }
  
  void SetMidiTracks(const std::vector<MidiTrack>& tracks)
  {
    if (!tracks.empty()) {
      //scrubber_.SetSequence(tracks[0].Sequence());
      midi_data_.lock.lock();
      midi_data_.seq = tracks[0].Sequence();
      midi_data_.lock.unlock();
    }
  }

  void RefreshUnselectedSections(double selected_pos)
  {
    return;
    if (sections_.empty()) {
      return;
    }
    
    // Figure out which section is selected
    int selected = selected_pos * sections_.size();
    
    NSLog(@"selected index %d", selected);
    
    for (int i = 0; i < sections_.size(); ++i) {
      if (i != selected) {
        sections_[i] = CreateSection();
      }
    }
    
    scrubber_.SetSequence(BuildSequence());
  }
  
  MidiMessageSequence BuildSequence()
  {
    MidiMessageSequenceBuilder builder;
    int64_t seq_offset = 0;
    int count = 0;
    for (const auto& section : sections_) {
      int64_t before = seq_offset;
      
      seq_offset += AddSectionSequence(section, seq_offset, builder);
      NSLog(@"built section %d from %d to %d", count, before, seq_offset);
      builder.SetDuration(seq_offset);
    }
    return builder.Build();
  }

  
private:
  struct Section {
    std::vector<std::unique_ptr<htree::Tree>> trees;
    double freq;
  };
  
  Section CreateSection()
  {
    htree::RatioSourcePtr ratio_source(new htree::golden::GoldenRatioSource());
    TreeCompositionSectionBuilder builder(ratio_source, rng_);

    // Block ratio
    const double block_ratio = 2.0;
    const int num_repeats = 8;
    //const int64_t seed = rng_();
    const int min_leaves = 4;
    const int max_leaves = 10;
    
    // Create 4 sections
    std::uniform_int_distribution<> freq_dist(0, (int)freqs_.size() - 1);
    int64_t seed = rng_();
    builder.AddBlock(block_ratio, num_repeats, seed, min_leaves, max_leaves);
    double freq = freqs_[freq_dist(rng_)];
    return { .trees = builder.Build(), .freq = freq};
  }
  
  int64_t AddSectionSequence(const Section& section, int64_t seq_offset, MidiMessageSequenceBuilder& builder)
  {
    const double timescale = AudioMidiSettingsManager.sharedManager.sampleRate;
    double offset = 0.0;
    
    //std::uniform_int_distribution<> choose_dist(0, 6);
    
    for (const auto& tree : section.trees) {
      const htree::Ratios& ratios = tree->RatioSource()->Ratios();
      double width = ratios[tree->RatioIndexXY()];
      double height = 1.0;

      std::map<htree::NodeID, int> active_voices;
      std::map<int, htree::NodeID> used_notes;
      
      std::vector<RegionEvent> region_events = GetTreeRegionEvents(*tree.get());
      for (auto it = region_events.begin(); it != region_events.end(); ++it) {
        const RegionEvent& event = *it;
        if (event.type == kRegionEventTypeEnd) {
          auto it = active_voices.find(event.id);
          if (it == active_voices.end()) {
            // The voice never got activated because it never got a slot
            continue;
          }
          
          used_notes.erase(it->second);
          active_voices.erase(it);
        } else if (event.type == kRegionEventTypeStart) {
          /*
          if (active_voices.size() > 1) {
            continue;
          }
          
          if (choose_dist(rng_) != 0) {
            continue;
          }
          */
          
          double ratio = 1.0 + event.vpos; // Ratio is the starting line from bottom
          double voice_freq = section.freq * ratio;
          int midi_index = (int)round(log(voice_freq/440.0)/log(2) * 12 + 69);
          // See if the note is already in use, if so, use it, otherwise
          // move up/down octaves until we find a slot
          bool found = false;
          for (int note_offset = 0; !found && note_offset < 4; note_offset++) {
            // Alternates a note down/up down/up etc.
            int note_dif = note_offset / 2 * ((note_offset & 1) ? -1 : 1);
            for (int octave_offset = 1; octave_offset < 8; octave_offset++) {
              // Alternates an octave down/up etc.
              int octave_mult = octave_offset / 2  * ((octave_offset & 1) ? -1 : 1);
              int octave_dif = octave_mult * 12;
              int resolved = midi_index + note_dif + octave_dif;
              if (resolved < 0 || resolved > 127) {
                continue;
              }

              // Is it free?
              if (used_notes.find(resolved) == used_notes.end()) {
                found = true;
                used_notes[resolved] = event.id;
                active_voices[event.id] = resolved;
                
                // Absolute time
                int64_t timestamp_on = seq_offset + (offset + event.time) * timescale;
                int64_t timestamp_off = timestamp_on;
                // Find the next off event
                for (auto next_it = it + 1; next_it != region_events.end(); ++next_it) {
                  if (next_it->id == event.id && next_it->type == kRegionEventTypeEnd) {
                    timestamp_off = seq_offset + (offset + next_it->time) * timescale;
                    break;
                  }
                }

                builder.AddNoteEvent(timestamp_on, 0, resolved, 127, timestamp_off - timestamp_on);
                break;
              }
            }
          }
        }
      }
      
      offset += width;
    }
    
    return offset * timescale;
  }
  
  std::vector<Section> sections_;
  std::random_device rd_;
  std::mt19937_64 rng_;
  std::vector<double> freqs_;
  MidiSequenceScrubber scrubber_;
  AUGraph graph_;
  MidiSharedData midi_data_;
};

@interface SimulationComposition()
{
  id<SimulationCompositionDelegate> delegate_;
  TreeComposition comp_;
  MockMidiDevice mock_device_;
}

@end

@implementation SimulationComposition

- (instancetype)initWithDelegate:(id<SimulationCompositionDelegate>)delegate andFreqs:(NSArray *)freqs
{
  if (self = [super init]) {
    delegate_ = delegate;
  
    for (NSNumber *freq in freqs) {
      comp_.AddFreq([freq doubleValue]);
    }
    comp_.Init([AudioMidiSettingsManager.sharedManager midiOutCore]);
    
    mock_device_.SetChannel(0);
   
    [self sendMessage:MidiMessage::AllNotesOff(0)];
  }
  
  return self;
}

- (void)sendMessage:(const MidiMessage&)message
{
  mock_device_.HandleMidiMessage(message);
  const std::vector<unsigned char>& data = message.Data();
  [delegate_ sendMidiData:&data[0] ofSize:data.size()];
}

- (void)refresh
{
  NSLog(@"Refresh %d %d", comp_.Position(), comp_.Duration());
  double norm_pos = (double)comp_.Position() / comp_.Duration();
  comp_.RefreshUnselectedSections(norm_pos);
}

- (void)loadMidiFile:(NSString *)path
{
  MidiFileSequenceReader reader([path cStringUsingEncoding:NSUTF8StringEncoding]);
  auto tracks = reader.ReadAllTracks([AudioMidiSettingsManager.sharedManager sampleRate]);
  for (const auto& track : tracks) {
    NSLog(@"got a track of length %lld", track.Duration());
  }
  comp_.SetMidiTracks(tracks);
}

- (void)resetMidiPrograms
{
  MidiSharedData* data = comp_.Storage();
  std::lock_guard<std::mutex> lock(data->lock);
  data->reset = true;
}

- (void)updatePosition:(double)position andVelocity:(double)velocity andValid:(bool)velocityValid
{
  const int64_t duration = comp_.Duration();
  const int64_t playhead = duration * position / (2.0 * M_PI);
  
  
  // Use this to set the
  //comp_.UpdateChannels(0x7F * position / (2.0 * M_PI));
  //const int dir = velocityValid ? (velocity < 0.0 ? -1 : 1) : 0;
  /*
  const MidiMessageSequence::EventList events = comp_.Update(playhead);
  if (!events.empty()) {
    for (const auto& event : events) {
      [self sendMessage:event->Message()];
    }
  }
  */
}


- (void)setMix:(MidiMixerInput *)mixerInput
{
  if (mixerInput == nil) {
    return;
  }
  
  MidiSharedData* data = comp_.Storage();
  std::lock_guard<std::mutex> lock(data->lock);
  [mixerInput copyVolumes:&data->volumes[0] forNumChannels:[mixerInput numChannels]];
}


@end
