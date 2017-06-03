#include "AccelStepper.h"

#define CPU_HZ 16000000L
#define TIMER_PRESCALER_DIV 8



// Timer/Counter 1 running on 16mhz / 8
#define T1_FREQ (16000000 / 8)
// Number of full steps per revolution for motor
#define FSPR 400
// This is different if using half steps I guess
#define SPR FSPR

// Constants to simplify speed_cntr_Move
// 1 rad/sec = 9.55 rpm
#define ALPHA (2*3.14159/SPR)                     // Motor step angle 2 * pi / spr
#define A_T_x100 ((long)(ALPHA * T1_FREQ * 100))  // (ALPHA / T1_FREQ) * 100
#define T1_FREQ_148 ((int)((T1_FREQ*0.676)/100))  // divided by 100 and scaled by .676 (error)
#define A_SQ (long)(ALPHA*2*10000000000)          // ALPHA * 2 * 10000000000
#define A_x20000 (int)(ALPHA*20000)               // ALPHA * 20000

#define DIRINC(INC)  ((INC) == CCW ? LOW : HIGH)

#define DEBUG_PARAMS

// State machine for motor
#define STOP  0
#define ACCEL 1
#define DECEL 2
#define RUN   3

#define CW  0
#define CCW 1

bool running = false;

/*! \brief Holding data used by timer interrupt for speed ramp calculation.
 *
 *  Contains data used by timer interrupt to calculate speed profile.
 *  Data is written to it by move(), when stepper motor is moving (timer
 *  interrupt running) data is read/updated when calculating a new step_delay
 */
typedef struct {
  //! What part of the speed ramp we are in.
  uint8_t run_state : 3;
  //! Direction stepper motor should move.
  uint8_t dir : 1;
  //! Peroid of next timer delay. At start this value set the accelration rate.
  uint16_t step_delay;
  //! What step_pos to start decelaration
  uint16_t decel_start;
  //! Sets deceleration rate.
  int16_t decel_val;
  //! Minimum time delay (max speed)
  int16_t min_delay;
  //! Counter used when accelerateing/decelerateing to calculate step_delay.
  int16_t accel_count;
} SpeedRampData;
  
byte proxPin = 2;
byte tiltPin = 3;
byte servoEnablePin = 5;
byte servoDirectionPin = 6;
byte servoClockPin = 7;
byte lowPowerModePin = 8;

byte statusPin = 13;

int servoPulsesPerRev = 400;

long interruptCount = 0;
volatile int servoPulseCounter = 0;
volatile uint8_t servoPulseDir = CCW;

SpeedRampData srd;

enum StatusPatternType {kStatusTypeStartup, kStatusTypeStage1, kStatusTypeIdle, kStatusTypeError};

struct StatusPattern {
  byte patternSize;
  int pattern[16]; 
};

struct StatusCursor {
  int duration;
  int position;
  long startTime;
  unsigned long nextUpdate;
};

StatusCursor statusCursor;
StatusPattern statusPattern;

AccelStepper stepper(AccelStepper::DRIVER, servoClockPin, servoDirectionPin);

byte stagingLevel = 0;
bool toggle = false;

int frequency = 1;

void setup() {
  pinMode(proxPin, INPUT_PULLUP);
  pinMode(tiltPin, INPUT_PULLUP);

  pinMode(servoEnablePin, OUTPUT);
  pinMode(servoDirectionPin, OUTPUT);
  pinMode(servoClockPin, OUTPUT);

  pinMode(statusPin, OUTPUT);
  pinMode(lowPowerModePin, OUTPUT);

  // Start in Low Power Mode, disabing 24V
  digitalWrite(lowPowerModePin, HIGH);

  // Disable motor
  digitalWrite(servoEnablePin, HIGH);
  digitalWrite(servoDirectionPin, DIRINC(servoPulseDir));

  // Setup complete
  initStatusPattern(statusPattern, kStatusTypeStartup);
  initStatusCursor(statusCursor, statusPattern);
  startStatusCursor(statusCursor, millis());

  Serial.begin(9600);
  Serial.println("Started...\n");
  Serial.print("ALPHA: ");
  Serial.print((float)ALPHA, 4);
  Serial.print("\n");
  Serial.print("A_T_x100: ");
  Serial.print(A_T_x100);
  Serial.print("\n");
  Serial.print("T1_FREQ_148: ");
  Serial.print(T1_FREQ_148);
  Serial.print("\n");
  unsigned long sqcheck = fstsqrt(123456789);
  Serial.print("SQRT Check should be 11111: ");
  Serial.print(sqcheck);
  Serial.print("\n");

  stepper.setMaxSpeed(1600);
        stepper.setAcceleration(100);
}

