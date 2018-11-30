//
//  SimulationComposition.m
//  Rotophone
//
//  Created by z on 11/27/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "SimulationComposition.h"
#include <vector>
#include <set>

enum MidiCommand {
  kMidiCommandNoteOff = 0x80,
  kMidiCommandNoteOn = 0x90,
  kMidiCommandAftertouch = 0xA0,
  kMidiCommandControlChange = 0xB0,
  kMidiCommandProgramChange = 0xC0,
  kMidiCommandChannelPressure = 0xD0,
  kMidiCommandPitchBend = 0xE0,
};



class MidiMessage {
public:
  MidiMessage(std::vector<unsigned char> data)
  :data_(data)
  {}
  
  MidiMessage(int byte1, int byte2) noexcept
  :data_({(unsigned char)byte1, (unsigned char)byte2})
  {}
  
  MidiMessage(int byte1, int byte2, int byte3) noexcept
  :data_({(unsigned char)byte1, (unsigned char)byte2, (unsigned char)byte3})
  {}
  
  const std::vector<unsigned char>& Data() const
  {
    return data_;
  }
  
  bool IsCommand(MidiCommand command) const noexcept
  {
    return !data_.empty() && data_[0] & command;
  }
  
  bool IsNoteOff() const noexcept
  {
    return IsCommand(kMidiCommandNoteOff);
  }
  
  bool IsNoteOn() const noexcept
  {
    return IsCommand(kMidiCommandNoteOn);
  }
  
  int Channel() const noexcept
  {
    if (data_.empty()) {
      return 0;
    }
    
    return data_[0] & 0xF;
  }
  
  int NoteVelocity() const noexcept
  {
    if (data_.size() < 3) {
      return 0;
    }
    
    return data_[2];
  }
  
  int NoteNumber() const noexcept
  {
    if (data_.size() < 2) {
      return 0;
    }
    
    return data_[1];
  }
  
  bool IsProgramChange() const noexcept
  {
    return IsCommand(kMidiCommandProgramChange);
  }
  
  bool IsControlChange() const noexcept
  {
    return IsCommand(kMidiCommandControlChange);
  }
  
  static MidiMessage NoteOff(int channel, int note_num, int velocity) noexcept
  {
    return MidiMessage(kMidiCommandNoteOff | (channel & 0xF), note_num, velocity);
  }
  
  static MidiMessage NoteOn(int channel, int note_num, int velocity) noexcept
  {
    return MidiMessage(kMidiCommandNoteOn | (channel & 0xF), note_num, velocity);
  }
  
  static MidiMessage ControlChange(int channel, int control_num, int control_val) noexcept
  {
    return MidiMessage(kMidiCommandControlChange | (channel & 0xF), control_num, control_val);
  }
  
  static MidiMessage ProgramChange(int channel, int program_num) noexcept
  {
    return MidiMessage(kMidiCommandProgramChange | (channel & 0xF), program_num);
  }
  
  static MidiMessage AllNotesOff(int channel) noexcept
  {
    return ControlChange(channel, 0x7B, 0);
  }
  
  static MidiMessage AllSoundOff(int channel) noexcept
  {
    return ControlChange(channel, 0x78, 0);
  }
private:
  std::vector<unsigned char> data_;
};



class SysExWriter {
public:
  SysExWriter(){}
  
  void Begin(unsigned char manufacturer_id) noexcept(false)
  {
    if (!data_.empty()) {
      throw "SysEx not empty";
    }
    
    data_.push_back(0xF0);
    data_.push_back(manufacturer_id);
  }
  
  void Push(unsigned char byte)
  {
    if (data_.empty()) {
      throw "SysEx empty";
    }
    data_.push_back(byte);
  }
  
  void Push(const unsigned char *bytes, size_t data_size)
  {
    data_.insert(data_.end(), bytes, bytes + data_size);
  }
  
  MidiMessage End() noexcept(false)
  {
    if (data_.empty()) {
      throw "SysEx empty";
    }
    
    data_.push_back(0xF7);
    MidiMessage m(std::move(data_));
    return m;
  }
  
private:
  std::vector<unsigned char> data_;
};

