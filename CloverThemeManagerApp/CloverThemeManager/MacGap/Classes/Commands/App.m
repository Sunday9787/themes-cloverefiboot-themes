#import "App.h"

#import "JSEventHelper.h"

// blackosx - add for writing file
#include <stdio.h>
FILE *newMesageFile;
#define BASH_TO_JS_LOG "/tmp/CloverThemeManager/bashToJs"

void WriteStringtoFile(const char *str, FILE *outfile);
@implementation App

@synthesize webView;

- (id) initWithWebView:(WebView *) view{
    self = [super init];
    
    if (self) {
        self.webView = view;
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                               selector: @selector(receiveSleepNotification:)
                                                                   name: NSWorkspaceWillSleepNotification object: NULL];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                               selector: @selector(receiveWakeNotification:)
                                                                   name: NSWorkspaceDidWakeNotification object: NULL];
        [[[NSWorkspace sharedWorkspace] notificationCenter] addObserver: self
                                                               selector: @selector(receiveActivateNotification:)
                                                                   name: NSWorkspaceDidActivateApplicationNotification object: NULL];
    }
    
    return self;
}

- (void) terminate {   
    [NSApp terminate:nil];
}

- (void) activate {
    [NSApp activateIgnoringOtherApps:YES];
}

- (void) hide {
    [NSApp hide:nil];
}

- (void) unhide {
    [NSApp unhide:nil];
}

- (void)beep {
    NSBeep();
}

- (void) bounce {
    [NSApp requestUserAttention:NSInformationalRequest];
}

- (void)setCustomUserAgent:(NSString *)userAgentString {
    [self.webView setCustomUserAgent: userAgentString];
}

- (void) open:(NSString*)url {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:url]];
}

- (void) launch:(NSString *)name
{
    //[[NSWorkspace sharedWorkspace] launchApplication:name];
    // blackosx - change this to send message to log file
    NSLog(@"%@",name);
}

// blackosx - add function to print to file
void WriteStringtoFile(const char *str, FILE *outfile)
{
    fprintf(outfile,"%s\n",str);
}

- (void) removeMessage:(NSString *)messageToRemove {
    // blackosx - add method for javascript to remove line from message log.

    // Read in existing file
    NSError* error = nil;
    NSString* contents = [NSString stringWithContentsOfFile:@BASH_TO_JS_LOG encoding:NSUTF8StringEncoding error:&error];
    if(error) { // If error object was instantiated, handle it.
        NSLog(@"ERROR while loading from file: %@", error);
    } else {
    
        // Open file for writing out
        newMesageFile = fopen(BASH_TO_JS_LOG,"w");
    
        // split by newlines into an array
        NSArray *splitFile = [contents componentsSeparatedByString:@"\n"];

        // Fast enumeration through original list
        for (NSString *item in splitFile) {
       
            // If item is not the one to remove && item is not empty, then write to file
            if (![messageToRemove isEqualToString:item] && [item length] != 0 ) {
                const char *itemToWrite = [item UTF8String];
                WriteStringtoFile(itemToWrite,newMesageFile);
            }
        }
    
        // close file
        fclose(newMesageFile);
    }
}


- (void)receiveSleepNotification:(NSNotification*)note{
    [JSEventHelper triggerEvent:@"sleep" forWebView:self.webView];
}

- (void) receiveWakeNotification:(NSNotification*)note{
    [JSEventHelper triggerEvent:@"wake" forWebView:self.webView];
}

- (void) receiveActivateNotification:(NSNotification*)notification{
    NSDictionary* userInfo = [notification userInfo];
    NSRunningApplication* runningApplication = [userInfo objectForKey:NSWorkspaceApplicationKey];
    if (runningApplication) {
        NSMutableDictionary* applicationDidGetFocusDict = [[NSMutableDictionary alloc] initWithCapacity:2];
        [applicationDidGetFocusDict setObject:runningApplication.localizedName
                                       forKey:@"localizedName"];
        [applicationDidGetFocusDict setObject:[runningApplication.bundleURL absoluteString]
                                       forKey:@"bundleURL"];
        
        [JSEventHelper triggerEvent:@"appActivated" withArgs:applicationDidGetFocusDict forWebView:self.webView];
    }
}


/*
 To get the elapsed time since the previous input event—keyboard, mouse, or tablet—specify kCGAnyInputEventType.
 */
- (NSNumber*)systemIdleTime {
    CFTimeInterval timeSinceLastEvent = CGEventSourceSecondsSinceLastEventType(kCGEventSourceStateHIDSystemState, kCGAnyInputEventType);
    
    return [NSNumber numberWithDouble:timeSinceLastEvent];
}


+ (NSString*) webScriptNameForSelector:(SEL)selector
{
    id	result = nil;
    
    if (selector == @selector(open:)) {
        result = @"open";
    } else if (selector == @selector(launch:)) {
        result = @"launch";
    } else if (selector == @selector(removeMessage:)) {
        result = @"removeMessage";
    } else if (selector == @selector(setCustomUserAgent:)) {
        result = @"setCustomUserAgent";
    } else if (selector == @selector(systemIdleTime)) {
        result = @"systemIdleTime";
    }
    
    return result;
}

+ (BOOL) isSelectorExcludedFromWebScript:(SEL)selector
{
    return NO;
}

+ (BOOL) isKeyExcludedFromWebScript:(const char*)name
{
    return YES;
}

@end
