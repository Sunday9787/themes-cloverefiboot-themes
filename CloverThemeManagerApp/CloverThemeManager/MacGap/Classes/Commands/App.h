#import <Foundation/Foundation.h>

#import "WindowController.h"

@interface App : NSObject {

}

@property (nonatomic, retain) WebView *webView;

- (id) initWithWebView:(WebView *)view;

- (void) terminate;
- (void) activate;
- (void) hide;
- (void) unhide;
- (void) beep;
- (void) bounce;
- (void) setCustomUserAgent:(NSString *)userAgentString;
- (NSNumber*) systemIdleTime;

// blackosx add these lines - are these required? may delete them...
- (void) open;
- (void) launch;
- (void) WriteStringtoFile;
- (void) removeMessage:(NSString *)messageToRemove;
@end
