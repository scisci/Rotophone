//
//  AudioMidiSettingsManager.m
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "AudioMidiSettingsManager.h"
#import "RtMidi.h"
#import <CoreAudio/CoreAudio.h>
#import <AudioToolbox/AudioToolbox.h>

static AudioMidiSettingsManager *sharedInstance = nil;

OSStatus GetDefaultInputDeviceSampleRate(Float64 *outSampleRate) {
    OSStatus error;
    AudioDeviceID deviceID = 0;
    AudioObjectPropertyAddress propertyAddress;
    UInt32 propertySize;

    //
    propertyAddress.mSelector = kAudioHardwarePropertyDefaultSystemOutputDevice;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = 0;
    propertySize = sizeof(AudioDeviceID);

    //
    error = AudioObjectGetPropertyData( kAudioObjectSystemObject,
                                                 &propertyAddress,
                                                 0,
                                                 nullptr,
                                                 &propertySize,
                                                 &deviceID);
    if( error) return error;

    //
    propertyAddress.mSelector = kAudioDevicePropertyNominalSampleRate;
    propertyAddress.mScope = kAudioObjectPropertyScopeGlobal;
    propertyAddress.mElement = 0;

    propertySize = sizeof(Float64);
    //gets property( nominal sample rate)
    error = AudioObjectGetPropertyData(deviceID,
                                                &propertyAddress,
                                                0,
                                                nullptr,
                                                &propertySize,
                                                outSampleRate);
    return error;
}

@interface AudioMidiSettingsManager()
{
  std::unique_ptr<RtMidiOut> _midiOut;
  Float64 _sampleRate;
}

@end

@implementation AudioMidiSettingsManager

@synthesize selectedMidiPort = _selectedMidiPort;

- (instancetype)init
{
  if (self == sharedInstance) return sharedInstance; // Already initialized
  
  self = [super init];
  if (self != nil)
  {
    _midiOut.reset(new RtMidiOut());
    _selectedMidiPort = -1;
    
    GetDefaultInputDeviceSampleRate(&_sampleRate);
  }
  return self;
}

+ (AudioMidiSettingsManager *)sharedManager;
{
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    if (sharedInstance == nil) {
      sharedInstance = [(AudioMidiSettingsManager *)[super allocWithZone:NULL] init];
    }
  });
  
  return sharedInstance;
}

- (void)dealloc {
  self.selectedMidiPort = -1;
}

- (NSArray *)listMidiPorts
{
  int numPorts = _midiOut->getPortCount();
  NSMutableArray *ports = [[NSMutableArray alloc] init];
  for (unsigned int i = 0; i < numPorts; i++ ) {
    [ports addObject:[NSString stringWithUTF8String:_midiOut->getPortName(i).c_str()]];
  }
  return ports;
}

- (void)setSelectedMidiPort:(int)selectedMidiPort
{
  if (selectedMidiPort != _selectedMidiPort) {
    if (_selectedMidiPort > -1) {
      _midiOut->closePort();
    }
    
    _selectedMidiPort = selectedMidiPort;
    
    if (_selectedMidiPort > -1) {
      _midiOut->openPort(_selectedMidiPort);
    }
  }
}

- (int)selectedMidiPort
{
  return _selectedMidiPort;
}

- (Float64)sampleRate
{
  return _sampleRate;
}

- (void)sendMidiData:(const unsigned char *)data ofSize:(size_t)dataSize
{
  if (_selectedMidiPort > -1) {
    _midiOut->sendMessage(data, dataSize);
  }
}


@end