void loop() {
  unsigned long now = millis();

  if (stagingLevel == 0 && now > 5000) {
    stagingLevel = 1;
    initStatusPattern(statusPattern, kStatusTypeStage1);
    initStatusCursor(statusCursor, statusPattern);

    // Enable 24V
    digitalWrite(lowPowerModePin, LOW);
  }

  if (stagingLevel == 1 && now > 7000) {
    stagingLevel = 2;
    initStatusPattern(statusPattern, kStatusTypeIdle);
    initStatusCursor(statusCursor, statusPattern);

    // Enable motor
    digitalWrite(servoEnablePin, LOW);

    //Serial.println("Init timer.");
    //initTimer();
  }

  if (stagingLevel == 2 && now > 9000) {
    stagingLevel = 3;

    stepper.moveTo(400);
  } 

   if (stagingLevel == 3 && now > 10000) {
    stagingLevel = 4;

    stepper.moveTo(200);
  }  

  if (stagingLevel == 4) {
    if (stepper.distanceToGo() == 0) {
      delay(5000);
      stepper.moveTo(rand() % 6400);
    }
  }

    // Max speed is 1 full rotation per second
    //move(400, 25, 25, 628);
    //delay(200);
    //move(400, 25, 25, 628);
/*

    delay(5000);

    move(400, 1, 1, 628);


    delay(5000);

    move(800, 250, 250, 9688);

    delay(5000);

    move(-1600, 250, 250, 9688);
    */
    
 // }
  stepper.run();
 

  // Update the status LED
  updateStatusCursor(statusCursor, statusPattern, now);
 
}

void initTimer() {
  cli();
  srd.run_state = STOP;
  // Clear
  TCCR1A = 0;
  TCCR1B = 0;
  TCNT1 = 0;
  // turn on CTC mode
  TCCR1B |= (1 << WGM12);
  // enable timer compare interrupt
  TIMSK1 |= (1 << OCIE1A);
  sei();
}

void moveToTarget(int16_t step) {
  // Check if we are starting from zero
  // Check if we are changing directions
  
}


/*! \brief Move the stepper motor a given number of steps.
 *
 *  Makes the stepper motor move the given number of steps.
 *  It accelrate with given accelration up to maximum speed and decelerate
 *  with given deceleration so it stops at the given step.
 *  If accel/decel is to small and steps to move is to few, speed might not
 *  reach the max speed limit before deceleration starts.
 *
 *  \param step  Number of steps to move (pos - CW, neg - CCW).
 *  \param accel  Accelration to use, in 0.01*rad/sec^2.
 *  \param decel  Decelration to use, in 0.01*rad/sec^2.
 *  \param speed  Max speed, in 0.01*rad/sec.
 */
