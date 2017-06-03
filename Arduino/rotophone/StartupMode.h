#ifndef Rotophone_Startup_Mode_h
#define Rotophone_Startup_Mode_h

#include "Mode.h"

class StartupMode : public Mode {
public:
  StartupMode()
  :state_(0), 
   startTime_(0),
   stepper_(NULL),
   dispatcher_(NULL)
  {}

  virtual void init(Resources *resources) {
    stepper_ = resources->stepper();
    dispatcher_ = resources->dispatcher();
  }
  
  virtual uint8_t mode() {
    return kModeStartup;  
  }

  virtual void begin() {
    state_ = 0;
    startTime_ = millis();

    stepper_->setupPins();

    pinMode(PROX_PIN, INPUT);

    pinMode(STATUS_PIN, OUTPUT);
    pinMode(LOW_POWER_MODE_PIN, OUTPUT);
  
    // Start in Low Power Mode, disabing 24V
    digitalWrite(LOW_POWER_MODE_PIN, HIGH);
  
    // Disable motor
    digitalWrite(SERVO_ENABLE_PIN, HIGH);

    Serial.begin(115200);
    Serial.println("\nBegin Startup");
  }

  virtual void end() {
    Serial.println("\nEnd Startup.");
  }

  virtual void loop() {
    unsigned long elapsed = millis() - startTime_;
    
    if (state_ == 0 && elapsed > 5000) {
      state_ = 1;
      // Enable 24V
      digitalWrite(LOW_POWER_MODE_PIN, LOW);
    }
  
    if (state_ == 1 && elapsed > 7000) {
      state_ = 2;
      // Enable motor
      digitalWrite(SERVO_ENABLE_PIN, LOW);
    }
  
  
    if (state_ == 2 && elapsed > 9000) {
      state_ = 3;
  #ifdef TESTS
      Tests tests;
      tests.testRead(stepper_);
      tests.testLoadSave(stepper_);
  #endif

      // We're done so change mode

      dispatcher_->dispatchGenericCommand(kModeCompleteCmd);
    }
  }

  virtual int handleCommand(Command *cmd) {
    // Disable all commands during startup.
    if (!isComplete()) {
      eventQueue_->addErrorEvent(kErrCodeNotReady);
      return COMMAND_HANDLED;
    }
    
    return COMMAND_UNHANDLED;
  }

  bool isComplete() {
    return state_ == 3;
  }

private:
  uint8_t state_;
  unsigned long startTime_;
  Stepper* stepper_;
  CommandDispatcher* dispatcher_;
};


#endif // Rotophone_Startup_Mode_h
