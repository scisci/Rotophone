//
//  SideBarViewController.m
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "SideBarViewController.h"
#import "MicrophoneController.h"

static void *TransportStoppedKVOContext = &TransportStoppedKVOContext;
static void *TransportMutedKVOContext = &TransportMutedKVOContext;
static void *TransportVolumeKVOContext = &TransportVolumeKVOContext;

@implementation TransportView

@synthesize transport = _transport;

- (void)setTransport:(NSObject<MicrophoneTransport> *)transport {
    if (_transport != nil ) {
        // Remove observers
        [_transport removeObserver:self forKeyPath:@"isStopped"];
        [_transport removeObserver:self forKeyPath:@"canStop"];
        [_transport removeObserver:self forKeyPath:@"canStart"];
        [_transport removeObserver:self forKeyPath:@"isMuted"];
        [_transport removeObserver:self forKeyPath:@"volume"];
    }
    
    _transport = transport;
    
    if (_transport != nil) {
        // Add observers
        [_transport addObserver:self forKeyPath:@"isStopped" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:TransportStoppedKVOContext];
        [_transport addObserver:self forKeyPath:@"canStop" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:TransportStoppedKVOContext];
        [_transport addObserver:self forKeyPath:@"canStart" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:TransportStoppedKVOContext];
        [_transport addObserver:self forKeyPath:@"isMuted" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:TransportMutedKVOContext];
        [_transport addObserver:self forKeyPath:@"volume" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:TransportVolumeKVOContext];
        [self updateStoppedState];
    }
}

- (void)updateMutedState {
    if (_transport == nil) {
        return;
    }
    
    _muteButton.title = _transport.isMuted ? @"Unmute" : @"Mute";
    [self setNeedsDisplay:YES];
}

- (void)updateVolumeState {
    if (_transport == nil) {
        return;
    }
    
    _volumeSlider.floatValue = _transport.volume;
}

- (void)updateStoppedState {
    if (_transport == nil) {
        return;
    }

    _startStopButton.title = _transport.isStopped ? @"Start" : @"Stop";
    
    if ((_transport.isStopped && !_transport.canStart) || (!_transport.isStopped && !_transport.canStop)) {
        [_startStopButton setEnabled:NO];
    } else {
        [_startStopButton setEnabled:YES];
    }
    [self setNeedsDisplay:YES];
}

- (NSObject<MicrophoneTransport> *)transport {
    return _transport;
}

- (IBAction)handleStartStopButton:(id)sender {
    if (_transport == nil) {
        return;
    }
    
    if (_transport.isStopped) {
        [_transport start];
    } else {
        [_transport stop];
    }
}

- (IBAction)handleCalibrateButton:(id)sender {
    if (_transport == nil) {
        return;
    }
    
    [_transport calibrate];
}

- (IBAction)handleMuteButton:(id)sender {
    if (_transport == nil) {
        return;
    }
    
    if ([_transport isMuted]) {
        [_transport unmute];
    } else {
        [_transport mute];
    }
}

- (IBAction)handleVolumeSlider:(id)sender {
    if (_transport == nil) {
        return;
    }
    
    [_transport setVolume:[(NSSlider *)sender floatValue]];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == TransportStoppedKVOContext) {
        [self updateStoppedState];
    } else if (context == TransportMutedKVOContext) {
        [self updateMutedState];
    } else if (context == TransportVolumeKVOContext) {
        [self updateVolumeState];
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end

@interface StatusView ()

@end


@implementation StatusView

@synthesize status = _status;

- (void)setStatus:(id<MicrophoneStatus>)status {
    _status = status;
    
    NSString *label = @"Disconnected";
    
    if (_status != nil && _status.isConnected) {
        switch (_status.currentMode) {
            case kModeStartup:
                label = @"Starting up";
                break;
            case kModeIdle:
                label = @"Idle";
                break;
            case kModeCalibrate:
                label = @"Calibrating";
                break;
            case kModeRun:
                label = @"Running";
                break;
            case kModeLowPower:
                label = @"Paused";
                break;
            case kModeUnknown:
                label = @"Unknown Mode";
                break;
        
        }
    }
    
    [_statusLabel setStringValue:label];
    [self setNeedsDisplay:YES];
}

- (id<MicrophoneStatus>)status {
    return _status;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    NSColor *color = [NSColor grayColor];
    
    if (_status != nil && _status.isConnected) {
        switch (_status.currentMode) {
            case kModeStartup:
                color = [NSColor yellowColor];
                break;
            case kModeIdle:
                color = [NSColor brownColor];
                break;
            case kModeCalibrate:
                color = [NSColor purpleColor];
                break;
            case kModeRun:
                color = [NSColor greenColor];
                break;
            case kModeLowPower:
                color = [NSColor redColor];
                break;
            case kModeUnknown:
                color = [NSColor orangeColor];
                break;
        }
    }
    
    [color setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    // [super resizeSubviewsWithOldSize:oldSize];
    _statusLabel.frame = CGRectMake(0, 0, _frame.size.width, _frame.size.height);
}

@end


@interface SideBarView ()
@property (retain) NSTextView* rawView;
@end

@implementation SideBarView

- (void)resizeSubviewsWithOldSize:(NSSize)oldSize {
    // [super resizeSubviewsWithOldSize:oldSize];
    float transportHeight = 100;
    float statusHeight = 50;
    
    _transportView.frame = CGRectMake(0, _frame.size.height - transportHeight, _frame.size.width, transportHeight);
    _statusView.frame = CGRectMake(0, _frame.size.height - statusHeight - transportHeight, _frame.size.width, statusHeight);
    _rawView.frame = CGRectMake(0, 0, _frame.size.width, _frame.size.height - statusHeight - transportHeight);
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    [[NSColor orangeColor] setFill];
    NSRectFill(dirtyRect);
    [super drawRect:dirtyRect];
}
@end

@interface SideBarViewController ()
@end

@implementation SideBarViewController

- (void)loadView {
    [super loadView];
    
    
    SideBarView* sideBarView = (SideBarView *)self.view;
    // Do view setup here.
    sideBarView.rawView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 200, 200)];
    [sideBarView addSubview:sideBarView.rawView];
    
    [sideBarView.transportView.volumeSlider setMinValue:0.0];
    [sideBarView.transportView.volumeSlider setMaxValue:1.0];
}

- (void)handleRawData:(NSData *)rawData {
    // Append it to the text field
    NSString *text = [[NSString alloc] initWithData:rawData encoding:NSUTF8StringEncoding];
    if (text != nil) {
        SideBarView* sideBarView = (SideBarView *)self.view;
        [sideBarView.rawView insertText:text];
        //[sideBarView.rawView scrollRangeToVisible:NSMakeRange([[sideBarView.rawView string] length], 0)];
    }
}

@end
