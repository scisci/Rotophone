#ifndef Rotophone_LowPower_Mode_h
#define Rotophone_Lo

#include "Mode.h"


class LowPowerMode : public Mode {
public:
  LowPowerMode()
  :errorLog_(NULL),
   stepper_(NULL),
   eventQueue_(NULL),
   status_(0),
   startTime_(0)
  {}

  virtual void init(Resources *resources) {
    errorLog_ = resources->errorLog();
    stepper_ = resources->stepper();
    eventQueue_ = resources->eventQueue();
  }
  
  virtual uint8_t mode() {
    return kModeLowPower;  
  }

  virtual void begin() {
    // We clear all errors
    errorLog_->clear();
    startTime_ = millis();
  }

  virtual void end() {
  }
  
  virtual void loop() {
    if (stepper_->isRunning()) {
      stepper_->run();
      return;
    }

    unsigned long elapsed = millis() - startTime_;

    if (status_ == 0 && elapsed > 1000) {
      status_ = 1;
      // Disable motor
      digitalWrite(SERVO_ENABLE_PIN, HIGH);
    }

    if (status_ == 1 && elapsed > 2000) {
      status_ = 2;
      // Disable 24V
      digitalWrite(LOW_POWER_MODE_PIN, HIGH);
    }
  }

  virtual int handleCommand(Command *cmd) {
    if (stepper_->isRunning()) {
      // Need to wait for stepper to stop before handling any commands
      // this will even prevent changing of modes and everything.
      eventQueue_->addErrorEvent(kErrCodeNotReady);
      return COMMAND_HANDLED;
    }
    return COMMAND_UNHANDLED;
  }
private:
  ErrorLog *errorLog_;
  Stepper *stepper_;
  EventQueue *eventQueue_;
  unsigned long startTime_;
  uint8_t status_;
};


#endif // Rotophone_Lo