enum Juno106ControlNum {
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


static const unsigned char kJuno106Switch1Octave16 = 1 << 0;
static const unsigned char kJuno106Switch1Octave8 = 1 << 1;
static const unsigned char kJuno106Switch1Octave4 = 1 << 2;
static const unsigned char kJuno106Switch1Pulse = 1 << 3;
static const unsigned char kJuno106Switch1Tri = 1 << 4;
static const unsigned char kJuno106Switch1ChorusOff = 1 << 5;
static const unsigned char kJuno106Switch1Chorus2Off = 1 << 6;

static const unsigned char kJuno106Switch2LFO = 0;
static const unsigned char kJuno106Switch2Manual = 1 << 0;
static const unsigned char kJuno106Switch2Env = 0;
static const unsigned char kJuno106Switch2Gate = 1 << 1;
static const unsigned char kJuno106Switch2PolPos = 0;
static const unsigned char kJuno106Switch2PolNeg = 1 << 2;
static const unsigned char kJuno106Switch2HPF3 = 0;
static const unsigned char kJuno106Switch2HPF2 = 0x01 << 3;
static const unsigned char kJuno106Switch2HPF1 = 0x02 << 3;
static const unsigned char kJuno106Switch2HPF0 = 0x03 << 3;

class Juno106Patch {
public:
  Juno106Patch(int patch)
  :patch(patch) {
    values[kJuno106ControlLFORate] = 0;
    values[kJuno106ControlLFODelayTime] = 0;
    values[kJuno106ControlDCOLFO] = 0;
    values[kJuno106ControlDCOPWM] = 0;
    values[kJuno106ControlDCONoise] = 0;
    values[kJuno106ControlVCFFreq] = 0x40;
    values[kJuno106ControlVCFRes] = 0;
    values[kJuno106ControlVCFEnv] = 0;
    values[kJuno106ControlVCFLFO] = 0;
    values[kJuno106ControlVCFKybd] = 0x7F;
    values[kJuno106ControlVCALevel] = 0x7F;
    values[kJuno106ControlEnvAttack] = 0;
    values[kJuno106ControlEnvDecay] = 0x40;
    values[kJuno106ControlEnvSustain] = 0x40;
    values[kJuno106ControlEnvRelease] = 0x40;
    values[kJuno106ControlDCOSub] = 0x7F;
    values[kJuno106ControlSwitch1] = kJuno106Switch1Octave8 | kJuno106Switch1Pulse | kJuno106Switch1Tri;
    values[kJuno106ControlSwitch2] = kJuno106Switch2Manual | kJuno106Switch2Env | kJuno106Switch2PolPos | kJuno106Switch2HPF0;
  }

  unsigned char patch;
  unsigned char values[18];
};

class Juno106SysExWriter : public SysExWriter {
public:
  Juno106SysExWriter()
  :SysExWriter() {}
  
  MidiMessage ControlChange(int channel, Juno106ControlNum control_num, int control_value) noexcept(false)
  {
    Begin(0x41);
    Push(0x32); // Control change
    Push(channel & 0xF); // Channel
    Push(control_num);
    Push(control_value);
    return End();
  }
  
  MidiMessage PatchChange(int channel, int patch) noexcept(false)
  {
    Begin(0x41);
    Push(0x30);
    Push(channel & 0xF);
    Push(patch & 0xF);
    return End();
  }
  
  MidiMessage ManualPatchChange(int channel, const Juno106Patch& patch) noexcept(false)
  {
    Begin(0x41);
    Push(0x31);
    Push(channel & 0xF);
    Push(patch.patch);
    Push(&patch.values[0], sizeof(patch.values));
    return End();
  }
};

class MidiMessageEvent {
public:
  MidiMessageEvent(int64_t timestamp, MidiMessage&& message)
  :MidiMessageEvent(timestamp, std::move(message), nullptr)
  {}
  
