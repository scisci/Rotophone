//
//  ToolViewController.h
//  Rotophone
//
//  Created by z on 5/10/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@protocol ToolViewControllerDelegate<NSObject>
- (void)addBody;
- (void)deleteSelection;
- (void)setScale:(float)scale;
@end


@interface ToolbarView : NSView
@property (unsafe_unretained) IBOutlet NSButton *addBodyButton;
@property (unsafe_unretained) IBOutlet NSButton *deleteButton;
@property (unsafe_unretained) IBOutlet NSSlider *scaleSlider;
@end

@interface ToolView : NSView
@property (unsafe_unretained) IBOutlet ToolbarView *toolbarView;
@end

@interface ToolViewController : NSViewController
@property (retain) NSViewController* controlPanel;
@property (unsafe_unretained) id<ToolViewControllerDelegate> delegate;
- (IBAction)handleAddBodyButton:(id)sender;
- (IBAction)handleDeleteButton:(id)sender;
- (IBAction)handleScaleSliderChanged:(id)sender;
@end
