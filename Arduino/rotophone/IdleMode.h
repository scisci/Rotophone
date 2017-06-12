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
   startTime_(0),
   dispatcher_(NULL),
   statusIndicator_(NULL),
   host_(NULL),
   waitingForStop_(false)
  {}

  virtual void init(Resources *resources) {
    stepper_ = resources->stepper();
    eventQueue_ = resources->eventQueue();
    dispatcher_ = resources->dispatcher();
    statusIndicator_ = resources->statusIndicator();
    errorLog_ = resources->errorLog();
    host_ = resources->host();
  }
  
  virtual ModeType mode() {
    return kModeIdle;  
  }

  virtual void begin() {
    stepper_->stop();
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

      // No host, or host has to be connected for 5 seconds so it can init;
      if (!host_->isConnected() || millis() - host_->startTime() < 5000) {
        return;
      }
            
      if (elapsed > 3000 && stepper_->needsCalibration()) {
        dispatcher_->dispatchSetModeCommand(kModeCalibrate);
        return;
      }
      
      if (elapsed > 7000) {
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
  Host *host_;
  StatusIndicator *statusIndicator_;
  unsigned long startTime_;
  bool waitingForStop_;
};


#endif // Rotophone_Idle_Mode_h

