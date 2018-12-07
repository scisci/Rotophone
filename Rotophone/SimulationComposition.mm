//
//  SimulationComposition.m
//  Rotophone
//
//  Created by z on 11/27/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "SimulationComposition.h"
#include "htree/Tree.hpp"
#include "htree/RandomBasicGenerator.hpp"
#include "htree/Golden.hpp"
#include "htree/RegionIterator.hpp"
#include "htree/Geometry.hpp"
#include <vector>
#include <set>
#include <random>

#include "MidiCore.hpp"
#include "MidiFileSequenceReader.hpp"


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

class TreeComposition {
public:
  TreeComposition()
  :rng_(rd_())
  {}
  
  void AddFreq(double freq)
  {
    freqs_.push_back(freq);
  }
  
  void Init() {
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
      scrubber_.SetSequence(tracks[0].Sequence());
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
    const double timescale = 48000;
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
    comp_.Init();
    
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
  auto tracks = reader.ReadAllTracks(48000);
  for (const auto& track : tracks) {
    NSLog(@"got a track of length %lld", track.Duration());
  }
  comp_.SetMidiTracks(tracks);
}

- (void)updatePosition:(double)position andVelocity:(double)velocity andValid:(bool)velocityValid
{
  const int64_t duration = comp_.Duration();
  const int64_t playhead = duration * position / (2.0 * M_PI);
  //const int dir = velocityValid ? (velocity < 0.0 ? -1 : 1) : 0;
  
  const MidiMessageSequence::EventList events = comp_.Update(playhead);
  if (!events.empty()) {
    for (const auto& event : events) {
      [self sendMessage:event->Message()];
    }
  }
}


@end
