#ifndef Rotophone_Status_h
#define Rotophone_Status_h

#include "Pins.h"


enum StatusType {
  kStatusTypeShortSlowBlink,
  kStatusTypeShortMediumBlink,
  kStatusTypeShortFastBlink,
  kStatusTypeSlowBlink, 
  kStatusTypeMediumBlink, 
  kStatusTypeFastBlink,
  kStatusTypeMedium2Blink,
  kStatusTypeMedium3Blink,
  kStatusTypeMedium4Blink
};



class StatusPattern {
  public:

  void setType(StatusType type) {
    switch (type) {
      case kStatusTypeShortSlowBlink:
        patternSize = 2;
        pattern[0] = 20;
        pattern[1] = 2000;
        break;
      case kStatusTypeSlowBlink:
        patternSize = 2;
        pattern[0] = 500;
        pattern[1] = 500;
        break;
      case kStatusTypeShortMediumBlink:
        patternSize = 2;
        pattern[0] = 20;
        pattern[1] = 1000;
        break;
      case kStatusTypeMediumBlink:
        patternSize = 2;
        pattern[0] = 200;
        pattern[1] = 200;
        break;
      case kStatusTypeShortFastBlink:
        patternSize = 2;
        pattern[0] = 20;
        pattern[1] = 100;
        break;
      case kStatusTypeFastBlink:
        patternSize = 2;
        pattern[0] = 50;
        pattern[1] = 50;
        break;
      case kStatusTypeMedium2Blink:
        patternSize = 4;
        pattern[0] = 100;
        pattern[1] = 200;
        pattern[2] = 100;
        pattern[3] = 600;
        break;
      case kStatusTypeMedium3Blink:
        patternSize = 5;
        pattern[0] = 100;
        pattern[1] = 200;
        pattern[2] = 100;
        pattern[3] = 200;
        pattern[4] = 100;
        pattern[5] = 600;
        break;
       case kStatusTypeMedium4Blink:
        patternSize = 5;
        pattern[0] = 100;
        pattern[1] = 200;
        pattern[2] = 100;
        pattern[3] = 200;
        pattern[4] = 100;
        pattern[5] = 200;
        pattern[6] = 100;
        pattern[7] = 600;
        break;
      default:
        patternSize = 2;
        pattern[0] = 20;
        pattern[1] = 1000;
    }
  }
  uint8_t patternSize;
  uint16_t pattern[16]; 
};

class StatusCursor {
  public:

  void setPattern(StatusPattern *pattern) {
    // Calculate the duration
    duration = 0;
    for (int i = 0; i < pattern->patternSize; i++) {
      duration += pattern->pattern[i];
    }
  
    position = -1;
    startTime = 0;
  }

  void start(unsigned long now) {
    startTime = now;
    nextUpdate = now;
  }

  void update(StatusPattern *pattern, unsigned long now) {
    if (now < nextUpdate) {
      return;
    }
    
    int elapsed = (now - startTime) % duration;
    int timeCounter = 0;
    int nextPosition = 0;
    for (int i = 0; i < pattern->patternSize; i++) {
      timeCounter += pattern->pattern[i];
      if (timeCounter >= elapsed) {
        nextPosition = i;
        break;
      }
    }
  
    nextUpdate = now + (timeCounter - elapsed);
    
    if (nextPosition != position) {
      if (nextPosition & 1) {
        digitalWrite(STATUS_PIN, LOW);
      } else {
        digitalWrite(STATUS_PIN, HIGH);
      }
  
      position = nextPosition;
    }
  }
  
  int duration;
  int position;
  long startTime;
  unsigned long nextUpdate;
};


class StatusIndicator {
public:
  StatusIndicator()
  :typeStackPos_(0)
  {}

  bool set(StatusType type) {
    pop();
    push(type);
  }
  
  bool push(StatusType type) {
    if (typeStackPos_ == 8) {
      return false;
    }
    
    typeStack_[typeStackPos_++] = type;
    pattern_.setType(type);
    cursor_.setPattern(&pattern_);
    cursor_.start(millis());
    return true;
  }

  bool pop() {
    if (typeStackPos_ == 0) {
      return false;
    }

    StatusType type = typeStack_[--typeStackPos_];
    pattern_.setType(type);
    cursor_.setPattern(&pattern_);
    cursor_.start(millis());
    return true;
  }

  void run(unsigned long now) {
    cursor_.update(&pattern_, now);
  }
private:
  StatusCursor cursor_;
  StatusPattern pattern_;
  StatusType typeStack_[8];
  uint8_t typeStackPos_;
};



#endif // Rotophone_Status_h
