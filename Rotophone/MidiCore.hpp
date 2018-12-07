//
//  MidiCore.h
//  Rotophone
//
//  Created by z on 12/7/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#ifndef MIDI_CORE_H
#define MIDI_CORE_H

#include <vector>
#include <map>
#include <algorithm>

enum MidiCommand {
  kMidiCommandNoteOff = 0x80,
  kMidiCommandNoteOn = 0x90,
  kMidiCommandAftertouch = 0xA0,
  kMidiCommandControlChange = 0xB0,
  kMidiCommandProgramChange = 0xC0,
  kMidiCommandChannelPressure = 0xD0,
  kMidiCommandPitchBend = 0xE0,
};

enum MidiControlChange {
  kMidiControlChangeAllNotesOff = 0x7B,
  kMidiControlChangeAllSoundOff = 0x78,
};





class MidiMessage {
public:
  MidiMessage(const std::vector<unsigned char>& data)
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
    return !data_.empty() && ((data_[0] & 0xF0) == command);
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
  
  bool IsControlChange(int control) const noexcept
  {
    return IsCommand(kMidiCommandControlChange) && data_.size() >= 2 && data_[1] == control;
  }
  
  bool IsMatchingNote(const MidiMessage& message) const noexcept
  {
    return NoteNumber() == message.NoteNumber() && Channel() == message.Channel();
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
    return ControlChange(channel, kMidiControlChangeAllNotesOff, 0);
  }
  
  static MidiMessage AllSoundOff(int channel) noexcept
  {
    return ControlChange(channel, kMidiControlChangeAllSoundOff, 0);
  }
private:
  std::vector<unsigned char> data_;
};

class MockMidiDevice {
public:
  MockMidiDevice()
  :channel_(-1)
  {}
  
  void SetChannel(int channel)
  {
    channel_ = channel;
  }
  
  void HandleMidiMessage(const MidiMessage& message)
  {
    if (channel_ >= 0 && message.Channel() != channel_) {
      return;
    }
    
    if (message.IsNoteOn()) {
      if (active_notes_.find(message.NoteNumber()) != active_notes_.end()) {
        //NSLog(@"warning, note is already on");
      }
      active_notes_.insert(std::make_pair(message.NoteNumber(), message.NoteVelocity()));
    } else if (message.IsNoteOff()) {
      if (active_notes_.find(message.NoteNumber()) == active_notes_.end()) {
        //NSLog(@"warning, note is not on");
      }
      auto it = active_notes_.find(message.NoteNumber());
      if (it != active_notes_.end()) {
        active_notes_.erase(it);
      }
    } else if (message.IsControlChange(kMidiControlChangeAllNotesOff)) {
      active_notes_.clear();
    }
  }
  
  std::vector<int> ActiveNotes() const
  {
    std::vector<int> active_notes;
    for (auto it = active_notes_.begin(); it != active_notes_.end(); ++it) {
      active_notes.push_back(it->first);
    }
    return active_notes;
  }
  
private:
  int channel_;
  std::map<int, int> active_notes_;
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

/*!
  An immutable midi message used in Midi Message sequences. Combines time
  and a message.
*/
class MidiMessageEvent {
public:
  /*! Constructor takes ownership of the midi message. */
  MidiMessageEvent(int64_t timestamp, MidiMessage&& message)
  :message_(std::move(message)),
   timestamp_(timestamp)
  {}

  /*! Constructor copies the midi message. */
  MidiMessageEvent(int64_t timestamp, const MidiMessage& message)
  :message_(message),
   timestamp_(timestamp)
  {}
  
  const MidiMessage& Message() const
  {
    return message_;
  }
  
  int64_t Timestamp() const
  {
    return timestamp_;
  }

private:
  friend struct MidiMessageEventCompare;
  MidiMessage message_;
  int64_t timestamp_;
};

/*!
  Comparator used to sort MidiMessageEvents
*/
struct MidiMessageEventCompare
{
  bool operator()(const std::shared_ptr<const MidiMessageEvent>& lhs, const std::shared_ptr<const MidiMessageEvent>& rhs)
  {
    if (lhs->timestamp_ == rhs->timestamp_) {
      if (lhs->message_.IsNoteOff() && !rhs->message_.IsNoteOff()) {
        return true;
      }
      
      return false;
    }
    
    return lhs->timestamp_ < rhs->timestamp_;
  }
  
  bool operator()(const std::shared_ptr<const MidiMessageEvent>& lhs, const int64_t& rhs)
  {
      return lhs->timestamp_ < rhs;
  }
  
  bool operator()(const int64_t& lhs, const std::shared_ptr<const MidiMessageEvent>& rhs)
  {
      return lhs > rhs->timestamp_;
  }
};




/*!
  Immutable sequence of midi message events.
*/
class MidiMessageSequence {
public:
  MidiMessageSequence() {}
  
  typedef std::vector<std::shared_ptr<const MidiMessageEvent>> EventList;

  EventList GetEventsInRange(int64_t start, int64_t end) const
  {
    return MidiMessageSequence::GetEventsInRange(events_, start, end);
  }

  int64_t Duration() const
  {
    return duration_;
  }
  
private:
  friend class MidiMessageSequenceBuilder;
  
  /*!
    Called by sequence builder with list of events. This is private because we enforce
    certain restrictions on the events list.
  */
  MidiMessageSequence(const std::vector<std::shared_ptr<const MidiMessageEvent>>& events, int64_t duration)
  :events_(events),
   duration_(duration)
  {}
  
