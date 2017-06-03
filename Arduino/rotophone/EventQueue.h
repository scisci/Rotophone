#ifndef Rotophone_EventQueue_h
#define Rotophone_EventQueue_h

#include "Serial.h"

#define EVENT_QUEUE_SIZE 128 // Must be a power of 2
#define EVENT_QUEUE_BLOCK 1
#define EVENT_QUEUE_NONBLOCK 0



class EventQueue {
public:
  EventQueue()
  :start_(0),
   size_(0),
   curEventCmd_(0),
   curEventSize_(0)
  {}

  void startEvent(uint8_t cmd) {
    curEventSize_ = 0;
    curEventData_[curEventSize_++] = kSerialHeader;
    curEventData_[curEventSize_++] = cmd;
  }

  
  void addEventData(uint8_t value) {
    curEventData_[curEventSize_++] = value;
  }

  void addEventData(uint16_t value) {
    curEventData_[curEventSize_++] = value >> 8;
    curEventData_[curEventSize_++] = value;
  }

  void addEventData(int16_t value) {
    curEventData_[curEventSize_++] = value >> 8;
    curEventData_[curEventSize_++] = value;
  }

  void addChecksum(uint16_t offset) {
    uint8_t checksum = 0;
    for (int i = 2 + offset; i < curEventSize_; i++) {
      checksum += curEventData_[i];
    }
    curEventData_[curEventSize_++] = checksum;
  }

  void addEventData(uint8_t *buffer, uint16_t size) {
    for (int i = 0; i < size; i++) {
      curEventData_[curEventSize_++] = buffer[i];
    }
  }

  
  bool finishEvent(bool block) {
    curEventData_[curEventSize_++] = kSerialTrailer;
    bool result = add(&curEventData_[0], curEventSize_, block);
    curEventSize_ = 0;
    return result;
  }

  bool addEvent(uint8_t cmd, bool block) {
    startEvent(cmd);
    return finishEvent(block);
  }

  bool addEvent(uint8_t cmd, uint8_t value, bool block) {
    startEvent(cmd);
    addEventData(value);
    return finishEvent(block);
  }

  bool addEvent(uint8_t cmd, uint16_t value, bool block) {
    startEvent(cmd);
    addEventData(value);
    return finishEvent(block);
  }

  bool addErrorEvent(uint16_t errorCode) {
    return addEvent(kErrEvent, errorCode, EVENT_QUEUE_BLOCK);
  }

  bool addHandshakeEvent(uint8_t handshakeID, uint8_t mode) {
    return addEvent(kHandshakeEvent, (uint16_t)handshakeID << 8 | mode, EVENT_QUEUE_BLOCK);
  }

  bool addModeChangedEvent(uint8_t mode) {
    return addEvent(kCurModeEvent, mode, EVENT_QUEUE_BLOCK);
  }

  bool addHeartBeatEvent() {
    return addEvent(kHeartBeatEvent, EVENT_QUEUE_NONBLOCK);
  }



  
  uint16_t dispatch(bool block) {
    int16_t writeSize = size_;
  
    if (block == EVENT_QUEUE_NONBLOCK && Serial.availableForWrite() < writeSize) {
      writeSize = Serial.availableForWrite();
    }
  
    return dispatchStream(&Serial, writeSize);
  }

  uint16_t dispatchStream(Stream* stream, int16_t writeSize) {
    uint16_t endPos = start_ + writeSize;
    
    // Check if it wraps around, if so, we need two writes.
    if (endPos <= EVENT_QUEUE_SIZE) {
      stream->write(&queue_[start_], endPos - start_);
    } else {
      stream->write(&queue_[start_], EVENT_QUEUE_SIZE - start_);
      stream->write(&queue_[0], endPos & (EVENT_QUEUE_SIZE - 1));
    }
  
    start_ = (start_ + writeSize) & (EVENT_QUEUE_SIZE - 1);
    size_ -= writeSize;
    return writeSize;
  }

  uint16_t copyEventQueue(uint16_t offset, uint8_t *dst, uint16_t size) {
    if (size > size_) {
      size = size_;
    }
    for (int i = 0; i < size; i++) {
      dst[i] = queue_[(start_ + i + offset) & (EVENT_QUEUE_SIZE - 1)];
    }

    return size;
  }

  uint8_t* internalQueue() {
    return &queue_[0];
  }

  uint16_t size() {
    return size_;
  }

  uint16_t start() {
    return start_;
  }

private:

  // Writes a contiguous block of data to the event queue or fails. If block is set to 
  // EVENT_QUEUE_NONBLOCK then this will quit if the amount to write plus what is 
  // in the buffer will overflow the Serial buffer causing it to block.
  bool add(uint8_t *eventData, uint16_t size, bool block) {
    if (size_ + size >= EVENT_QUEUE_SIZE) {
      return false;
    }
  
    if (block == EVENT_QUEUE_NONBLOCK && size_ + size > Serial.availableForWrite()) {
      return false;
    }
    
    for (int i = 0; i < size; i++) {
      uint16_t pos = (start_ + size_ + i) & (EVENT_QUEUE_SIZE - 1);
      queue_[pos] = eventData[i];
    }
  
    size_ += size;
    return true;
  }

  
  uint8_t queue_[EVENT_QUEUE_SIZE];
  uint16_t start_;
  uint16_t size_;

  uint8_t curEventCmd_;
  uint8_t curEventData_[EVENT_QUEUE_SIZE];
  uint8_t curEventSize_;
};
















/*
uint16_t eventQueueRead(uint8_t *readBuffer, uint16_t maxSize) {
  uint16_t readSize = maxSize;
  if (eventQueueSize < readSize) {
    readSize = eventQueueSize;
  }

  for (uint16_t i = 0; i < readSize; i++) {
    *readBuffer = eventQueue[eventQueueStart];
    readBuffer++;
    eventQueueStart = (eventQueueStart + 1) & (EVENT_QUEUE_SIZE - 1);
    eventQueueSize--;
  }

  return readSize;
}
*/



#endif // Rotophone_EventQueue_h
