//
//  MidiDeviceJuno106.h
//  Rotophone
//
//  Created by z on 12/7/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#ifndef MidiDeviceJuno106_h
#define MidiDeviceJuno106_h

#include "MidiCore.hpp"

enum Juno106ControlNum {
  kJuno106ControlLFORate = 0x00,
  kJuno106ControlLFODelayTime = 0x01,
  kJuno106ControlDCOLFO = 0x02,
  kJuno106ControlDCOPWM = 0x03,
  kJuno106ControlDCONoise = 0x04,
  kJuno106ControlVCFFreq = 0x05,
  kJuno106ControlVCFRes = 0x06,
  kJuno106ControlVCFEnv = 0x07,
  kJuno106ControlVCFLFO = 0x08,
  kJuno106ControlVCFKybd = 0x09,
  kJuno106ControlVCALevel = 0x0A,
  kJuno106ControlEnvAttack = 0x0B,
  kJuno106ControlEnvDecay = 0x0C,
  kJuno106ControlEnvSustain = 0x0D,
  kJuno106ControlEnvRelease = 0x0E,
  kJuno106ControlDCOSub = 0x0F,
  kJuno106ControlSwitch1 = 0x10,
  kJuno106ControlSwitch2 = 0x11,
};


static const unsigned char kJuno106Switch1Octave16 = 1 << 0;
static const unsigned char kJuno106Switch1Octave8 = 1 << 1;
static const unsigned char kJuno106Switch1Octave4 = 1 << 2;
static const unsigned char kJuno106Switch1Pulse = 1 << 3;
static const unsigned char kJuno106Switch1Tri = 1 << 4;
static const unsigned char kJuno106Switch1ChorusOff = 1 << 5;
static const unsigned char kJuno106Switch1Chorus2Off = 1 << 6;

static const unsigned char kJuno106Switch2LFO = 0;
static const unsigned char kJuno106Switch2Manual = 1 << 0;
static const unsigned char kJuno106Switch2Env = 0;
static const unsigned char kJuno106Switch2Gate = 1 << 1;
static const unsigned char kJuno106Switch2PolPos = 0;
static const unsigned char kJuno106Switch2PolNeg = 1 << 2;
static const unsigned char kJuno106Switch2HPF3 = 0;
static const unsigned char kJuno106Switch2HPF2 = 0x01 << 3;
static const unsigned char kJuno106Switch2HPF1 = 0x02 << 3;
static const unsigned char kJuno106Switch2HPF0 = 0x03 << 3;

class Juno106Patch {
public:
  Juno106Patch(int patch)
  :patch(patch) {
    values[kJuno106ControlLFORate] = 0;
    values[kJuno106ControlLFODelayTime] = 0;
    values[kJuno106ControlDCOLFO] = 0;
    values[kJuno106ControlDCOPWM] = 0;
    values[kJuno106ControlDCONoise] = 0;
    values[kJuno106ControlVCFFreq] = 0x40;
    values[kJuno106ControlVCFRes] = 0;
    values[kJuno106ControlVCFEnv] = 0;
    values[kJuno106ControlVCFLFO] = 0;
    values[kJuno106ControlVCFKybd] = 0x7F;
    values[kJuno106ControlVCALevel] = 0x7F;
    values[kJuno106ControlEnvAttack] = 0;
    values[kJuno106ControlEnvDecay] = 0x40;
    values[kJuno106ControlEnvSustain] = 0x40;
    values[kJuno106ControlEnvRelease] = 0x40;
    values[kJuno106ControlDCOSub] = 0x7F;
    values[kJuno106ControlSwitch1] = kJuno106Switch1Octave8 | kJuno106Switch1Pulse | kJuno106Switch1Tri;
    values[kJuno106ControlSwitch2] = kJuno106Switch2Manual | kJuno106Switch2Env | kJuno106Switch2PolPos | kJuno106Switch2HPF0;
  }

  unsigned char patch;
  unsigned char values[18];
};

class Juno106SysExBuilder : public MidiMessageBuilder {
public:
  Juno106SysExBuilder()
  :MidiMessageBuilder() {}
  
  void ControlChange(int channel, Juno106ControlNum control_num, int control_value)
  {
    SetSysEx(0x41);
    Push(0x32); // Control change
    Push(channel & 0xF); // Channel
    Push(control_num);
    Push(control_value);
    EndSysEx();
  }
  
  void PatchChange(int channel, int patch) noexcept(false)
  {
    SetSysEx(0x41);
    Push(0x30);
    Push(channel & 0xF);
    Push(patch & 0xF);
    EndSysEx();
  }
  
  void ManualPatchChange(int channel, const Juno106Patch& patch) noexcept(false)
  {
    SetSysEx(0x41);
    Push(0x31);
    Push(channel & 0xF);
    Push(patch.patch);
    Push(&patch.values[0], sizeof(patch.values));
    EndSysEx();
  }
};


#endif /* MidiDeviceJuno106_h */