void move(int16_t step, uint16_t accel, uint16_t decel, uint16_t speed)
{
  //! Number of steps before we hit max speed.
  uint16_t max_s_lim;
  //! Number of steps before we must start deceleration (if accel does not hit max speed).
  uint16_t accel_lim;

  // Set direction from sign on step value.
  if (step < 0){
    srd.dir = CCW;
    step = -step;
  } else {
    srd.dir = CW;
  }

  // If moving only 1 step.
  if (step == 1) {
    // Move one step...
    srd.accel_count = -1;
    // ...in DECEL state.
    srd.run_state = DECEL;
    // Just a short delay so main() can act on 'running'.
    srd.step_delay = 1000;
    running = true;
    OCR1A = 10;
    // Run Timer/Counter 1 with prescaler = 8.
    TCCR1B |= ((0<<CS12)|(1<<CS11)|(0<<CS10));
  }
  // Only move if number of steps to move is not zero.
  else if (step != 0){
    // Refer to documentation for detailed information about these calculations.

    // Set max speed limit, by calc min_delay to use in timer.
    // min_delay = (alpha / tt)/ w
    // min_delay is the delay at the target speed.
    // when the delay reaches this, it enters run mode
    srd.min_delay = A_T_x100 / speed;

    // Set accelration by calc the first (c0) step delay .
    // step_delay = 1/tt * sqrt(2*alpha/accel)
    // step_delay = ( tfreq*0.676/100 )*100 * sqrt( (2*alpha*10000000000) / (accel*100) )/10000
    srd.step_delay = (T1_FREQ_148 * fstsqrt(A_SQ / accel)) / 100;

#ifdef DEBUG_PARAMS
    Serial.print("Min delay:");
    Serial.print(srd.min_delay);
    Serial.print("\n");
    Serial.print("First step delay:");
    Serial.print(srd.step_delay);
    Serial.print("\n");
#endif

    // Find out after how many steps does the speed hit the max speed limit.
    // max_s_lim = speed^2 / (2*alpha*accel)
    // This is steps to stop
    max_s_lim = (long)speed*speed/(long)(((long)A_x20000*accel)/100);
    max_s_lim = (long)speed*speed/(long)(((long)A_x20000*accel)/1000);
    //float test = (speed * 100 * speed * 100) / (2 * ALPHA * accel * 100);
    //max_s_lim = test;
    //Serial.print("test:");
    //Serial.print(test);
    //Serial.print("\n");
    //max_s_lim = (long)speed*speed/(long)(((long)A_x20000*accel));

    //max_s_lim = (long)speed*speed/(long)((ALPHA * 2 * accel * 100));
    //max_s_lim = 11;;
#ifdef DEBUG_PARAMS
    Serial.print("Max s limit:");
    Serial.print(max_s_lim);
    Serial.print("\n");
#endif

    // If we hit max speed limit before 0,5 step it will round to 0.
    // But in practice we need to move atleast 1 step to get any speed at all.
    if(max_s_lim == 0){
      max_s_lim = 1;
    }

    // Find out after how many steps we must start deceleration.
    // n1 = (n1+n2)decel / (accel + decel)
    accel_lim = ((long)step*decel) / (accel+decel);
    // We must accelrate at least 1 step before we can start deceleration.
    if(accel_lim == 0){
      accel_lim = 1;
    }

#ifdef DEBUG_PARAMS
    Serial.print("accel limit:");
    Serial.print(accel_lim);
    Serial.print("\n");
#endif

    // Use the limit we hit first to calc decel.
    if (accel_lim <= max_s_lim) {
      srd.decel_val = accel_lim - step;
    } else {
      srd.decel_val = -((long)max_s_lim*accel)/decel;
    }
    // We must decelrate at least 1 step to stop.
    if(srd.decel_val == 0){
      srd.decel_val = -1;
    }

#ifdef DEBUG_PARAMS
    Serial.print("decel val:");
    Serial.print(srd.decel_val);
    Serial.print("\n");
#endif

    // Find step to start decleration.
    srd.decel_start = step + srd.decel_val;

#ifdef DEBUG_PARAMS
    Serial.print("decel start:");
    Serial.print(srd.decel_start);
    Serial.print("\n");
#endif

    // If the maximum speed is so low that we dont need to go via accelration state.
    if (srd.step_delay <= srd.min_delay) {
      srd.step_delay = srd.min_delay;
      srd.run_state = RUN;
    } else{
      srd.run_state = ACCEL;
    }

    // Reset counter.
    srd.accel_count = 0;
    running = true;

    // A small delay before move (can this be removed?)
    OCR1A = 10;
    TCNT1 = 0;
    // Set Timer/Counter to divide clock by 8
    TCCR1B |= ((0<<CS12)|(1<<CS11)|(0<<CS10));
  }
}

/*

void updateFreq(unsigned int frequencyHz) {
  int compareValue = (CPU_HZ / (TIMER_PRESCALER_DIV * frequencyHz)) - 1;
  TCNT1 = map(TCNT1, 0, OCR1A, 0, compareValue);
  OCR1A = compareValue;
}*/

ISR(TIMER1_COMPA_vect) {
  // Holds next delay period.
  uint16_t new_step_delay;
  // Remember the last step delay used when accelerating.
  static int16_t last_accel_delay;
  // Counting steps when moving.
  static uint16_t step_count = 0;
  // Keep track of remainder from new_step-delay calculation to incrase accurancy
  static uint16_t rest = 0;

  OCR1A = srd.step_delay;

  //Serial.print("stp:");
  //Serial.print(srd.step_delay);
  //Serial.print("\n");

  switch (srd.run_state) {
    case STOP:
      step_count = 0;
      rest = 0;
      // Stop Timer/Counter 1.
      TCCR1B &= ~((1<<CS12)|(1<<CS11)|(1<<CS10));
      running = false;
      break;

    case ACCEL:
      stepCounter(srd.dir);
      step_count++;
      srd.accel_count++;
      new_step_delay = srd.step_delay - (((2 * (long)srd.step_delay) + rest)/(4 * srd.accel_count + 1));

#ifdef DEBUG_PARAMS
      Serial.print("acceld:");
      Serial.print(new_step_delay);
      Serial.print("\n");
#endif

      rest = ((2 * (long)srd.step_delay)+rest)%(4 * srd.accel_count + 1);
      // Chech if we should start decelration.
      if(step_count >= srd.decel_start) {
        srd.accel_count = srd.decel_val;

#ifdef DEBUG_PARAMS
      Serial.print("start decel from accel:");
      Serial.print(srd.accel_count);
      Serial.print("\n");
#endif
        srd.run_state = DECEL;
      }
      // Chech if we hitted max speed.
      else if(new_step_delay <= srd.min_delay) {
        last_accel_delay = new_step_delay;
        new_step_delay = srd.min_delay;
        rest = 0;
        srd.run_state = RUN;
      }
      break;

    case RUN:
      stepCounter(srd.dir);
      step_count++;
      new_step_delay = srd.min_delay;
      // Chech if we should start decelration.
      if(step_count >= srd.decel_start) {
        srd.accel_count = srd.decel_val;
        
#ifdef DEBUG_PARAMS
        Serial.print("start decel from run:");
        Serial.print(srd.accel_count);
        Serial.print("\n");
#endif
        // Start decelration with same delay as accel ended with.
        new_step_delay = last_accel_delay;
        srd.run_state = DECEL;
      }
      break;

    case DECEL:
      stepCounter(srd.dir);
      step_count++;
      srd.accel_count++;
      new_step_delay = srd.step_delay - (((2 * (long)srd.step_delay) + rest)/(4 * srd.accel_count + 1));

#ifdef DEBUG_PARAMS
      Serial.print("deceld:");
      Serial.print(new_step_delay);
      Serial.print("\n");
#endif

      rest = ((2 * (long)srd.step_delay)+rest)%(4 * srd.accel_count + 1);
      // Check if we at last step
      if (srd.accel_count >= 0) {
        srd.run_state = STOP;
      }
      break;
  }
  srd.step_delay = new_step_delay;
}

