//
//  AudioMidiSettingsManager.h
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface AudioMidiSettingsManager : NSObject

+ (AudioMidiSettingsManager *)sharedManager;

@property (readwrite) int selectedMidiPort;

@end

NS_ASSUME_NONNULL_END
