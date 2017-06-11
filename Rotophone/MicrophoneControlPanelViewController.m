//
//  MicrophoneControlPanelViewController.m
//  Rotophone
//
//  Created by z on 6/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MicrophoneControlPanelViewController.h"


@implementation MicrophoneControlPanelView

@end


@interface MicrophoneControlPanelViewController ()

@end

@implementation MicrophoneControlPanelViewController
- (IBAction)handleZeroClick:(id)sender {
    [_microphone setZero];
}
- (IBAction)handleRotationChanged:(id)sender {
    NSSlider* slider = (NSSlider *)sender;
    float value = 2 * M_PI - [slider floatValue];
    [_microphone setRotoTarget:value];
}
- (IBAction)handleBaseRotationChanged:(id)sender {
    NSSlider* slider = (NSSlider *)sender;
    float value = 2 * M_PI - [slider floatValue];
    [_microphone setBaseRotation:value];
}

- (void)loadView {
    [super loadView];

    MicrophoneControlPanelView* controlPanelView = (MicrophoneControlPanelView *)self.view;
    controlPanelView.targetSlider.minValue = 0.0;
    controlPanelView.targetSlider.maxValue = 2 * M_PI;
    controlPanelView.rotationSlider.minValue = 0.0;
    controlPanelView.rotationSlider.maxValue = 2 * M_PI;
}

@end
