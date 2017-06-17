//
//  BodyControlPanel.h
//  Rotophone
//
//  Created by z on 6/17/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Entities.h"

@interface BodyControlPanelView : NSView
@property (unsafe_unretained) IBOutlet NSSlider *widthSlider;
@property (unsafe_unretained) IBOutlet NSSlider *height;
@property (unsafe_unretained) IBOutlet NSSlider *rotationSlider;
@end

@interface BodyControlPanel : NSViewController
- (IBAction)handleWidthChanged:(id)sender;
- (IBAction)handleHeightChanged:(id)sender;
- (IBAction)handleRotationChanged:(id)sender;

@property (retain) FieldEntity* entity;

@end
