#ifndef Rotophone_Stepper_h
#define Rotophone_Stepper_h

#include "Pins.h"
#include "Protocol.h"

#define SERVO_SPR 1600
#define SPROCKET_GEAR_NUM 11
#define SPROCKET_GEAR_DEN 24
#define SPROCKET_SPR_DIV ((long)SERVO_SPR * SPROCKET_GEAR_DEN)
#define REVS_TO_STEPS(revs) ((long)((float)revs * SERVO_SPR * SPROCKET_GEAR_DEN) / SPROCKET_GEAR_NUM)

// Calibrate every 3 hours
#define CALIBRATION_INTERVAL ((long)3 * 60 * 60 * 1000)

#define DIV_INT(n, d) ((((n) < 0) ^ ((d) < 0)) ? (((n) - (d)/2)/(d)) : (((n) + (d)/2)/(d)))

#include "AccelStepper.h"

#include "EventQueue.h"

class Stepper {
public:
  Stepper(EventQueue *eventQueue, uint8_t interface, uint8_t pin1, uint8_t pin2)
  :eventQueue_(eventQueue),
   stepper_(interface, pin1, pin2),
   stepperOffsetInSteps_(0),
   lastDispatchedPositionTime_(0),
   lastDispatchedPosition_(0),
   lastCalibrationTime_(-1),
   scanning_(false)
   {
    stepper_.setMaxSpeed(1600);
    stepper_.setAcceleration(100);

  }

  void setupPins() {
    pinMode(SERVO_ENABLE_PIN, OUTPUT);
    pinMode(SERVO_DIRECTION_PIN, OUTPUT);
    pinMode(SERVO_CLOCK_PIN, OUTPUT);
  }

  bool needsCalibration() {
    return lastCalibrationTime_ == -1 || (millis() - lastCalibrationTime_ > CALIBRATION_INTERVAL);
  }

  
  void useScanSpeed() {
    stepper_.setMaxSpeed(200);
  }

  void useMicroSpeed() {
    stepper_.setMaxSpeed(30);
  }

  void useRunSpeed() {
    stepper_.setMaxSpeed(1600);
  }


  void scan(float revs) {
    long amt = REVS_TO_STEPS(revs);
    /*
    Serial.print("\nScanning ");
    Serial.print(amt);
    Serial.println(" steps.");*/
    stepper_.move(amt);
  }

  long stepsPerRevolution() {
    return ((long)SERVO_SPR * SPROCKET_GEAR_DEN) / SPROCKET_GEAR_NUM;
  }

  long stepCount() {
    return stepper_.currentPosition();
  }

  void setStep(long step) {
    stepper_.moveTo(step);
  }

  void calibrate() {
    lastCalibrationTime_ = millis();
    stepper_.setCurrentPosition(0);
  }

  int16_t zeroOffset() {
    return stepperOffsetInSteps_;
  }

  void setZeroOffset(int16_t offset) {
    stepperOffsetInSteps_ = offset;
  }

  void zero() {
    // Need to make sure the number fits in 16 bit
    setZeroOffset((stepper_.currentPosition() * SPROCKET_GEAR_NUM) % SPROCKET_SPR_DIV);
  }


  void runToPosition() {
    stepper_.runToPosition();
  }


  void setPosition(uint16_t pos) {
    // Position is 0-65535, which maps to a single circle
    // where 0 is some agreed upon starting position
    
    // Convert from revolutions to steps
  
    long servoStepCount = stepper_.currentPosition() - stepperOffsetInSteps_;
    long sprocketDivNum = servoStepCount * SPROCKET_GEAR_NUM * kSetPositionBound;
    long sprocketDivDen = (long)SPROCKET_GEAR_DEN * SERVO_SPR;
    long sprocketStepCount = DIV_INT(sprocketDivNum, sprocketDivDen);
    long remainder = sprocketStepCount & (kSetPositionBound - 1);
    if (remainder < 0) {
      remainder += kSetPositionBound;
    }
  
    int dif = (int)pos - remainder;
    if (dif > kSetPositionBound / 2) {
      dif -= kSetPositionBound;
    } else if (dif < -kSetPositionBound / 2) {
      dif += kSetPositionBound;
    }

    const long absoluteNum = ((sprocketStepCount + dif) * SPROCKET_GEAR_DEN * SERVO_SPR);
    const long absoluteDen = ((long)SPROCKET_GEAR_NUM * kSetPositionBound);
    const long absolute = DIV_INT(absoluteNum, absoluteDen) + stepperOffsetInSteps_;
  /*
    Serial.print("setPosition(");
    Serial.print(pos);
    Serial.print(")\n");
    Serial.print(" servoStepCount: ");
    Serial.print(servoStepCount);
    Serial.print(" remainder: ");
    Serial.print(remainder);
    Serial.print(" dif: ");
    Serial.print(dif);
    Serial.print(" absolute: ");
    Serial.print(absolute);
    Serial.print("\n");
    */
    stepper_.moveTo(absolute);
  }

  uint16_t positionParam(long steps) {
    long servoStepCount = steps - stepperOffsetInSteps_;
    // Convert currentPosition to 10 bit
    long remainder = (servoStepCount * SPROCKET_GEAR_NUM) % SPROCKET_SPR_DIV;
    if (remainder < 0) {
      remainder += SPROCKET_SPR_DIV;
    }

    long paramNum = remainder * kSetPositionBound;
    long paramDen = SPROCKET_SPR_DIV;
    return DIV_INT(paramNum, paramDen) & (kSetPositionBound - 1);
  }


  bool dispatchCurrentPosition() {
    uint16_t p = positionParam(stepper_.currentPosition());
    if (lastDispatchedPosition_ != p) {
      lastDispatchedPosition_ = p;
      eventQueue_->addEvent(kCurPosEvent, p, EVENT_QUEUE_NONBLOCK);
      return true;
    }
  
    return false;
  }

  void run() {
    unsigned long now = millis();
    
    stepper_.run();

    // Update position every 20 ms
    if (now - lastDispatchedPositionTime_ > 20) {
      if (dispatchCurrentPosition()) {
        lastDispatchedPositionTime_ = now;
      }
    }
  }

  void stop() {
    stepper_.stop();
  }

  bool isRunning() {
    return stepper_.isRunning();
  }

  AccelStepper* accelStepper() {
    return &stepper_;
  }



private:
  bool scanning_;
  AccelStepper stepper_;
  unsigned long lastCalibrationTime_;
  // The number of steps from 0 to get to a center point
// For instance, if we are at 0 point when stepper is at
// 400 steps, then stepperOffsetInSteps is 400
  int16_t stepperOffsetInSteps_;
  unsigned long lastDispatchedPositionTime_;
  uint16_t lastDispatchedPosition_;
  EventQueue *eventQueue_;
};

#endif // Rotophone_Stepper_h

