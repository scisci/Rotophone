#ifndef Rotophone_Idle_Mode_h
#define Rotophone_Idle_Mode_h

#include "Mode.h"
#include "Stepper.h"
#include "EventQueue.h"


class IdleMode : public Mode {
public:
  IdleMode()
  :stepper_(NULL),
   eventQueue_(NULL),
   errorLog_(NULL),
   handshakeID_(-1),
   startTime_(0),
   dispatcher_(NULL),
   statusIndicator_(NULL),
   waitingForStop_(false)
  {}

  virtual void init(Resources *resources) {
    stepper_ = resources->stepper();
    eventQueue_ = resources->eventQueue();
    dispatcher_ = resources->dispatcher();
    statusIndicator_ = resources->statusIndicator();
    errorLog_ = resources->errorLog();
  }
  
  virtual uint8_t mode() {
    return kModeIdle;  
  }

  virtual void begin() {
    stepper_->stop();
    handshakeID_ = -1;
    startTime_ = millis();
    waitingForStop_ = false;
    Serial.println("\nBegin Idle.");
  }

  virtual void end() {
    stopWaiting();
    Serial.println("\nEnd Idle.");
  }

  
  
  virtual void loop() {
    // If the stepper is still running, then wait for it to stop
    if (stepper_->isRunning()) {
      stepper_->run();
      startWaiting();
      return;
    } else if (waitingForStop_) {
      stopWaiting();
    }

    unsigned long elapsed = millis() - startTime_;

    if (elapsed > 2000) {
      if (errorLog_->hasProblem()) {
          // Enter low power mode, which will clear all errors
          // and pause until user does something.
          dispatcher_->dispatchSetModeCommand(kModeLowPower);
          return;
      }
        
      if (stepper_->needsCalibration()) {
        dispatcher_->dispatchSetModeCommand(kModeCalibrate);
      } else if (elapsed > 7000) {
        dispatcher_->dispatchSetModeCommand(kModeRun);
      }
    }
    
  }

  virtual int handleCommand(Command *cmd) {
    

    return COMMAND_UNHANDLED;
  }
private:

  void startWaiting() {
   if (!waitingForStop_) {
      waitingForStop_ = true;
      statusIndicator_->push(kStatusTypeFastBlink);
    }
  }

  void stopWaiting() {
    if (waitingForStop_) {
      waitingForStop_ = false;
      statusIndicator_->pop();
    }
  }
  Stepper *stepper_;
  EventQueue *eventQueue_;
  ErrorLog *errorLog_;
  CommandDispatcher *dispatcher_;
  StatusIndicator *statusIndicator_;
  uint8_t handshakeID_;
  unsigned long startTime_;
  bool waitingForStop_;
};


#endif // Rotophone_Idle_Mode_h

