#ifndef Rotophone_Calibration_Mode_h
#define Rotophone_Calibration_Mode_h

#include "Mode.h"

#define CALIBRATION_LOW_QUALITY_THRESHOLD 10
#define CALIBRATION_CYCLE_THRESHOLD 10
#define PROX_FRONT_EDGE_BUFFER_STEPS 160
#define CALIB_DEBUG

enum CalibrationStatus {
  kCalibrationStatusInit,
  kCalibrationStatusFind,
  kCalibrationStatusAlternateCycle,
  kCalibrationStatusMoveOffProx,
  kCalibrationStatusMoveOffProxStop,
  kCalibrationStatusScanForProxInit,
  kCalibrationStatusInitMicroRegister,
  kCalibrationStatusScanForProx,
  kCalibrationStatusStopAfterProx,
  kCalibrationStatusMoveBackToProx,
  kCalibrationStatusCalibrate,
  kCalibrationStatusDone
};

class CalibrationMode : public Mode {
public:
  CalibrationMode()
  :stepper_(NULL),
   dispatcher_(NULL),
   statusIndicator_(NULL),
   errorLog_(NULL),
   calibrationStep_(0),
   testCalibrationStep_(0),
   status_(kCalibrationStatusInit),
   attempts_(0),
   calibrationFailed_(false),
   proxScanStarted_(false),
   proxDebounce_(0)
  {}

  virtual void init(Resources *resources) {
    dispatcher_ = resources->dispatcher();
    statusIndicator_ = resources->statusIndicator();
    stepper_ = resources->stepper();
    errorLog_ = resources->errorLog();
  }
  
  virtual uint8_t mode() {
    return kModeCalibrate;  
  }

  virtual void begin() {
    status_ = kCalibrationStatusInit;
    attempts_ = 0;
    calibrationFailed_ = false;
    stepper_->useScanSpeed();
    statusIndicator_->push(kStatusTypeShortMediumBlink);
    Serial.println("\nBegin Calibration.");
  }

  virtual void end() {
    statusIndicator_->pop();
    stepper_->useRunSpeed();
    Serial.println("\nEnd Calibration.");
  }
  
