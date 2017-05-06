//
//  MainViewController.m
//  Rotophone
//
//  Created by z on 5/6/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()
@property (retain) NSSound *sound;
@end

@implementation MainViewController

- (void)loadView {
    [super loadView];
    // Do view setup here.
}

- (IBAction)handleSoundButton:(id)sender {
    NSLog(@"sound button");
    NSBundle* bundle = NSBundle.mainBundle;
    NSString* filePath = [bundle pathForResource:@"Two Steps From Hell - Ashes (Halloween)" ofType:@"mp3" inDirectory:@"Resources"];
    
    NSLog(@"Got file path %@", filePath);
    
    _sound = [[NSSound alloc] initWithContentsOfFile:filePath byReference: YES];
    [_sound play];
}

@end
