#ifndef Rotophone_Mode_h
#define Rotophone_Mode_h


#include "Serial.h"
#include "Status.h"
#include "Stepper.h"
#include "Pins.h"
#include "Interrupts.h"
#include "Settings.h"
#include "Host.h"


#ifdef TESTS
#include "Tests.h"
#endif



class ErrorLog {
public:
  ErrorLog()
  :calibrationErrorCount(0)
  {}

  void addCalibrationError() {
    calibrationErrorCount++;
  }

  void clearCalibrationErrors() {
    calibrationErrorCount = 0;
  }

  bool hasProblem() {
    return calibrationErrorCount > 3;
  }

  void clear() {
    clearCalibrationErrors();
  }
  
  uint16_t calibrationErrorCount;
};


class Resources {
public:
  virtual EventQueue* eventQueue() = 0;
  virtual Stepper* stepper() = 0;
  virtual CommandDispatcher* dispatcher() = 0;
  virtual ProximityInterrupt* proximityInterrupt() = 0;
  virtual StatusIndicator* statusIndicator() = 0;
  virtual ErrorLog* errorLog() = 0;
  virtual Settings* settings() = 0;
  virtual Host* host() = 0;
};




class Mode : public CommandHandler {
public:
  virtual void init(Resources *resources) = 0;
  virtual ModeType mode() = 0;
  virtual void begin() = 0;
  virtual void end() = 0;
  virtual void loop() = 0;

protected:
  EventQueue *eventQueue_;
};





#endif // Rotophone_Mode_h