void stepCounter(uint8_t inc) {
  if (inc == CCW) {
    servoPulseCounter--;
  } else {
    servoPulseCounter++;
  }

  if (inc != servoPulseDir) {
    servoPulseDir = inc;
    digitalWrite(servoDirectionPin, DIRINC(inc));
  }

  digitalWrite(servoClockPin, HIGH);
  digitalWrite(servoClockPin, LOW);
}

void initStatusPattern(StatusPattern &pattern, enum StatusPatternType type) {
  switch (type) {
    case kStatusTypeStartup:
      pattern.patternSize = 2;
      pattern.pattern[0] = 100;
      pattern.pattern[1] = 100;
      break;
    case kStatusTypeStage1:
      pattern.patternSize = 2;
      pattern.pattern[0] = 100;
      pattern.pattern[1] = 500;
      break;
    case kStatusTypeIdle:
      pattern.patternSize = 2;
      pattern.pattern[0] = 500;
      pattern.pattern[1] = 500;
    break;
    case kStatusTypeError:
      pattern.patternSize = 6;
      pattern.pattern[0] = 150;
      pattern.pattern[1] = 750;
      pattern.pattern[2] = 750;
      pattern.pattern[3] = 500;
      pattern.pattern[4] = 750;
      pattern.pattern[5] = 500;
      break;
    default:
      pattern.patternSize = 2;
      pattern.pattern[0] = 100;
      pattern.pattern[1] = 100;
  }
}

void initStatusCursor(StatusCursor &cursor, StatusPattern &pattern) {
  // Calculate the duration
  cursor.duration = 0;
  for (int i = 0; i < pattern.patternSize; i++) {
    cursor.duration += pattern.pattern[i];
  }

  cursor.position = -1;
  cursor.startTime = 0;
}

void startStatusCursor(StatusCursor &cursor, unsigned long now) {
  cursor.startTime = now;
  cursor.nextUpdate = now;
}

void updateStatusCursor(StatusCursor &cursor, StatusPattern &pattern, unsigned long now) {
  if (now < cursor.nextUpdate) {
    return;
  }
  
  int elapsed = (now - cursor.startTime) % cursor.duration;
  int timeCounter = 0;
  int nextPosition = 0;
  for (int i = 0; i < pattern.patternSize; i++) {
    timeCounter += pattern.pattern[i];
    if (timeCounter >= elapsed) {
      nextPosition = i;
      break;
    }
  }

  cursor.nextUpdate = now + (timeCounter - elapsed);
  
  if (nextPosition != cursor.position) {
    if (nextPosition & 1) {
      digitalWrite(statusPin, LOW);
    } else {
      digitalWrite(statusPin, HIGH);
    }

    cursor.position = nextPosition;
  }

  
}


static unsigned long fstsqrt(unsigned long x)
{
  register unsigned long xr;  // result register
  register unsigned long q2;  // scan-bit register
  register unsigned char f;   // flag (one bit)

  xr = 0;                     // clear result
  q2 = 0x40000000L;           // higest possible result bit
  do
  {
    if((xr + q2) <= x)
    {
      x -= xr + q2;
      f = 1;                  // set flag
    }
    else{
      f = 0;                  // clear flag
    }
    xr >>= 1;
    if(f){
      xr += q2;               // test flag
    }
  } while(q2 >>= 2);          // shift twice
  if(xr < x){
    return xr +1;             // add for rounding
  }
  else{
    return xr;
  }
}


