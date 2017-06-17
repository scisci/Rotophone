//
//  BodyControlPanel.m
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "BodyControlPanel.h"
#import "Shape.h"

static void *RotationKVOContext = &RotationKVOContext;
static void *WidthKVOContext = &WidthKVOContext;
static void *HeightKVOContext = &HeightKVOContext;

@interface BodyControlPanelView ()

@end

@implementation BodyControlPanelView

@end

@interface BodyControlPanel ()

@end

@implementation BodyControlPanel

@synthesize entity = _entity;

- (void)loadView {
    [super loadView];
    // Do view setup here.
    
    BodyControlPanelView *bcpv = (BodyControlPanelView *)self.view;
    
    [bcpv.widthSlider setMinValue:1.0];
    [bcpv.widthSlider setMaxValue:100.0];
    [bcpv.heightSlider setMinValue:1.0];
    [bcpv.heightSlider setMaxValue:100.0];
    [bcpv.rotationSlider setMinValue:0.0];
    [bcpv.rotationSlider setMaxValue:2 * M_PI];
}


- (FieldEntity *)entity {
    return _entity;
}

- (void)dealloc {
    self.entity = nil;
}

- (void)setEntity:(FieldEntity *)entity {
    if (_entity != nil) {
        // Remove observers
        [_entity removeObserver:self forKeyPath:@"rotation"];
        [_entity removeObserver:self forKeyPath:@"width"];
        [_entity removeObserver:self forKeyPath:@"height"];
    }
    
    _entity = entity;
    
    if (_entity != nil) {
        
        // Add observers
        [_entity addObserver:self forKeyPath:@"rotation" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:RotationKVOContext];
        [_entity addObserver:self forKeyPath:@"width" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:WidthKVOContext];
        [_entity addObserver:self forKeyPath:@"height" options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew context:HeightKVOContext];
        [self updateControls];
    }
}

- (void)updateControls {
    BodyControlPanelView *view = (BodyControlPanelView *)self.view;
    view.rotationSlider.floatValue = [ShapeHelper counterClockwiseToClockwise:_entity.rotation.floatValue];
    view.widthSlider.floatValue = _entity.width.floatValue;
    view.heightSlider.floatValue = _entity.height.floatValue;
}


- (IBAction)handleWidthChanged:(id)sender {
    _entity.width = [NSNumber numberWithFloat:[(NSSlider *)sender floatValue]];
}

- (IBAction)handleHeightChanged:(id)sender {
    _entity.height = [NSNumber numberWithFloat:[(NSSlider *)sender floatValue]];
}

- (IBAction)handleRotationChanged:(id)sender {
    BodyControlPanelView *bcpv = (BodyControlPanelView *)self.view;
    _entity.rotation = [NSNumber numberWithFloat:[ShapeHelper clockwiseToCounterClockwise:[bcpv.rotationSlider floatValue]]];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (context == RotationKVOContext || context == WidthKVOContext || context==HeightKVOContext) {
        [self updateControls];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
