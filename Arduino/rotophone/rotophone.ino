
#include "Serial.h"
#include "EventQueue.h"
#include "Stepper.h"
#include "Status.h"
#include "StartupMode.h"
#include "IdleMode.h"
#include "RunMode.h"
#include "LowPowerMode.h"
#include "CalibrationMode.h"
#include "Pins.h"
#include "Interrupts.h"
#include "Parser.h"
#include "Settings.h"


#ifdef TESTS
#include "Tests.h"
#endif

#define HEART_BEAT_INTERVAL 5000



class App : public Resources, public CommandHandler, public ProximityInterrupt {
public:
  static App& getInstance() {
    static App instance; // Guaranteed to be destroyed.
                            // Instantiated on first use.
    return instance;
  }
        
  App()
  :curMode_(NULL),
   stepper_(&eventQueue_, AccelStepper::DRIVER, SERVO_CLOCK_PIN, SERVO_DIRECTION_PIN),
   settings_(&stepper_),
   reader_(&Serial, &dispatcher_, &parserFactory_),
   lastHeartBeat_(0),
   lastProx_(0),
   handshakeID_(-1)
  {
    startupMode_.init(this);
    idleMode_.init(this);
    calibrationMode_.init(this);
    runMode_.init(this);
    lowPowerMode_.init(this);
    dispatcher_.pushCommandHandler(this);
    statusIndicator_.push(kStatusTypeSlowBlink);
  }

 
  virtual int handleCommand(Command *cmd) {
    if (cmd == NULL) {
      Serial.println("\nNull command!");
      return COMMAND_HANDLED;
    }
    switch(cmd->type()) {
      case kSetModeCmd:
        setMode(((SetModeCommand *)cmd)->mode);
        return COMMAND_HANDLED;
      case kModeCompleteCmd:
        if ((curMode_ == &startupMode_ && startupMode_.isComplete()) ||
            (curMode_ == &calibrationMode_ && calibrationMode_.isComplete())) {
          setMode(kModeIdle);
        }
        break;
      case kHandshakeCmd:
        handshakeID_ = ((HandshakeCommand *)cmd)->handshakeID;
        // Emit it back
        if (curMode_ != NULL) {
          eventQueue_.addHandshakeEvent(handshakeID_, curMode_->mode());
        }
        break;
      case kLoadCmd:
        if (settings_.loadData((DataCommand *)cmd) != 0) {
          eventQueue_.addErrorEvent(kErrIncorrectDataFormat);
        }
        break;
        
      case kSaveCmd:
        settings_.saveData(&eventQueue_);
        break;
    }
    
    return COMMAND_HANDLED;
  }

  virtual EventQueue* eventQueue() {
    return &eventQueue_;
  }

  virtual Stepper* stepper() {
    return &stepper_;
  }

  virtual CommandDispatcher* dispatcher() {
    return &dispatcher_;
  }

  virtual ProximityInterrupt* proximityInterrupt() {
    return this;
  }

  virtual SerialReader* reader() {
    return &reader_;
  }

  virtual StatusIndicator* statusIndicator() {
    return &statusIndicator_;
  }

  virtual ErrorLog* errorLog() {
    return &errorLog_;
  }

  

  void setMode(uint8_t mode) {
    Mode *nextMode = NULL;
    switch (mode) {
      case kModeLowPower:
        nextMode = &lowPowerMode_;
        break;
      case kModeStartup:
        nextMode = &startupMode_;
        break;
      case kModeIdle:
        nextMode = &idleMode_;
        break;
      case kModeCalibrate:
        nextMode = &calibrationMode_;
        break;
      case kModeRun:
        nextMode = &runMode_;
        break;
      default:
        eventQueue_.addErrorEvent(kErrCodeInvalidMode);
        return;
    }
    
    if (nextMode == curMode_) {
      return;
    }

/*
    if (stepper_.isRunning()) {
      Serial.println("\nCan't change mode, stepper is still running.");
      // Need to wait for stepper to stop before handling any commands
      // this will even prevent changing of modes and everything.
      eventQueue_.addErrorEvent(kErrCodeNotReady);
      return;
    }
    */

    // Low Power Must be followed by startup
    // Startup must be preceded by low power
    if ((curMode_ == &lowPowerMode_ && mode != kModeStartup) ||
        (curMode_ != NULL && curMode_ != &lowPowerMode_ && mode == kModeStartup)) {
      eventQueue_.addErrorEvent(kErrCodeStartupAfterLowPower);
      return;
    }

    if (curMode_ != NULL) {
      curMode_->end();
      statusIndicator_.pop();
      dispatcher_.popCommandHandler(curMode_);
    }

    curMode_ = nextMode;

    if (curMode_ != NULL) {
      dispatcher_.pushCommandHandler(curMode_);
      statusIndicator_.push(getStatusTypeForMode(mode));
      curMode_->begin();

      // Notify that we changed modes
      eventQueue_.addModeChangedEvent(mode);
    }
  }

  StatusType getStatusTypeForMode(uint8_t mode) {
    switch (mode) {
      case kModeStartup: return kStatusTypeMediumBlink;
      case kModeIdle: return kStatusTypeSlowBlink;
      case kModeRun: return kStatusTypeShortMediumBlink;
      case kModeCalibrate: return kStatusTypeShortFastBlink;
      case kModeLowPower: return kStatusTypeShortSlowBlink;
      default: return kStatusTypeFastBlink;
    }
  }

  void loop() {
    unsigned long now = millis();

    // Run the current mode
    curMode_->loop();

    // Dispatch the handshake signal if we have a host
    if (handshakeID_ > -1 && now - lastHeartBeat_ > HEART_BEAT_INTERVAL) {
      lastHeartBeat_ = now;
      eventQueue_.addHeartBeatEvent();
    }

     // Read serial and dispatch commands.
    reader_.read();
    
    // Non-blocking serial write.
    eventQueue_.dispatch(EVENT_QUEUE_NONBLOCK);

    // Update the status LED
    statusIndicator_.run(now);
  }
protected:

static void handleProximityInterrupt() {
  App::getInstance().fireProximity();
}

  virtual void attachProximity() {
    attachInterrupt(digitalPinToInterrupt(PROX_PIN), App::handleProximityInterrupt, FALLING);
  }

  virtual void detachProximity() {
    detachInterrupt(digitalPinToInterrupt(PROX_PIN));
  }

private:
  StartupMode startupMode_;
  IdleMode idleMode_;
  CalibrationMode calibrationMode_;
  RunMode runMode_;
  LowPowerMode lowPowerMode_;

  Settings settings_;
  
  Mode *curMode_;
  Stepper stepper_;
  StatusIndicator statusIndicator_;
  EventQueue eventQueue_;
  SerialReader reader_;
  CommandDispatcher dispatcher_;
  GenericCommandParserFactory parserFactory_;
  ErrorLog errorLog_;
  unsigned long lastHeartBeat_;
  int lastProx_;
  int handshakeID_;
};



void setup() {
  App &app = App::getInstance();
  app.setMode(kModeStartup);

#ifdef TESTS
    Tests tests;
    tests.testEventQueue();
    tests.testDataCommands();
#endif

  for (;;) {
    app.loop();
  }
}