  virtual void loop() {
    // Starting point for calibrating from the beginning with no history.
    // Reset all counting vars.
    if (status_ == kCalibrationStatusInit) {
#ifdef CALIB_DEBUG
      Serial.println("\nInit calibration.");
#endif
      testCalibrationStep_ = 0;
      verifyCycle_ = 0;
      scanCount_ = 0;
      status_ = kCalibrationStatusFind;
      stepper_->useRunSpeed();
      stepper_->setStep(stepper_->stepCount() - 2000 + rand() % 2000);
    }

    // This point is reached on each sub cycle. A cycle consists of the
    // arm doing micro steps to find a step. Once it verifies that twice
    // the cycle is complete. That step can be stored and another cycle
    // can verify that cycle.
    if (status_ == kCalibrationStatusFind && !stepper_->isRunning()) {
#ifdef CALIB_DEBUG
      Serial.print("\nCalibration cycle:");
      Serial.print(verifyCycle_);
      Serial.print(" count:");
      Serial.print(scanCount_);
      Serial.println();
#endif
      
      stepper_->useRunSpeed();
      status_ = kCalibrationStatusMoveOffProx;
      proxDebounce_ = 0;
      proxScanStarted_ = false;
    }

    if (status_ == kCalibrationStatusMoveOffProx) {
      // If prox pin is low, we are on the magnet
      uint8_t proxValue = digitalRead(PROX_PIN);
      if (!proxValue) {
        proxDebounce_ = 0;
        if (!proxScanStarted_) {
#ifdef CALIB_DEBUG
          Serial.println("\nMove away from proximity CCW.");
#endif
          proxScanStarted_ = true;
          stepper_->scan(-1.0);
        }
      } else if (proxDebounce_++ > 80) {
        if (proxScanStarted_) { 
#ifdef CALIB_DEBUG
          Serial.println("\nStopping...");
#endif
          proxScanStarted_ = false;
          stepper_->stop();
        }

        status_ = kCalibrationStatusMoveOffProxStop;
      }
    }

    if (status_ == kCalibrationStatusMoveOffProxStop && !stepper_->isRunning()) {
#ifdef CALIB_DEBUG
      Serial.print("\nNow at position ");
      Serial.print(stepper_->stepCount());
      Serial.println();
#endif
      status_ = kCalibrationStatusScanForProxInit;
      stepper_->useScanSpeed();
    }

    // Now we are off the proximity but don't know where
    if (status_ == kCalibrationStatusScanForProxInit) {
      status_ = kCalibrationStatusScanForProx;
#ifdef CALIB_DEBUG
      Serial.println("\nCalibration scan CW for prox...");
#endif
      calibrationStep_ = 0;
      proxDebounce_ = 0;
      stepper_->scan(1.25);
      statusIndicator_->set(kStatusTypeMedium2Blink);
    }

    if (status_ == kCalibrationStatusScanForProx) {
      uint8_t proxValue = digitalRead(PROX_PIN);
      if (!proxValue) {
        if (proxDebounce_++ > 5) {
          calibrationStep_ = stepper_->stepCount();
          status_ = kCalibrationStatusStopAfterProx;
#ifdef CALIB_DEBUG
          Serial.print("\nFound step ");
          Serial.print(calibrationStep_);
          Serial.println();
#endif
          stepper_->stop();
          statusIndicator_->set(kStatusTypeFastBlink);
        }
      } else {
        proxDebounce_ = 0;
        if (!stepper_->isRunning()) {
          // Failed to find calibration step
#ifdef CALIB_DEBUG
          Serial.println("\nFailed to find step after full revolution, retrying...");
#endif
          if (++attempts_ == 2) { 
            // Failed
            status_ = kCalibrationStatusDone;
            calibrationFailed_ = true;
            errorLog_->addCalibrationError();
            eventQueue_->addErrorEvent(kErrCodeCalibrationFailed);
            // We're done so change mode
            dispatcher_->dispatchGenericCommand(kModeCompleteCmd);
          } else {
            status_ = kCalibrationStatusInit;
          }
        }
       
      }
      
    }
    

    if (status_ == kCalibrationStatusStopAfterProx && !stepper_->isRunning()) {
      status_ = kCalibrationStatusMoveBackToProx;
#ifdef CALIB_DEBUG
      Serial.print("\nJust found step ");
      Serial.print(calibrationStep_);
      Serial.println(".");
#endif
      // Skip the double check if this is an alternate verify cycle
      if (verifyCycle_ > 0) {
        if (abs(calibrationStep_ - stepper_->stepsPerRevolution() - cycleCalibrationStep_) < CALIBRATION_LOW_QUALITY_THRESHOLD) {
          stepper_->setStep(calibrationStep_ - PROX_FRONT_EDGE_BUFFER_STEPS);
          status_ = kCalibrationStatusInitMicroRegister;
          proxDebounce_ = 0;
        } else {
#ifdef CALIB_DEBUG
          Serial.print("\nHmm ");
          Serial.print(calibrationStep_);
          Serial.print(" is not close to ");
          Serial.print(cycleCalibrationStep_);
          Serial.println(".");
#endif
          status_ = kCalibrationStatusInit;
        }
      } else if (scanCount_++ == 0) {
        testCalibrationStep_ = calibrationStep_;
        status_ = kCalibrationStatusFind;
      } else {
        if (abs(calibrationStep_ - testCalibrationStep_) < CALIBRATION_LOW_QUALITY_THRESHOLD) {
#ifdef CALIB_DEBUG
          Serial.print("\nVerifying ");
          Serial.print(calibrationStep_);
          Serial.print(" is close to ");
          Serial.print(testCalibrationStep_);
          Serial.println(".");
#endif
          stepper_->setStep(calibrationStep_ - PROX_FRONT_EDGE_BUFFER_STEPS);
          status_ = kCalibrationStatusInitMicroRegister;
          proxDebounce_ = 0;
        } else {
#ifdef CALIB_DEBUG
          Serial.print("\nHmm ");
          Serial.print(calibrationStep_);
          Serial.print(" is not close to ");
          Serial.print(testCalibrationStep_);
          Serial.println(".");
#endif
          status_ = kCalibrationStatusInit;
        }
      }
    }

    if (status_ == kCalibrationStatusInitMicroRegister && !stepper_->isRunning()) {
      uint8_t proxValue = digitalRead(PROX_PIN);
      if (!proxValue) {
        if (proxDebounce_++ > 2000) {
#ifdef CALIB_DEBUG
          Serial.print("Cycle is ");
          Serial.print(verifyCycle_);
          Serial.print(", Settled on position ");
          Serial.print(stepper_->stepCount());
          Serial.println(".");
#endif
          if (verifyCycle_ == 0) {
            cycleCalibrationStep_ = stepper_->stepCount();
            status_ = kCalibrationStatusAlternateCycle;
            stepper_->useRunSpeed();
            stepper_->scan(0.5);
          } else {
            if (abs(stepper_->stepCount() - stepper_->stepsPerRevolution() - cycleCalibrationStep_) > CALIBRATION_CYCLE_THRESHOLD) {
              status_ = kCalibrationStatusInit;
            } else {
              status_ = kCalibrationStatusCalibrate;
              long value = (cycleCalibrationStep_ + stepper_->stepCount() - stepper_->stepsPerRevolution()) / 2;
              stepper_->useRunSpeed();
              stepper_->setStep(value);
            }
          }
        }
      } else {
        proxDebounce_ = 0;
        stepper_->setStep(stepper_->stepCount() + 1);
      }

      
    }

    if (status_ == kCalibrationStatusCalibrate && !stepper_->isRunning()) {
      status_ = kCalibrationStatusDone;
#ifdef CALIB_DEBUG
      Serial.println("\nCalibration step 4: calibrate");
#endif
      stepper_->calibrate();
      statusIndicator_->push(kStatusTypeShortMediumBlink);

      errorLog_->clearCalibrationErrors();
      // We're done so change mode
      dispatcher_->dispatchGenericCommand(kModeCompleteCmd);
    }


    if (status_ == kCalibrationStatusAlternateCycle && !stepper_->isRunning()) {
      verifyCycle_++;
      scanCount_ = 0;
      status_ = kCalibrationStatusFind;
    }

    
    stepper_->run();
  }


  bool isComplete() {
    return status_ == kCalibrationStatusDone || calibrationFailed_;
  }

  virtual int handleCommand(Command *cmd) {
    
    return COMMAND_UNHANDLED;
  }


private:
  Stepper* stepper_;
  CommandDispatcher* dispatcher_;
  CalibrationStatus status_;
  StatusIndicator *statusIndicator_;
  ErrorLog *errorLog_;
  uint8_t attempts_;
  long calibrationStep_;
  long testCalibrationStep_;
  long cycleCalibrationStep_;
  uint8_t verifyCycle_;
  bool calibrationFailed_;
  bool proxScanStarted_;
  uint16_t proxDebounce_;
  uint8_t scanCount_;
};


#endif // Rotophone_Calibration_Mode_h

