//
//  AppDelegate.m
//  Rotophone
//
//  Created by z on 5/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"

#import "ORSSerialPort.h"
#import "Document.h"
#import "SimulationAudioUnit.h"

@interface SerialPortMenuItem : NSObject
@property NSMenuItem *menuItem;
@property ORSSerialPort *serialPort;
-(id) initWithSerialPort:(ORSSerialPort*)serialPort AndMenuItem:(NSMenuItem*)menuItem;
@end

@implementation SerialPortMenuItem
- (id) initWithSerialPort:(ORSSerialPort *)serialPort AndMenuItem:(NSMenuItem *)menuItem {
    self = [super init];
    if (self) {
        self.menuItem = menuItem;
        self.serialPort = serialPort;
    }
    return self;
}
@end

@interface AppDelegate ()
@property (retain) SimulationAudioUnit *pdAudioUnit;
@property (readwrite) BOOL appStarted;
@property (unsafe_unretained) IBOutlet NSApplication *application;

@property (retain) NSMutableArray* serialMenuItems;
@property (unsafe_unretained) IBOutlet NSMenuItem *availablePortStartSeparator;
@property (unsafe_unretained) IBOutlet NSMenuItem *noAvailablePortsMenuItem;
@end

@implementation AppDelegate

static void *PersonAccountBalanceContext = &PersonAccountBalanceContext;
static void *SelectedPortKVOContext = &SelectedPortKVOContext;

- (id)init {
    if (self = [super init]) {
        self.appStarted = false;
        self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
        self.serialPortHandler = [[SerialPortHandler alloc] init];
        self.pdAudioUnit = [[SimulationAudioUnit alloc] init];
        int result = [_pdAudioUnit configureWithSampleRate:44100.0 numberChannels:2 inputEnabled:NO];
    }
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    /*
    NSString *bundlePath = NSBundle.mainBundle.bundlePath;
    // Insert code here to initialize your application
    NSString *fileName = @"~/Library/LaunchAgents/Rotophone.plist".stringByExpandingTildeInPath;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:fileName]) {
        //create content - four lines of text
        NSString *content = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\
        <!DOCTYPE plist PUBLIC \"-//Apple Computer//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\
        <plist version=\"1.0\">\
        <dict>\
        <key>Label</key>\
        <string>com.considerthebelvedere</string>\
        <key>ProgramArguments</key>\
        <array>\
        <string>/bin/sh</string>\
        <string>%@</string>\
        </array>\
        <key>RunAtLoad</key>\
        <true/>\
        </dict>\
        </plist>", bundlePath];
        
        
        
        //save content to the documents directory
        [content writeToFile:fileName
                  atomically:YES
                    encoding:NSStringEncodingConversionAllowLossy
                       error:nil];
    }
    */
    // Try to install the launch script
    
    /*
     
     */
    _serialMenuItems = [[NSMutableArray alloc] initWithCapacity:0];
    
    
    
    [_serialPortManager addObserver:self forKeyPath:@"availablePorts" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:PersonAccountBalanceContext];
    [self handlePortsChanged];
    
    
    
    [_serialPortHandler addObserver:self
                         forKeyPath:@"selectedPort"
                            options:(NSKeyValueObservingOptionNew |
                                     NSKeyValueObservingOptionOld)
                            context:SelectedPortKVOContext];

    [self handleSelectedSerialPort];
    
    
    
    _pdAudioUnit.active = YES;
    _appStarted = true;
    
}

- (BOOL)applicationShouldOpenUntitledFile:(NSApplication *)sender
{
    // On startup, when asked to open an untitled file, open the last opened
    // file instead
    if (!_appStarted)
    {
        // Get the recent documents
        NSDocumentController *controller =
        [NSDocumentController sharedDocumentController];
        NSArray *documents = [controller recentDocumentURLs];
        
        // If there is a recent document, try to open it.
        if ([documents count] > 0)
        {
            NSError *error = nil;
            // point to last document saved
            NSInteger index = 0;
            [controller
             openDocumentWithContentsOfURL:[documents objectAtIndex:index]
             display:YES error:&error];
            
            // If there was no error, then prevent untitled from appearing.
            if (error == nil)
            {
                return NO;
            }
        }
    }
    
    return YES;
}


- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}




- (void)handlePortsChanged {
    NSArray *ports = _serialPortManager.availablePorts;

    for (SerialPortMenuItem *item in _serialMenuItems) {
        [item.menuItem.menu removeItem:item.menuItem];
    }
    
    NSMenu *menu = _availablePortStartSeparator.menu;
    NSInteger nextIndex = [menu indexOfItem:_availablePortStartSeparator] + 1;
    
    if (ports.count == 0) {
        [_noAvailablePortsMenuItem setHidden:FALSE];
    } else {
        [_noAvailablePortsMenuItem setHidden:TRUE];
        for (ORSSerialPort* port in ports) {
            NSMenuItem *menuItem = [[NSMenuItem alloc] initWithTitle:port.name action:@selector(selectPort:) keyEquivalent:@""];
            SerialPortMenuItem *item = [[SerialPortMenuItem alloc] initWithSerialPort:port AndMenuItem:menuItem];
            [menu insertItem:menuItem atIndex:nextIndex++];
            [_serialMenuItems addObject:item];
        }
    }
    
}

- (void)selectPort:(id)sender {
    NSMenuItem *menuItem = (NSMenuItem *)sender;
    NSLog(@"Select port %@", menuItem.title);
    
    
    
    for (SerialPortMenuItem *item in _serialMenuItems) {
        if (item.menuItem == menuItem) {
            // Select the port
            [_serialPortHandler setSelectedPort:item.serialPort];
        }
    }
    
    
}

- (void)handleSelectedSerialPort {
    for (SerialPortMenuItem *item in _serialMenuItems) {
        if (item.serialPort == _serialPortHandler.selectedPort) {
            [item.menuItem setState:NSOnState];
        } else {
            [item.menuItem setState:NSOffState];
        }
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == PersonAccountBalanceContext) {
        // Do something with the balance…
        [self handlePortsChanged];
    } else if (context == SelectedPortKVOContext) {
        [self handleSelectedSerialPort];
    }else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}


@end
