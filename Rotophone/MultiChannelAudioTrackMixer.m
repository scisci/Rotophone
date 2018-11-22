
#import "MultiChannelAudioTrackMixer.h"

#import <AVFoundation/AVFoundation.h>
#import <AVKit/AVKit.h>
#import "MultiChannelAudioTrackMixer.h"
#import <Accelerate/Accelerate.h>
#import <pthread.h>

static const unsigned int kMaxChannels = 16;
static const unsigned int kRampSize = 256;

struct MixerStorage {
  float volumes[kMaxChannels];
  float prev_volumes[kMaxChannels];
  float ramp[kRampSize];
  pthread_mutex_t mutex;
};


void init(MTAudioProcessingTapRef tap, void *clientInfo, void **tapStorageOut) {
  NSLog(@"Initialising the Audio Tap Processor");
  *tapStorageOut = clientInfo;
}

void finalize(MTAudioProcessingTapRef tap) {
  NSLog(@"Finalizing the Audio Tap Processor");
}

void prepare(MTAudioProcessingTapRef tap, CMItemCount maxFrames, const AudioStreamBasicDescription *processingFormat) {
  NSLog(@"Preparing the Audio Tap Processor");
}

void unprepare(MTAudioProcessingTapRef tap) {
  NSLog(@"Unpreparing the Audio Tap Processor");
}

void process(MTAudioProcessingTapRef tap, CMItemCount numberFrames,
         MTAudioProcessingTapFlags flags, AudioBufferList *bufferListInOut,
         CMItemCount *numberFramesOut, MTAudioProcessingTapFlags *flagsOut) {
  OSStatus err = MTAudioProcessingTapGetSourceAudio(tap, numberFrames, bufferListInOut, flagsOut, NULL, numberFramesOut);
  if (err){
    NSLog(@"Error from GetSourceAudio: %d", (int)err);
    return;
  }

  struct MixerStorage *mixer_data = (struct MixerStorage *) MTAudioProcessingTapGetStorage(tap);
  
  int num_channels = bufferListInOut->mNumberBuffers;
  if (num_channels > kMaxChannels) {
    num_channels = kMaxChannels;
  }
  
  // Copy in volumes
  float volumes[kMaxChannels];
  pthread_mutex_lock(&mixer_data->mutex);
  memcpy(&volumes[0], &mixer_data->volumes[0], num_channels * sizeof(float));
  pthread_mutex_unlock(&mixer_data->mutex);
  
  // Scale each channel, if the volume changed then ramp the volume by kRampSize, otherwise
  // just multiply by the volume
  for (int i = 0; i < num_channels; i++) {
    const unsigned int buffer_size = bufferListInOut->mBuffers[i].mDataByteSize / sizeof(float);
    
    if (volumes[i] != mixer_data->prev_volumes[i]) {
      const unsigned int ramp_size = buffer_size < kRampSize ? buffer_size : kRampSize;
      // We need a ramp
      float inc = (volumes[i] - mixer_data->prev_volumes[i]) / ramp_size;
      vDSP_vramp(&mixer_data->prev_volumes[i], &inc, &mixer_data->ramp[0], 1, ramp_size);
      mixer_data->prev_volumes[i] = volumes[i];
      
      const unsigned int ramp_byte_offset = ramp_size * sizeof(float);

      vDSP_vmul(bufferListInOut->mBuffers[i].mData, 1, &mixer_data->ramp[0], 1, bufferListInOut->mBuffers[i].mData, 1, ramp_size);
      vDSP_vsmul(bufferListInOut->mBuffers[i].mData + ramp_byte_offset, 1, &mixer_data->prev_volumes[i], bufferListInOut->mBuffers[i].mData + ramp_byte_offset, 1, buffer_size - ramp_size);
    } else {
      vDSP_vsmul(bufferListInOut->mBuffers[i].mData, 1, &mixer_data->prev_volumes[i], bufferListInOut->mBuffers[i].mData, 1, buffer_size);
    }
  }
  
  // Add each track together into buf 1
  for (int i = 1; i < num_channels; i++) {
    vDSP_vadd(bufferListInOut->mBuffers[0].mData, 1, bufferListInOut->mBuffers[i].mData, 1, bufferListInOut->mBuffers[0].mData, 1, bufferListInOut->mBuffers[i].mDataByteSize / sizeof(float));
  }
  
  // Copy 1 to 2
  memcpy(bufferListInOut->mBuffers[1].mData, bufferListInOut->mBuffers[0].mData, bufferListInOut->mBuffers[1].mDataByteSize);
  
  // Clear channel 2 and 3
  for (int i = 2; i < num_channels; i++) {
    vDSP_vclr(bufferListInOut->mBuffers[i].mData, 1, bufferListInOut->mBuffers[i].mDataByteSize / sizeof(float));
  }

}


@interface MixerInput() {
  unsigned int _numChannels;
  float _volumes[kMaxChannels];
}

@end

@implementation MixerInput

- (instancetype)initWithNumChannels:(unsigned int)numChannels
{
  if (self = [super init]) {
    _numChannels = numChannels > kMaxChannels ? kMaxChannels : numChannels;
    for (int i = 0; i < _numChannels; i++) {
      _volumes[i] = 0.0;
    }
  }
  
  return self;
}

- (unsigned int)numChannels
{
  return _numChannels;
}

- (void)setVolume:(float)volume forChannel:(unsigned int)channel
{
  if (channel >= _numChannels) {
    return;
  }
  
  _volumes[channel] = volume;
}

