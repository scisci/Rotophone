//
//  VideoViewController.m
//  VideoMixerTest
//
//  Created by z on 11/12/18.
//  Copyright © 2018 scisci. All rights reserved.
//

#import "VideoViewController.h"
#import "MultiChannelAudioTrackMixer.h"
#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>


@interface VideoView() {
}

@property (unsafe_unretained) AVPlayerLayer *playerLayer;

@end

@implementation VideoView

-(CALayer*)makeBackingLayer
{
  CALayer *theLayer = [[CALayer alloc]init];
  theLayer.layoutManager = [[CAConstraintLayoutManager alloc] init];
  return theLayer;
}


@end

@interface VideoViewController () {
  AVQueuePlayer *_player;
  AVPlayerLooper *_looper;
  AVPlayerItem *_playerItem;
  MultiChannelAudioTrackMixer *_mixer;
  URLResource *_playerUrlResource;
  id<NSObject> _loopObserver;
}

@end

@implementation VideoViewController

- (void)viewDidLoad {
  [super viewDidLoad];

  _player = [[AVQueuePlayer alloc] initWithItems:@[]];

  _mixer = [[MultiChannelAudioTrackMixer alloc] init];

  AVPlayerView *customView = (AVPlayerView *)self.view;
  customView.player = _player;
  customView.controlsStyle = AVPlayerViewControlsStyleNone;

  _loopObserver = [NSNotificationCenter.defaultCenter addObserverForName:AVPlayerItemDidPlayToEndTimeNotification
              object:nil
              queue:nil
              usingBlock:^(NSNotification *note) {
                  [self queuePlayerItem];
              }];
}

- (void)dealloc
{
  [NSNotificationCenter.defaultCenter removeObserver:_loopObserver];
}

- (void)queuePlayerItem
{
  if (_playerUrlResource == nil) {
    return;
  }
  
  _playerItem = [AVPlayerItem playerItemWithURL:_playerUrlResource.url];
  [_mixer setPlayerItem:_playerItem];
  [_player insertItem:_playerItem afterItem:nil];
}

- (MultiChannelAudioTrackMixer *)mixer
{
  return _mixer;
}

- (MixerInput *)mix
{
  return [_mixer mix];
}

- (void)setMix:(MixerInput *)mix
{
  [_mixer setMix:mix];
}

- (MixerInput *)openVideo:(URLResource *)urlResource
{
  _playerUrlResource = urlResource;
  
  [_player removeAllItems];
  [self queuePlayerItem];

  [_player play];
  
  return [_mixer mix];
}
/*
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary<NSKeyValueChangeKey, id> *)change
                       context:(void *)context
{
  if (_playerItem != nil) {
    AVPlayerItemStatus status = _playerItem.status;
    if (status == AVPlayerItemStatusReadyToPlay) {
     // [_player play];
    }
    
    if (status == AVPlayerItemStatusFailed) {
      NSLog(@"Load failed %@", _playerItem.error);
    }
    NSLog(@"Status is now %d", status);
  }
}
*/

@end
