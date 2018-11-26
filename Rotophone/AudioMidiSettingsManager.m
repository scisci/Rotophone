//
//  AudioMidiSettingsManager.m
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "AudioMidiSettingsManager.h"

static AudioMidiSettingsManager *sharedInstance = nil;

@implementation AudioMidiSettingsManager

- (instancetype)init
{
  if (self == sharedInstance) return sharedInstance; // Already initialized
  
  self = [super init];
  if (self != nil)
  {
    // TODO: init
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

@end
