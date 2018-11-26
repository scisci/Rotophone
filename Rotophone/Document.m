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
#import "VideoWindowController.h"
#import "PdFile.h"
#import "SerialPortHandler.h"
#import "MicrophoneShapeAdapter.h"
#import "MicrophoneController.h"
#import "MockDevice.h"
#import "SimulationController.h"
#import "PdBase.h"

// Video stuff
#import "SandboxFileManager.h"


#define USE_MOCK_DEVICE

static void *SelectedPortKVOContext = &SelectedPortKVOContext;
static void *MicrophoneConnectedKVOContext = &MicrophoneConnectedKVOContext;
static void *VolumeKVOContext = &VolumeKVOContext;
static void *MuteKVOContext = &MuteKVOContext;
static void *PerformKVOContext = &PerformKVOContext;
static void *MockKVOContext = &MockKVOContext;
static void *RawSerialKVOContext = &RawSerialKVOContext;


@interface Document () {
    MockDevice* _mockDevice;
}
@property (retain) PdFile *file;
@property (retain) PdFile *testGrain;
@property (retain) MicrophoneEntity *microphone;
@property (retain) SerialPortEntity *serialPortSettings;
@property (retain) SerialPortHandler *serialPortHandler;
@property (retain) MicrophoneController *microphoneController;
@property (retain) MainWindowController *mainWindowController;
@property (retain) VideoWindowController *videoWindowController;
@property (retain) SimulationController *simulationController;
@property (retain) DeviceProviderSelector *deviceSelector;
@property (retain) SandboxFileManager *sandboxFileManager;
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

- (SceneEntity *)getOrCreateScene {
    // See if we can get a microphone
    NSFetchRequest *request = [SceneEntity fetchRequestInContext:self.managedObjectContext];
    NSError *err = nil;
    NSArray *results = [self.managedObjectContext executeFetchRequest:request error:&err];
    if (err != nil) {
        return nil;
    }
    if (results.count == 0) {
        SceneEntity* scene = [[SceneEntity alloc] initWithContext:self.managedObjectContext];
        return scene;
        
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
    body.weight = [NSNumber numberWithFloat:1.0];
    field.pan = [NSNumber numberWithFloat:0.5];
    
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
        NSString* resourcePath = [filePath stringByAppendingPathComponent:@"Resources"];
        self.file = [PdFile openFileNamed:@"combined.pd" path:resourcePath];
        //self.testGrain = [PdFile openFileNamed:@"testpatch-particle.pd" path:resourcePath];
        self.deviceSelector = [[DeviceProviderSelector alloc] init];
        
        self.sandboxFileManager = [[SandboxFileManager alloc] initWithPrefix:@"roto"];
        
        NSLog(@"loading samples");
        // goods
        // whale2.wav
        // tv.wav
        // lynch.aif
        // horns.wav
        // bell.aif
        [self loadSampleBank:[NSArray arrayWithObjects:@"bell.aif", @"horns.wav", @"rocks1.wav", @"rocks.wav", @"glass.wav", @"pottery.aif", @"horns.wav", @"whale2.wav", nil]];
    }
    return self;
}

- (void)loadSampleBank:(NSArray *)paths {
    NSBundle* bundle = NSBundle.mainBundle;
    NSString* filePath = bundle.resourcePath;
    NSString* resourcePath = [filePath stringByAppendingPathComponent:@"Resources"];
    NSString* soundsPath = [resourcePath stringByAppendingPathComponent:@"sounds"];
    
    unsigned long size = paths.count;
    if (size > 8) {
        size = 8;
    }
    for (int i = 0; i < size; i++) {
        NSString* samplePath = [soundsPath stringByAppendingPathComponent: [paths objectAtIndex:i]];
        NSString *loadSampleParamName = [NSString stringWithFormat:@"%d-load_zample_%d", _file.dollarZero, i + 1];
        NSString *sampleName = [NSString stringWithFormat:@"%d-zample", i + 1];
        int result = [PdBase sendMessage:@"read"  withArguments:[NSArray arrayWithObjects:@"-resize", @"-maxsize", [NSNumber numberWithFloat:1e+07], samplePath, sampleName, nil] toReceiver:loadSampleParamName];
        if (result != 0) {
            NSLog(@"failed to load sample %@", [paths objectAtIndex:i]);
        }
    }


}