- (void)copyVolumes:(float *)dst forNumChannels:(unsigned int)numChannels
{
  unsigned int size = numChannels > kMaxChannels ? kMaxChannels : numChannels;
  memcpy(dst, &_volumes[0], size * sizeof(float));
}

- (void)copyMix:(MixerInput *)mixerInput
{
  _numChannels = mixerInput->_numChannels;
  memcpy(_volumes, mixerInput->_volumes, kMaxChannels * sizeof(float));
}


@end

@interface MultiChannelAudioTrackMixer () {
  AVPlayerItem *_playerItem;
  unsigned int _numChannels;
  struct MixerStorage _mixerStorage;
}

@end

@implementation MultiChannelAudioTrackMixer

- (instancetype)init
{
  if (self = [super init]) {
    _playerItem = nil;
    _numChannels = 0;

    memset(&_mixerStorage.volumes[0], 0, kMaxChannels * sizeof(float));
    memset(&_mixerStorage.prev_volumes[0], 0, kMaxChannels * sizeof(float));
    pthread_mutex_init(&_mixerStorage.mutex, NULL);
  }
  
  return self;
}

- (void)dealloc
{
  [self setPlayerItem:nil];
  pthread_mutex_destroy(&_mixerStorage.mutex);
}

- (AVAssetTrack *)getAudioTrack:(AVPlayerItem *)playerItem
{
  AVAsset *asset = _playerItem.asset;
  AVAssetTrack *audioTrack = nil;
  for (AVAssetTrack *assetTrack in asset.tracks) {
    if ([assetTrack.mediaType isEqualToString:AVMediaTypeAudio]) {
      audioTrack = assetTrack;
    }
  }
  
  return audioTrack;
}

- (unsigned int)getNumChannels:(AVAssetTrack *)track
{
  unsigned int numChannels = 0;
  NSArray* formatDesc = track.formatDescriptions;
  for (unsigned int i = 0; i < [formatDesc count]; ++i) {
    CMAudioFormatDescriptionRef item = (__bridge CMAudioFormatDescriptionRef)[formatDesc objectAtIndex:i];
    const AudioStreamBasicDescription* desc = CMAudioFormatDescriptionGetStreamBasicDescription (item);
    if(desc && desc->mChannelsPerFrame > numChannels) {
      numChannels = desc->mChannelsPerFrame;
    }
  }
  
  return numChannels;
}

- (unsigned int)getNumChannelsForPlayerItem:(AVPlayerItem *)playerItem
{
  AVAssetTrack *audioTrack = [self getAudioTrack:_playerItem];
  if (audioTrack == nil) {
    return 0;
  }
  
  return [self getNumChannels:audioTrack];
}


- (void)setPlayerItem:(AVPlayerItem *)playerItem
{
  if (_playerItem != nil) {
    _playerItem.audioMix = nil;
  }
  
  // Clear volumes to 0, make sure to lock mutex in case audio is still processing
  /*
  pthread_mutex_lock(&_mixerStorage.mutex);
  _numChannels = 0;
  memset(&_mixerStorage.volumes[0], 0, kMaxChannels * sizeof(float));
  memset(&_mixerStorage.prev_volumes[0], 0, kMaxChannels * sizeof(float));
  pthread_mutex_unlock(&_mixerStorage.mutex);
  */
  
  _playerItem = playerItem;
  
  if (_playerItem != nil) {
    AVAssetTrack *audioTrack = [self getAudioTrack:_playerItem];
    if (audioTrack == nil) {
      return;
    }
    
    _numChannels = [self getNumChannels:audioTrack];
    
    AVMutableAudioMixInputParameters *inputParams = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:audioTrack];
  
    MTAudioProcessingTapCallbacks callbacks;
    callbacks.version = kMTAudioProcessingTapCallbacksVersion_0;
    callbacks.clientInfo = &_mixerStorage;
    callbacks.init = init;
    callbacks.prepare = prepare;
    callbacks.process = process;
    callbacks.unprepare = unprepare;
    callbacks.finalize = finalize;

    // The create function makes a copy of our callbacks struct
    MTAudioProcessingTapRef audioProcessingTap = nil;
    OSStatus err = MTAudioProcessingTapCreate(kCFAllocatorDefault, &callbacks,
                                              kMTAudioProcessingTapCreationFlag_PostEffects, &audioProcessingTap);
    if (err || !audioProcessingTap) {
      NSLog(@"Unable to create the Audio Processing Tap");
      return;
    }
    
    // Assign the tap to the input parameters
    inputParams.audioTapProcessor = audioProcessingTap;
    CFRelease(audioProcessingTap);
    [inputParams setVolume:1.0 atTime:kCMTimeZero];

    // Create a new AVAudioMix and assign it to our AVPlayerItem
    AVMutableAudioMix *audioMix = [AVMutableAudioMix audioMix];
    audioMix.inputParameters = @[inputParams];
    _playerItem.audioMix = audioMix;
  }
}

- (MixerInput *)mix
{
  MixerInput *mix = [[MixerInput alloc] initWithNumChannels:_numChannels];
  pthread_mutex_lock(&_mixerStorage.mutex);
  for (int i = 0; i < kMaxChannels; i++) {
    [mix setVolume:_mixerStorage.volumes[i] forChannel:i];
  }
  pthread_mutex_unlock(&_mixerStorage.mutex);
  return mix;
}

- (void)setMix:(MixerInput *)mixerInput
{
  if (mixerInput == nil) {
    return;
  }
  
  pthread_mutex_lock(&_mixerStorage.mutex);
  [mixerInput copyVolumes:&_mixerStorage.volumes[0] forNumChannels:_numChannels];
  pthread_mutex_unlock(&_mixerStorage.mutex);
}

@end
