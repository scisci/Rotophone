//
//  AudioMidiViewController.m
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "AudioMidiViewController.h"
#import "AudioMidiSettingsManager.h"
#import "RtMidi.h"

static void *AvailablePortsKVOContext = &AvailablePortsKVOContext;
static void *SelectedPortKVOContext = &SelectedPortKVOContext;

@interface AudioMidiViewController ()
{

}

@property (weak) IBOutlet NSPopUpButton *midiPortPopupButton;
@end

@implementation AudioMidiViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
  
    // Listen for changes to midi ports
    [[AudioMidiSettingsManager sharedManager] addObserver:self
                forKeyPath:@"selectedMidiPort"
                   options:(NSKeyValueObservingOptionNew |
                            NSKeyValueObservingOptionOld)
                   context:SelectedPortKVOContext];

    [self handlePortsChanged];
    [self handleSelectedPortChanged];
}

- (void)dealloc
{
  [[AudioMidiSettingsManager sharedManager] removeObserver:self forKeyPath:@"selectedMidiPort"];
}

- (IBAction)popupButtonSelectionDidChange:(id)sender {
  NSLog(@"popup button changed %@", sender);
  int selectedIndex = (int)_midiPortPopupButton.indexOfSelectedItem - 1;
  if (selectedIndex != AudioMidiSettingsManager.sharedManager.selectedMidiPort) {
    AudioMidiSettingsManager.sharedManager.selectedMidiPort = selectedIndex;
  }
}
- (IBAction)resetMidiProgramButtonWasPressed:(id)sender {
  
  [[NSNotificationCenter defaultCenter]
        postNotificationName:@"ResetMidiProgram"
        object:self];
}

- (void)handlePortsChanged
{
  NSArray *portNames = [[AudioMidiSettingsManager sharedManager] listMidiPorts];

  [_midiPortPopupButton removeAllItems];
  [_midiPortPopupButton addItemWithTitle: @"No Midi"];
  
  for (int i = 0; i < portNames.count; i++) {
    NSString *portName = [portNames objectAtIndex:i];
    [_midiPortPopupButton addItemWithTitle:[NSString stringWithFormat:@"%d %@", i+1, portName]];
  }
}

- (void)handleSelectedPortChanged
{
  AudioMidiSettingsManager* settings = [AudioMidiSettingsManager sharedManager];
  NSArray *portNames = [[AudioMidiSettingsManager sharedManager] listMidiPorts];
  int index = settings.selectedMidiPort;
  if (index < 0 || index >= portNames.count) {
    index = -1;
  }
  
  [_midiPortPopupButton selectItemAtIndex:index+1];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
  
    if (context == AvailablePortsKVOContext) {
        // Do something with the balance…
        [self handlePortsChanged];
    } else if (context == SelectedPortKVOContext) {
        [self handleSelectedPortChanged];
    }else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end