- (void)setupSerialPort:(id)sender {
    NSLog(@"setting up serial port");
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


- (void)setScale:(float)scale {
    SceneView *sceneView = (SceneView *)_mainWindowController.mainViewController.sceneViewController.view;
    sceneView.entity.scale = [NSNumber numberWithFloat:scale];
    [sceneView setNeedsDisplay:YES];
}

- (void)makeWindowControllers {
    
    AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
    
    self.microphone = [self getOrCreateMicrophone];
    self.serialPortSettings = [self getOrCreateSerialPortSettings];
    self.serialPortHandler = appDelegate.serialPortHandler;
    self.simulationController = [[SimulationController alloc] initWithPatch:_file];
    
    
    [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(setupSerialPort:) userInfo:nil repeats:NO];
    
 
    
    // Create a window
    self.mainWindowController = [[MainWindowController alloc] init];
    _mainWindowController.mainViewController.document = self;
    [self addWindowController:_mainWindowController];
  
    self.videoWindowController = [[VideoWindowController alloc] init];
    [self addWindowController:_videoWindowController];
  
    NSURL *fileUrl = [NSURL fileURLWithPath:@"/Users/scisci/xcode/VideoMixerTest/3chseq.mov"];
    [_sandboxFileManager openUrl:fileUrl withCompletion:^(URLResource *resource) {
      if (resource != nil) {
        [self->_videoWindowController.videoViewController openVideo: resource];
        [_simulationController setAVMixer:[self->_videoWindowController.videoViewController mixer]];
      }
    }];
    
    
    _mainWindowController.mainViewController.toolViewController.delegate = self;
    /*
#ifdef USE_MOCK_DEVICE
    
#else
    
#endif
    */
   
    self.microphoneController = [[MicrophoneController alloc] initWithEntity:_microphone andDeviceProvider:_deviceSelector];
    
    [_microphoneController addObserver:self
                         forKeyPath:@"status"
                         options:(NSKeyValueObservingOptionNew |
                                  NSKeyValueObservingOptionOld)
                         context:MicrophoneConnectedKVOContext];

    
    
    // Create a shape for the microphone
    SceneEntity *sceneEntity = [self getOrCreateScene];
    
    SceneView *sceneView = (SceneView *)_mainWindowController.mainViewController.sceneViewController.view;
    sceneView.entity = sceneEntity;
    
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
 
    
    
   // [_simulationController start];
    
    // Listen to changes to the transport and update
    [_microphoneController.transport addObserver:self forKeyPath:@"volume" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:VolumeKVOContext];
    [_microphoneController.transport addObserver:self forKeyPath:@"isMuted" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:MuteKVOContext];
    [_microphoneController.transport addObserver:self forKeyPath:@"isPerforming" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:PerformKVOContext];
    [_microphoneController.transport addObserver:self forKeyPath:@"isUsingMock" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:MockKVOContext];
    [_microphoneController.transport addObserver:self forKeyPath:@"isRawSerialEnabled" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:RawSerialKVOContext];
    
    [self updateVolumeState];
    [self updateMuteState];
    [self updatePerformState];
    [self updateRawSerialState];
    [self updateMockState];
}

- (void)updateMuteState {
    NSString *paramName = [NSString stringWithFormat:@"%d-mute", _file.dollarZero];
    [PdBase sendFloat:_microphoneController.transport.isMuted? 0.0 : 1.0 toReceiver:paramName];
}

- (void)updateVolumeState {
    NSString *paramName = [NSString stringWithFormat:@"%d-volume", _file.dollarZero];
    [PdBase sendFloat:_microphoneController.transport.volume toReceiver:paramName];
}

- (void)updatePerformState {
    if (_microphoneController.transport.isPerforming) {
        [_simulationController startPerform];
    } else {
        [_simulationController stopPerform];
    }
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
    [_microphoneController.transport removeObserver:self forKeyPath:@"volume"];
    [_microphoneController.transport removeObserver:self forKeyPath:@"isMuted"];
    [_microphoneController.transport removeObserver:self forKeyPath:@"isPerforming"];
    [_microphoneController.transport removeObserver:self forKeyPath:@"isUsingMock"];
    [_microphoneController.transport removeObserver:self forKeyPath:@"isRawSerialEnabled"];
    [_microphoneController removeObserver:self
                               forKeyPath:@"status"];

    _serialPortHandler.rawStreamHandler = nil;
}


- (void)updateRawSerialState {
    if (_microphoneController.transport.isRawSerialEnabled) {
        _serialPortHandler.rawStreamHandler =  _mainWindowController.mainViewController.sideBarViewController;
        
    } else {
        _serialPortHandler.rawStreamHandler = nil;
        
    }
}

- (void)updateMockState {
    if (_microphoneController.transport.isUsingMock) {
        if (_mockDevice == nil) {
            _mockDevice = [[MockDevice alloc] init];
        }
        _deviceSelector.deviceProvider = _mockDevice;
        
    } else {
        _deviceSelector.deviceProvider = _serialPortHandler;
    }
}



- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    
    if (context == MicrophoneConnectedKVOContext) {
        NSLog(@"Microphone status changed connected %d, mode %d.", _microphoneController.isConnected, _microphoneController.currentMode);
        
        SideBarView *sideBarView = (SideBarView *)_mainWindowController.mainViewController.sideBarViewController.view;
        sideBarView.statusView.status = _microphoneController.status;
        
        if (_microphoneController.currentMode == kModeRun) {
            [_simulationController start];
        } else {
            [_simulationController stop];
        }
        

        
        if (_microphoneController.isConnected && _serialPortHandler.selectedPort != nil) {
            _serialPortSettings.path = _serialPortHandler.selectedPort.path;
            _serialPortSettings.name = _serialPortHandler.selectedPort.name;
        }
    } else if (context == MuteKVOContext) {
        [self updateMuteState];
    } else if (context == VolumeKVOContext) {
        [self updateVolumeState];
    } else if (context == PerformKVOContext) {
        [self updatePerformState];
    } else if (context == MockKVOContext) {
        [self updateMockState];
    } else if (context == RawSerialKVOContext) {
        [self updateRawSerialState];
    }else {
        // Any unrecognized context must belong to super
        [super observeValueForKeyPath:keyPath
                             ofObject:object
                               change:change
                              context:context];
    }
}

@end