  MidiMessageEvent(int64_t timestamp, MidiMessage&& message, std::shared_ptr<const MidiMessageEvent> note_off)
  :message_(std::move(message)),
   timestamp_(timestamp),
   note_off_(note_off)
  {}
  
  const MidiMessage& Message() const
  {
    return message_;
  }
  
  int64_t Timestamp() const
  {
    return timestamp_;
  }
  
  std::shared_ptr<const MidiMessageEvent> NoteOffEvent() const
  {
    return note_off_;
  }

private:
  friend struct MidiMessageEventCompare;
  std::shared_ptr<const MidiMessageEvent> note_off_;
  MidiMessage message_;
  int64_t timestamp_;
};

struct MidiMessageEventCompare
{
  bool operator()(const std::shared_ptr<MidiMessageEvent>& lhs, const std::shared_ptr<MidiMessageEvent>& rhs)
  {
    if (lhs->timestamp_ == rhs->timestamp_) {
      if (lhs->message_.IsNoteOff() && !rhs->message_.IsNoteOff()) {
        return true;
      }
      
      return false;
    }
    
    return lhs->timestamp_ < rhs->timestamp_;
  }
  
  bool operator()(const std::shared_ptr<MidiMessageEvent>& lhs, const int64_t& rhs)
  {
      return lhs->timestamp_ < rhs;
  }
  
  bool operator()(const int64_t& lhs, const std::shared_ptr<MidiMessageEvent>& rhs)
  {
      return lhs > rhs->timestamp_;
  }
};

class MidiBufferWriter {
public:
  void Reset()
  {
    buffer_.clear();
  }
  
  void Write(const MidiMessage& message)
  {
    const std::vector<unsigned char>& data = message.Data();
    buffer_.insert(buffer_.end(), data.begin(), data.end());
  }
  
  const std::vector<unsigned char>& Buffer() const
  {
    return buffer_;
  }
  
private:
  std::vector<unsigned char> buffer_;
};

class MidiMessageSequence {
public:
  typedef std::vector<std::shared_ptr<const MidiMessageEvent>> EventList;
  
  std::shared_ptr<MidiMessageEvent> AddNoteEvent(int64_t timestamp, int channel, int note_num, int velocity, int64_t duration)
  {
    std::shared_ptr<MidiMessageEvent> note_off_event(new MidiMessageEvent(timestamp + duration, MidiMessage::NoteOff(channel, note_num, 0)));
    std::shared_ptr<MidiMessageEvent> note_on_event(new MidiMessageEvent(timestamp, MidiMessage::NoteOn(channel, note_num, velocity), note_off_event));
    
    // Find the point it should be inserted which is where timestamp
    Insert(note_on_event);
    Insert(note_off_event);
    return note_on_event;
  }
  
  // Get all events (start, end)
  EventList GetEventsInRange(int64_t start, int64_t end) const
  {
    std::vector<std::shared_ptr<const MidiMessageEvent>> events;
    auto next_event = std::lower_bound(events_.begin(), events_.end(), start, MidiMessageEventCompare());
    for (auto it = next_event; it < events_.end(); ++it) {
      int64_t timestamp = (*it)->Timestamp();
      if (timestamp <= end) {
        events.push_back(*it);
      } else {
        break;
      }
    }
    return events;
  }
  
  MidiMessageSequence Invert() const
  {
    MidiMessageSequence inv_seq_;
    int64_t duration = Duration();
    for (auto it = events_.begin(); it != events_.end(); ++it) {
      const MidiMessage& message = (*it)->Message();
      if (message.IsNoteOn()) {
        std::shared_ptr<const MidiMessageEvent> note_off = (*it)->NoteOffEvent();
        if (note_off != nullptr) {
          int64_t timestamp = duration - note_off->Timestamp();
          inv_seq_.AddNoteEvent(timestamp, message.Channel(), message.NoteNumber(), message.NoteVelocity(), note_off->Timestamp() - (*it)->Timestamp());
        }
      }
    }
    return inv_seq_;
  }
  
