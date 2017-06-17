//
//  BodyControlPanel.m
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "BodyControlPanel.h"


@interface BodyControlPanelView ()

@end

@implementation BodyControlPanelView

@end

@interface BodyControlPanel ()

@end

@implementation BodyControlPanel

- (void)loadView {
    [super loadView];
    // Do view setup here.
    
    BodyControlPanelView *bcpv = (BodyControlPanelView *)self.view;
    
    [bcpv.widthSlider setMinValue:1.0];
    [bcpv.widthSlider setMaxValue:100.0];
    [bcpv.height setMinValue:1.0];
    [bcpv.height setMaxValue:100.0];
    [bcpv.rotationSlider setMinValue:0.0];
    [bcpv.rotationSlider setMaxValue:2 * M_PI];
}

- (IBAction)handleWidthChanged:(id)sender {
    NSLog(@"change width of body");
    _entity.width = [NSNumber numberWithFloat:[(NSSlider *)sender floatValue]];
}

- (IBAction)handleHeightChanged:(id)sender {
    NSLog(@"change height of body");
    _entity.height = [NSNumber numberWithFloat:[(NSSlider *)sender floatValue]];
}

- (IBAction)handleRotationChanged:(id)sender {
    NSLog(@"change rotation of body");
    _entity.rotation = [NSNumber numberWithFloat:[(NSSlider *)sender floatValue]];
}
@end
