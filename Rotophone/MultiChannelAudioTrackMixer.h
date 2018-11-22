#import <AVFoundation/AVFoundation.h>

@interface MixerInput : NSObject
- (instancetype)initWithNumChannels:(unsigned int)numChannels;
- (unsigned int)numChannels;
- (void)setVolume:(float)volume forChannel:(unsigned int)channel;
- (void)copyMix:(MixerInput *)mixerInput;

@end

@interface MultiChannelAudioTrackMixer : NSObject

- (void)setPlayerItem:(AVPlayerItem *)playerItem;
- (unsigned int)getNumChannelsForPlayerItem:(AVPlayerItem *)playerItem;
- (void)setMix:(MixerInput *)mixerInput;
- (MixerInput *)mix;

@end


