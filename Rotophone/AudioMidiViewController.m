//
//  AudioMidiViewController.m
//  Rotophone
//
//  Created by z on 11/25/18.
//  Copyright © 2018 Scientific Sciences. All rights reserved.
//

#import "AudioMidiViewController.h"
#import "AudioMidiSettingsManager.h"
#import <MIKMIDI/MIKMIDI.h>

static void *AvailablePortsKVOContext = &AvailablePortsKVOContext;
static void *SelectedPortKVOContext = &SelectedPortKVOContext;

@interface AudioMidiViewController ()

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
  
    [[MIKMIDIDeviceManager sharedDeviceManager] addObserver:self
                forKeyPath:@"availableDevices"
                   options:(NSKeyValueObservingOptionNew |
                            NSKeyValueObservingOptionOld)
                   context:AvailablePortsKVOContext];
  

    [self handlePortsChanged];
    [self handleSelectedPortChanged];
}

- (void)dealloc
{
  [[AudioMidiSettingsManager sharedManager] removeObserver:self forKeyPath:@"selectedMidiPort"];
  
  [[MIKMIDIDeviceManager sharedDeviceManager] removeObserver:self forKeyPath:@"availableDevices"];
}
- (IBAction)popupButtonSelectionDidChange:(id)sender {
  NSLog(@"popup button changed %@", sender);
  int selectedIndex = (int)_midiPortPopupButton.indexOfSelectedItem - 1;
  if (selectedIndex != AudioMidiSettingsManager.sharedManager.selectedMidiPort) {
    AudioMidiSettingsManager.sharedManager.selectedMidiPort = selectedIndex;
  }
}

- (void)handlePortsChanged
{
  NSArray *devices = [[MIKMIDIDeviceManager sharedDeviceManager] availableDevices];
  
  [_midiPortPopupButton removeAllItems];
  
  [_midiPortPopupButton addItemWithTitle: @"No Midi"];
  
  for (int i = 0; i < devices.count; i++) {
    MIKMIDIDevice *device = [devices objectAtIndex:i];
    [_midiPortPopupButton addItemWithTitle:[NSString stringWithFormat:@"%d %@ - %@", i+1, device.manufacturer, device.model]];
  }
}

- (void)handleSelectedPortChanged
{
  AudioMidiSettingsManager* settings = [AudioMidiSettingsManager sharedManager];
  NSArray *devices = [[MIKMIDIDeviceManager sharedDeviceManager] availableDevices];
  int index = settings.selectedMidiPort;
  if (index < 0 || index >= devices.count) {
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
