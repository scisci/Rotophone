#import "SandboxFileManager.h"


@interface URLResource ()
{
  NSURL *_url;
  BOOL _isScoped;
}

@end

@implementation URLResource
- (instancetype)initWithURL:(NSURL *)url isScoped:(BOOL)scoped
{
  if (self = [super init]) {
    _url = url;
    _isScoped = scoped;
    if (scoped) {
      [_url startAccessingSecurityScopedResource];
    }
  }
  
  return self;
}

- (NSURL *)url
{
  return _url;
}

- (void)dealloc
{
  if (_isScoped) {
    [_url stopAccessingSecurityScopedResource];
  }
}
@end

@interface SandboxFileManager() {
  NSString *_prefix;
}

@end

@implementation SandboxFileManager

- (instancetype)initWithPrefix:(NSString *)prefix
{
  if (self = [super init]) {
    _prefix = prefix;
  }
  
  return self;
}


- (BOOL)panel:(id)sender shouldEnableURL:(NSURL *)url {
  NSParameterAssert(url);
  
  // there were no mismatches (or no components meaning url is root)
  return YES;
}

- (NSString *)bookmarkKeyForURL:(NSURL *)url
{
  NSString *urlStr = [url absoluteString];
  return [NSString stringWithFormat:@"%1$@_%2$@", _prefix, urlStr];
}

- (NSData *)getBookmarkData:(NSURL *)url
{
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  
  // loop through the bookmarks one path at a time down the URL
  NSString *key = [self bookmarkKeyForURL:url];
  NSData *bookmark = [defaults dataForKey:key];
  return bookmark;
}

- (void)setBookmarkData:(NSURL *)url
{
  NSData *bookmarkData = [url bookmarkDataWithOptions:NSURLBookmarkCreationWithSecurityScope|NSURLBookmarkCreationSecurityScopeAllowOnlyReadAccess includingResourceValuesForKeys:nil relativeToURL:nil error:NULL];
  NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
  NSString *key = [self bookmarkKeyForURL:url];
  [defaults setObject:bookmarkData forKey:key];
}

- (void)openUrl:(NSURL *)url withCompletion:(void (^)(URLResource *resource))completion
{
  NSData *data = [self getBookmarkData:url];
  if (data != nil) {
    BOOL bookmarkDataIsStale;
    NSURL *allowedURL = [NSURL URLByResolvingBookmarkData:data options:NSURLBookmarkResolutionWithSecurityScope|NSURLBookmarkResolutionWithoutUI relativeToURL:nil bookmarkDataIsStale:&bookmarkDataIsStale error:NULL];
    if (!bookmarkDataIsStale) {
      completion([[URLResource alloc] initWithURL:allowedURL isScoped:true]);
      return;
    }
  }

  NSOpenPanel* panel = [NSOpenPanel openPanel];
  panel.delegate = self;

  [panel beginWithCompletionHandler:^(NSInteger result) {
    if (result == NSModalResponseOK) {
      NSURL*  allowedURL = [[panel URLs] objectAtIndex:0];
      [self setBookmarkData: allowedURL];
      completion([[URLResource alloc] initWithURL: allowedURL isScoped: false]);
      return;
    } else {
      completion(nil);
    }
   }];
}



@end