  int64_t Duration() const
  {
    if (events_.empty()) {
      return 0;
    }
    
    return events_.back()->Timestamp();
  }
  
private:
  void Insert(std::shared_ptr<MidiMessageEvent> event)
  {
    auto next_event = std::upper_bound(events_.begin(), events_.end(), event, MidiMessageEventCompare());
    events_.insert(next_event, event);
  }
  
  std::vector<std::shared_ptr<MidiMessageEvent>> events_;
};

@interface SimulationComposition()
{
  id<SimulationCompositionDelegate> delegate_;
  
  int64_t position_;
  int dir_;
  
  bool notes_active_;
  MidiBufferWriter buf_;
  MidiMessageSequence seq_;
  MidiMessageSequence inv_seq_;
}

@end

@implementation SimulationComposition

- (instancetype)initWithDelegate:(id<SimulationCompositionDelegate>)delegate
{
  if (self = [super init]) {
    delegate_ = delegate;
    position_ = 0;
    notes_active_ = false;
    dir_ = 0;
    
    double ticks_per_sec = 44100.0;
    
    for (int i = 0; i < 4; i++) {
      seq_.AddNoteEvent(i * ticks_per_sec, 0, 44 + i, 127, 1 * ticks_per_sec);
    }
  
    inv_seq_ = seq_.Invert();
  }
  
  return self;
}

- (void)sendMessage:(const MidiMessage&)message
{
  const std::vector<unsigned char>& data = message.Data();
  [delegate_ sendMidiData:&data[0] ofSize:data.size()];
}

- (void)updatePosition:(double)position andVelocity:(double)velocity andValid:(bool)velocityValid
{
  int64_t duration = seq_.Duration();
  int64_t playhead = duration * position / (2.0 * M_PI);
/*
  if (!velocityValid) {
    if (notes_active_) {
      NSLog(@"clearing all notes");
      notes_active_ = false;
      // Its a reset, so clear any midi events
      [self sendMessage:MidiMessage::AllNotesOff(0)];
    }
    
    position_ = playhead;
    dir_ = 0;
  } else {
  */
    const MidiMessageSequence* seq = &seq_;
    int dir = velocityValid ? (velocity < 0.0 ? -1 : 1) : dir_;
    
    if (playhead == position_ && dir == dir_) {
      return;
    }
    
    // If the direction changed then start from the current position
    // otherwise the current position was already played so start
    // one tick in.
    int64_t start = dir == dir_ ? position_ + dir : position_;
    int64_t end = playhead;
    
    position_ = playhead;
    dir_ = dir;
    
    NSLog(@"Position %f %d", position, position_);
    if (dir == -1) {
      seq = &inv_seq_;
      start = duration - start;
      end = duration - end;
    }
    
    MidiMessageSequence::EventList events;
    
    if (end < start) {
      MidiMessageSequence::EventList end_events = seq->GetEventsInRange(start, duration);
      MidiMessageSequence::EventList start_events = seq->GetEventsInRange(0, end);
      events.insert(events.end(), end_events.begin(), end_events.end());
      events.insert(events.end(), start_events.begin(), start_events.end());
    } else {
      //NSLog(@"Check %d %d", start, end);
      MidiMessageSequence::EventList elapsed_events = seq->GetEventsInRange(start, end);
      events.insert(events.end(), elapsed_events.begin(), elapsed_events.end());
    }
    
    if (!events.empty()) {
      notes_active_ = true;
      for (auto& event : events) {
        
        //NSLog(@"got note event %d noteon:%d", event->Message().NoteNumber(), event->Message().IsNoteOn());
        [self sendMessage:event->Message()];
      }
    }
  //}
}

- (void)flush
{
/*
  auto& buf = buf_.Buffer();
  if (!buf.empty()) {
    NSLog(@"flushing %d bytes", buf.size());
    [delegate_ sendMidiData:&buf[0] ofSize:buf.size()];
    buf_.Reset();
  }
  */
}


@end
