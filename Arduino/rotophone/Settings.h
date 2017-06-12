#ifndef Rotophone_Settings_h
#define Rotophone_Settings_h

#include "EventQueue.h"
#include "Stepper.h"

#define DATA_VERSION 1


class Settings {
public:
  Settings(Stepper* stepper)
  :stepper_(stepper)
  {}

  int loadData(DataCommand *dataCmd) {
      if (dataCmd->dataSize < 3) {
        return -1;
      }
      
      uint8_t version = dataCmd->data[0];
      if (version != DATA_VERSION) {
        return -1;
      }

      // First two bytes are the step offset
      int16_t stepOffset = (int16_t)dataCmd->data[1] << 8 | dataCmd->data[2];
      //Serial.print("\nLoaded zero offset");
      //Serial.print(stepOffset);
      //Serial.println(".");
      stepper_->setZeroOffset(stepOffset);
      return 0;
  }

  void saveData(EventQueue* eventQueue) {
    int16_t stepOffset = stepper_->zeroOffset();

    //Serial.print("\nSaving zero offset");
     // Serial.print(stepOffset);
     // Serial.println(".");
    
    eventQueue->startEvent(kSaveEvent);
    eventQueue->addEventData((uint8_t)5); // 1 count byte, 1 version byte, 2 offset bytes, 1 checksum
    eventQueue->addEventData((uint8_t)DATA_VERSION);
    eventQueue->addEventData(stepOffset);
    eventQueue->addChecksum(1); // Offset 1 since we don't include byte count in the checksum
    eventQueue->finishEvent(EVENT_QUEUE_BLOCK);
  }

private:
  Stepper* stepper_;
};


#endif // Rotophone_Settings_h
