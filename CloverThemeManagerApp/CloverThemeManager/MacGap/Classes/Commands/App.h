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
- (void) open:(NSString*)url;
- (void) launch:(NSString *)name;
- (void) removeMessage:(NSString *)messageToRemove;
@end
