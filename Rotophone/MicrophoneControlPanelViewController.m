//
//  MicrophoneControlPanelViewController.m
//  Rotophone
//
//  Created by z on 6/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophoneControlPanelViewController.h"
#import "Entities.h"
#import "Shape.h"

@implementation MicrophoneControlPanelView

@end


@interface MicrophoneControlPanelViewController ()

@end

static void* MicrophoneBaseRotationKVOContext = &MicrophoneBaseRotationKVOContext;
static void* MicrophoneRotationTargetKVOContext = &MicrophoneRotationTargetKVOContext;
static void* MicrophonePickupKVOContext = &MicrophonePickupKVOContext;

@implementation MicrophoneControlPanelViewController
@synthesize microphone = _microphone;
- (IBAction)handlePickupAngleChanged:(id)sender {
    NSSlider* slider = (NSSlider *)sender;
    [_microphone setPickupAngle:slider.floatValue];
}
- (IBAction)handlePickupDistChanged:(id)sender {
    NSSlider* slider = (NSSlider *)sender;
    [_microphone setPickupDist:slider.floatValue];
}

- (IBAction)handleZeroClick:(id)sender {
    [_microphone setZero];
}
- (IBAction)handleRotationChanged:(id)sender {
    NSSlider* slider = (NSSlider *)sender;
    //float value = [2 * M_PI - [slider floatValue];
    [_microphone setRotoTarget:[slider floatValue]];
}
- (IBAction)handleBaseRotationChanged:(id)sender {
    NSSlider* slider = (NSSlider *)sender;
    //float value = 2 * M_PI - [slider floatValue];
    [_microphone setBaseRotation:[ShapeHelper clockwiseToCounterClockwise:[slider floatValue]]];
}

- (void)loadView {
    [super loadView];

    MicrophoneControlPanelView* controlPanelView = (MicrophoneControlPanelView *)self.view;
    controlPanelView.targetSlider.minValue = 0.0;
    controlPanelView.targetSlider.maxValue = 2 * M_PI;
    controlPanelView.rotationSlider.minValue = 0.0;
    controlPanelView.rotationSlider.maxValue = 2 * M_PI;
    controlPanelView.pickupAngleSlider.minValue = 0.0;
    controlPanelView.pickupAngleSlider.maxValue = 2 * M_PI;
    controlPanelView.pickupDistSlider.minValue = 56.0;
    controlPanelView.pickupDistSlider.maxValue = 240.0;
}

- (NSObject<MicrophoneProxy> *)microphone {
    return _microphone;
}

- (void)setMicrophone:(NSObject<MicrophoneProxy> *)microphone {
    if (_microphone != nil) {
        // Remove observers
        [_microphone.entity removeObserver:self forKeyPath:@"rotation"];
        [_microphone.entity removeObserver:self forKeyPath:@"rotoTarget"];
        [_microphone.entity removeObserver:self forKeyPath:@"pickupAngle"];
        [_microphone.entity removeObserver:self forKeyPath:@"pickupDist"];
    }
    
    _microphone = microphone;
    
    if (_microphone != nil) {
        
        // Add observers
        [_microphone.entity addObserver:self forKeyPath:@"rotation" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:MicrophoneBaseRotationKVOContext];
        [_microphone.entity addObserver:self forKeyPath:@"rotoTarget" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:MicrophoneRotationTargetKVOContext];
        [_microphone.entity addObserver:self forKeyPath:@"pickupAngle" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:MicrophonePickupKVOContext];
        [_microphone.entity addObserver:self forKeyPath:@"pickupDist" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:MicrophonePickupKVOContext];
        
         MicrophoneControlPanelView* controlPanelView = (MicrophoneControlPanelView *)self.view;
        controlPanelView.rotationSlider.floatValue = [ShapeHelper counterClockwiseToClockwise:_microphone.entity.rotation.floatValue];
        controlPanelView.targetSlider.floatValue = _microphone.entity.rotoTarget.floatValue;
        controlPanelView.pickupAngleSlider.floatValue = _microphone.entity.pickupAngle.floatValue;
        controlPanelView.pickupDistSlider.floatValue = _microphone.entity.pickupDist.floatValue;
    }
}

- (void)dealloc {
    self.microphone = nil;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    
    MicrophoneControlPanelView* controlPanelView = (MicrophoneControlPanelView *)self.view;
    if (context == MicrophoneBaseRotationKVOContext) {
        controlPanelView.rotationSlider.floatValue = [ShapeHelper counterClockwiseToClockwise:_microphone.entity.rotation.floatValue];
    } else if (context == MicrophoneRotationTargetKVOContext) {
        controlPanelView.targetSlider.floatValue = _microphone.entity.rotoTarget.floatValue;
    } else if (context == MicrophonePickupKVOContext) {
        controlPanelView.pickupAngleSlider.floatValue = _microphone.entity.pickupAngle.floatValue;
        controlPanelView.pickupDistSlider.floatValue = _microphone.entity.pickupDist.floatValue;
    }else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
