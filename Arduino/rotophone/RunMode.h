#ifndef Rotophone_Run_Mode_h
#define Rotophone_Run_Mode_h

#include "Mode.h"



class RunMode : public Mode {
public:
  RunMode()
  :stepper_(NULL)
   {}

  virtual void init(Resources *resources) {
    stepper_ = resources->stepper();
  }
  
  virtual uint8_t mode() {
    return kModeRun;  
  }

  virtual void begin() {
    Serial.println("\nBegin run.");
  }

  virtual void end() {
    Serial.println("\nEnd run.");
  }
  
  virtual void loop() {
    stepper_->run();
  }

  virtual int handleCommand(Command *cmd) {
    switch (cmd->type()) {
      case kSetPosCmd:
        stepper_->setPosition(((SetPosCommand *)cmd)->pos);
        return COMMAND_HANDLED;
      case kZeroCmd:
        if (stepper_->isRunning()) {
          eventQueue_->addErrorEvent(kErrCodeZeroWhileMoving);
        } else {
          // Set the current zero
          stepper_->zero();
        }
        return COMMAND_HANDLED;
    }
    
    return COMMAND_UNHANDLED;
  }

private:
  AccelStepper *accelStepper_;
  Stepper *stepper_;
};


#endif // Rotophone_Run_Mode_h