  /*!
    Called by sequence builder with list of events. This is private because we enforce
    certain restrictions on the events list.
  */
  MidiMessageSequence(std::vector<std::shared_ptr<const MidiMessageEvent>>&& events, int64_t duration)
  :events_(std::move(events)),
   duration_(duration)
  {}
  
  static EventList GetEventsInRange(const EventList& events, int64_t start, int64_t end)
  {
    EventList sub_events;
    auto next_event = std::lower_bound(events.begin(), events.end(), start, MidiMessageEventCompare());
    for (auto it = next_event; it < events.end(); ++it) {
      int64_t timestamp = (*it)->Timestamp();
      if (timestamp <= end) {
        sub_events.push_back(*it);
      } else {
        break;
      }
    }
    return sub_events;
  }
  
  static int64_t GetDuration(const EventList& events)
  {
    if (events.empty()) {
      return 0;
    }
    
    return events.back()->Timestamp();
  }

  int64_t duration_;
  std::vector<std::shared_ptr<const MidiMessageEvent>> events_;
};

class MidiMessageSequenceBuilder {
public:
  MidiMessageSequenceBuilder()
  :duration_(0)
  {}
  
  void Clear()
  {
    duration_ = 0;
    events_.clear();
  }
  
  std::shared_ptr<MidiMessageEvent> AddNoteEvent(int64_t timestamp, int channel, int note_num, int velocity, int64_t duration)
  {
    auto note_off_event = std::make_shared<MidiMessageEvent>(timestamp + duration, MidiMessage::NoteOff(channel, note_num, 0));
    auto note_on_event = std::make_shared<MidiMessageEvent>(timestamp, MidiMessage::NoteOn(channel, note_num, velocity));
    Insert(note_on_event);
    Insert(note_off_event);
    UpdateDuration();
    return note_on_event;
  }
  
  std::shared_ptr<MidiMessageEvent> AddEvent(int64_t timestamp, MidiMessage&& message)
  {
    auto event = std::make_shared<MidiMessageEvent>(timestamp, message);
    Insert(event);
    UpdateDuration();
    return event;
  }
  
  static MidiMessageSequence Invert(const MidiMessageSequence& seq)
  {
    MidiMessageSequenceBuilder builder;
    int64_t duration = seq.Duration();
    for (auto it = seq.events_.begin(); it != seq.events_.end(); ++it) {
      const MidiMessage& message = (*it)->Message();
      if (message.IsNoteOn()) {
        auto off_it = std::find_if(it, seq.events_.end(), [&message](const std::shared_ptr<const MidiMessageEvent>& other) -> bool {
          const MidiMessage& other_message = other->Message();
          return other_message.IsNoteOff() && other_message.NoteNumber() == message.NoteNumber() && other_message.Channel() == message.Channel();
        });

        if (off_it != seq.events_.end()) {
          int64_t off_timestamp = (*off_it)->Timestamp();
          int64_t timestamp = duration - off_timestamp;
          builder.AddNoteEvent(timestamp, message.Channel(), message.NoteNumber(), message.NoteVelocity(), off_timestamp - (*it)->Timestamp());
        } else {
          throw "Failed to find note off";
        }
      }
    }
    
    return builder.Build();
  }
  
  MidiMessageSequence Build()
  {
    return MidiMessageSequence(std::move(events_), duration_);
  }
  
  void Add(const MidiMessageSequence& other, int64_t offset)
  {
    MidiMessageEventCompare comparator;
    MidiMessageSequence::EventList rhs_events = other.GetEventsInRange(0, other.Duration());
    auto last = events_.begin();
    for (auto it = rhs_events.begin(); it != rhs_events.end(); ++it) {
      std::shared_ptr<const MidiMessageEvent> clone = *it;
      if (offset != 0) {
        clone.reset(new MidiMessageEvent((*it)->Timestamp() + offset, (*it)->Message()));
      }
      
      auto next_event = std::upper_bound(last, events_.end(), clone, comparator);
      last = events_.insert(next_event, clone);
    }
    
    UpdateDuration();
  }
  
  void SetDuration(int64_t duration)
  {
    duration_ = duration;
    UpdateDuration();
  }
  
  
  int64_t Duration() const
  {
    return duration_;
  }
  
private:
  void UpdateDuration()
  {
    int64_t duration = MidiMessageSequence::GetDuration(events_);
    if (duration >= duration_) {
      duration_ = duration;
    }
  }
  void Insert(std::shared_ptr<MidiMessageEvent> event)
  {
    auto next_event = std::upper_bound(events_.begin(), events_.end(), event, MidiMessageEventCompare());
    events_.insert(next_event, event);
  }
  
  int64_t duration_;
  std::vector<std::shared_ptr<const MidiMessageEvent>> events_;
};

class MidiTrack {
public:
  MidiTrack(int64_t offset, int64_t duration, MidiMessageSequence&& seq)
  :seq_(std::move(seq)),
   offset_(offset),
   duration_(duration)
  {}
  
  const MidiMessageSequence& Sequence() const
  {
    return seq_;
  }
  
  MidiMessageSequence::EventList GetEventsInAbsoluteRange(int64_t start, int64_t end) const
  {
    const int64_t rel_start = std::max(start - offset_, 0LL);
    const int64_t rel_end = std::max(end - offset_, 0LL);
    return seq_.GetEventsInRange(rel_start, rel_end);
  }
  
  void SetOffset(int64_t offset)
  {
    offset_ = offset;
  }
  
  const int64_t Offset() const
  {
    return offset_;
  }
  
  const int64_t Duration() const
  {
    return duration_;
  }
  
private:
  MidiMessageSequence seq_;
  int64_t offset_;
  int64_t duration_;
};

#endif /* MidiCore_h */
