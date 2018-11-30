//
//  AudioMidiSettingsManager.m
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "AudioMidiSettingsManager.h"
#import "RtMidi.h"

static AudioMidiSettingsManager *sharedInstance = nil;

@interface AudioMidiSettingsManager()
{
  std::unique_ptr<RtMidiOut> _midiOut;
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

- (void)sendMidiData:(const unsigned char *)data ofSize:(size_t)dataSize
{
  if (_selectedMidiPort > -1) {
    _midiOut->sendMessage(data, dataSize);
  }
}


@end
