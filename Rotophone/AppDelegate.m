//
//  AppDelegate.m
//  Rotophone
//
//  Created by z on 5/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "AppDelegate.h"
#import "MainViewController.h"
#import "ORSSerialPortManager.h"
#import "ORSSerialPort.h"
#import "SerialPortHandler.h"

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
@property (retain) NSWindow* window;
@property (retain) MainViewController* rootViewController;

@property (retain) ORSSerialPortManager* serialPortManager;
@property (retain) SerialPortHandler* serialPortHandler;
@property (retain) NSMutableArray* serialMenuItems;
@property (unsafe_unretained) IBOutlet NSMenuItem *availablePortStartSeparator;
@property (unsafe_unretained) IBOutlet NSMenuItem *noAvailablePortsMenuItem;
@end

@implementation AppDelegate

static void *PersonAccountBalanceContext = &PersonAccountBalanceContext;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application
    
    // Create a window
    NSRect frame = NSMakeRect(0, 0, 200, 200);
    _window  = [[NSWindow alloc] initWithContentRect:frame
                                                     styleMask:NSTitledWindowMask | NSResizableWindowMask | NSClosableWindowMask | NSMiniaturizableWindowMask
                                                       backing:NSBackingStoreBuffered
                                                         defer:NO];
    [_window setBackgroundColor:[NSColor blueColor]];
    [_window makeKeyAndOrderFront:NSApp];
    
    self.rootViewController = [[MainViewController alloc] initWithNibName:@"MainViewController" bundle:nil];
    
    _window.contentView = _rootViewController.view;
    
    self.serialPortManager = [ORSSerialPortManager sharedSerialPortManager];
    self.serialPortHandler = [[SerialPortHandler alloc] init];
    
    [_serialPortManager addObserver:self forKeyPath:@"availablePorts" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:PersonAccountBalanceContext];
    
    _serialMenuItems = [[NSMutableArray alloc] initWithCapacity:0];
 
    [self handlePortsChanged];
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
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}


@end
