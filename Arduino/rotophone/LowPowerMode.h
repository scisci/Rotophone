#ifndef Rotophone_LowPower_Mode_h
#define Rotophone_Lo

#include "Mode.h"


enum LowPowerStatus {
  kLowPowerStatusInit,
  kLowPowerStatusDisableMotor,
  kLowPowerStatusDisablePower,
  kLowPowerStatusDone
};

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
  
  virtual ModeType mode() {
    return kModeLowPower;  
  }

  virtual void begin() {
    // We clear all errors
    errorLog_->clear();
    startTime_ = millis();
    status_ = kLowPowerStatusInit;
    stepper_->stop();
  }

  virtual void end() {
  }
  
  virtual void loop() {
    if (stepper_->isRunning()) {
      stepper_->run();
      return;
    } else if (status_ == kLowPowerStatusInit) {
      status_ = kLowPowerStatusDisableMotor;
    }

    unsigned long elapsed = millis() - startTime_;

    if (status_ == kLowPowerStatusDisableMotor && elapsed > 1000) {
      status_ = kLowPowerStatusDisablePower;
      // Disable motor
      digitalWrite(SERVO_ENABLE_PIN, HIGH);
    }

    if (status_ == kLowPowerStatusDisablePower && elapsed > 2000) {
      status_ = kLowPowerStatusDone;
      // Disable 24V
      digitalWrite(LOW_POWER_MODE_PIN, HIGH);
    }
  }

  bool isComplete() {
    return status_ == kLowPowerStatusDone;
  }

  virtual int handleCommand(Command *cmd) {
    if (status_ != kLowPowerStatusDone) {
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

