//
//  Document.m
//  Rotophone
//
//  Created by z on 5/5/17.
//  Copyright © 2017 Scientific Sciences. All rights reserved.
//

#import "Document.h"
#import "Entities.h"
#import "AppDelegate.h"
#import "MainWindowController.h"
#import "objc/PdFile.h"
#import "SerialPortHandler.h"
#import "MicrophoneShapeAdapter.h"
#import "MicrophoneController.h"
#import "MockDevice.h"
#import "SimulationController.h"

static void *SelectedPortKVOContext = &SelectedPortKVOContext;
static void *MicrophoneConnectedKVOContext = &MicrophoneConnectedKVOContext;


@interface Document ()
@property (retain) PdFile *file;
@property (retain) MicrophoneEntity *microphone;
@property (retain) SerialPortEntity *serialPortSettings;
@property (retain) SerialPortHandler *serialPortHandler;
@property (retain) MicrophoneController *microphoneController;
@property (retain) MainWindowController *mainWindowController;
@property (retain) SimulationController *simulationController;
@end

@implementation Document
+ (BOOL)usesUbiquitousStorage {
    return NO;
}

-(void)shapeSelectionChangedFrom:(id<Shape>)old To:(id<Shape>)selection {
    // New selection
    NSLog(@"new slection");
}

- (MicrophoneEntity *)getOrCreateMicrophone {
    // See if we can get a microphone
    NSFetchRequest *request = [MicrophoneEntity fetchRequestInContext:self.managedObjectContext];
    NSError *err = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&err];
    if (err != nil) {
        return nil;
    }
    if (results.count == 0) {
        MicrophoneEntity* microphone = [[MicrophoneEntity alloc] initWithName:@"azxyz" andContext:self.managedObjectContext];
        microphone.originX  = [NSNumber numberWithFloat:20.0];
        microphone.originY = [NSNumber numberWithFloat:40.0];
        microphone.rotation = [NSNumber numberWithFloat:45.0];
        return microphone;

    }
    
    return [results objectAtIndex:0];
}

- (BodyEntity *)createBody {
    // First create a field
    FieldEntity* field = [[FieldEntity alloc] initWithName:@"somefield" andContext:self.managedObjectContext];
    field.width = [NSNumber numberWithFloat:20.0];
    field.height = [NSNumber numberWithFloat:5.0];
    field.originX = [NSNumber numberWithFloat:0];
    field.originY = [NSNumber numberWithFloat:0];
    field.rotation = [NSNumber numberWithFloat:0];
    BodyEntity* body = [[BodyEntity alloc] initWithName:@"somebody" andContext:self.managedObjectContext];
    
    NSMutableSet *mutableSet = [body mutableSetValueForKey:@"fields"];
    [mutableSet addObject:field];
    return body;
}

- (NSArray *)bodies {
    NSFetchRequest *request = [BodyEntity fetchRequestInContext:self.managedObjectContext];
    NSError *err = nil;
   NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&err];
    if (err != nil) {
        NSLog(@"error getting bodies!");
        return [[NSArray alloc] init];
    }
    return results;
}

- (SerialPortEntity *)getOrCreateSerialPortSettings {
    NSFetchRequest *request = [SerialPortEntity fetchRequestInContext:self.managedObjectContext];
    NSError *err = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&err];
    if (err != nil) {
        return nil;
    }
    
    if (results.count == 0) {
        SerialPortEntity* serialPortSettings = [[SerialPortEntity alloc] initWithName:@"" Path:@"" andContext:self.managedObjectContext];
        return serialPortSettings;
    }
    
    return [results objectAtIndex:0];

}

- (instancetype)init {
    self = [super init];
    if (self) {
        // Add your subclass-specific initialization here.
        // Create a microphone object
        
                NSBundle* bundle = NSBundle.mainBundle;
        NSString* filePath = bundle.resourcePath;
        filePath = [filePath stringByAppendingPathComponent:@"Resources"];
        self.file = [PdFile openFileNamed:@"testpatch-sine.pd" path:filePath];
        
        
            }
    return self;
}


- (void)setupSerialPort {
    // If no serial port is selected, then try to pull one from
    // the saved state.
    if (_serialPortHandler.selectedPort == nil) {
        NSString *savedPath = _serialPortSettings.path;
        if (savedPath != nil && savedPath.length > 0) {
            // Select the port with the given path.
            [_serialPortHandler selectPortByPath: savedPath];
        }
    }
}

+ (BOOL)autosavesInPlace {
    return YES;
}


- (void)makeWindowControllers {
    
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    
    self.microphone = [self getOrCreateMicrophone];
    self.serialPortSettings = [self getOrCreateSerialPortSettings];
    self.serialPortHandler = appDelegate.serialPortHandler;
    self.simulationController = [[SimulationController alloc] init];
    
    [self setupSerialPort];

    
    // Create a window
    self.mainWindowController = [[MainWindowController alloc] init];
    _mainWindowController.mainViewController.document = self;
    [self addWindowController:_mainWindowController];
    
    
    _mainWindowController.mainViewController.toolViewController.delegate = self;
    //MockDevice* device = [[MockDevice alloc] init];
    //[device setPosition: 0.3];
    
    SerialPortHandler* device = _serialPortHandler;
    
    self.microphoneController = [[MicrophoneController alloc] initWithEntity:_microphone andDeviceProvider:device];
    
    [_microphoneController addObserver:self
                         forKeyPath:@"status"
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:MicrophoneConnectedKVOContext];

    
    
    // Create a shape for the microphone
    
    SceneView *sceneView = (SceneView *)_mainWindowController.mainViewController.sceneViewController.view;
    
    _simulationController.scene = sceneView;
    [_simulationController addMicrophone:_microphoneController];
    
    // Add any boides
    NSArray *bodies = [self bodies];
    for (BodyEntity* body in bodies) {
        [_simulationController addBody:body];
    }
    
    
    
    SideBarView *sideBarView = (SideBarView *)_mainWindowController.mainViewController.sideBarViewController.view;
    sideBarView.statusView.status = _microphoneController.status;
    
    sideBarView.transportView.transport = _microphoneController.transport;
 
    
    _serialPortHandler.rawStreamHandler =  _mainWindowController.mainViewController.sideBarViewController;
}

- (void)addBody {
    BodyEntity *body = [self createBody];
    [_simulationController addBody:body];
}



- (void)deleteSelection {
    SceneView *sceneView = (SceneView *)_mainWindowController.mainViewController.sceneViewController.view;
    if (sceneView.selection != nil) {
        [_simulationController removeShape:sceneView.selection];
    }
}

- (void)dealloc {
    [_serialPortHandler removeObserver:self forKeyPath:@"selectedPort"];
    _serialPortHandler.rawStreamHandler = nil;
}




- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == MicrophoneConnectedKVOContext) {
        NSLog(@"Microphone status changed connected %d, mode %d.", _microphoneController.isConnected, _microphoneController.currentMode);
        
        SideBarView *sideBarView = (SideBarView *)_mainWindowController.mainViewController.sideBarViewController.view;
        sideBarView.statusView.status = _microphoneController.status;
        

        
        if (_microphoneController.isConnected && _serialPortHandler.selectedPort != nil) {
            _serialPortSettings.path = _serialPortHandler.selectedPort.path;
            _serialPortSettings.name = _serialPortHandler.selectedPort.name;
        }
    } else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end


