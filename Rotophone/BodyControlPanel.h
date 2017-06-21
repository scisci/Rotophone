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
@property (unsafe_unretained) IBOutlet NSSlider *heightSlider;
@property (unsafe_unretained) IBOutlet NSSlider *rotationSlider;
@property (unsafe_unretained) IBOutlet NSTextField *nameField;
@property (unsafe_unretained) IBOutlet NSSlider *weightField;
@property (unsafe_unretained) IBOutlet NSSlider *panField;
@end

@interface BodyControlPanel : NSViewController
- (IBAction)handleWidthChanged:(id)sender;
- (IBAction)handleHeightChanged:(id)sender;
- (IBAction)handleRotationChanged:(id)sender;

@property (retain) BodyEntity* bodyEntity;
@property (retain) FieldEntity* entity;

@end
