#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>


@interface URLResource : NSObject
- (instancetype)initWithURL:(NSURL *)url isScoped:(BOOL)scoped;
- (NSURL *)url;
@end


@interface SandboxFileManager : NSObject<NSOpenSavePanelDelegate>

- (instancetype)initWithPrefix:(NSString *)prefix;
- (void)openUrl:(NSURL *)url withCompletion:(void (^)(URLResource *resource))completion;
@end
