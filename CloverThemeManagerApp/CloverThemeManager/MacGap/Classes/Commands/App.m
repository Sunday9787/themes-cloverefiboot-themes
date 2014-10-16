#import "App.h"

#import "JSEventHelper.h"

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

- (void) launch:(NSString *)name {
    //[[NSWorkspace sharedWorkspace] launchApplication:name];
    // blackosx - change this to send message to log file
    NSLog(@"%@",name);
}



// Method by Carlos P from:
// http://stackoverflow.com/questions/6841937/authorizationexecutewithprivileges-is-deprecated

- (BOOL) runProcessAsAdministrator:(NSString*)scriptPath
                     withArguments:(NSArray *)arguments
                            output:(NSString **)output
                  errorDescription:(NSString **)errorDescription {
NSLog(@"runProcessAsAdministrator()\"%@\"",scriptPath);
    NSString * allArgs = [arguments componentsJoinedByString:@" "];
    NSString * fullScript = [NSString stringWithFormat:@"'%@' %@", scriptPath, allArgs];
NSLog(@"runProcessAsAdministrator()b");
    NSDictionary *errorInfo = [NSDictionary new];
    NSString *script =  [NSString stringWithFormat:@"do shell script \"%@\" with administrator privileges", fullScript];
NSLog(@"runProcessAsAdministrator()c");
    NSAppleScript *appleScript = [[NSAppleScript new] initWithSource:script];
NSLog(@"runProcessAsAdministrator()c1");
    NSAppleEventDescriptor * eventResult = [appleScript executeAndReturnError:&errorInfo];
NSLog(@"runProcessAsAdministrator()d");
    // Check errorInfo
    if (! eventResult)
    {
NSLog(@"runProcessAsAdministrator()error");
        // Describe common errors
        *errorDescription = nil;
        if ([errorInfo valueForKey:NSAppleScriptErrorNumber])
        {
            NSNumber * errorNumber = (NSNumber *)[errorInfo valueForKey:NSAppleScriptErrorNumber];
            if ([errorNumber intValue] == -128)
                *errorDescription = @"The administrator password is required to do this.";
        }
        
        // Set error message from provided message
        if (*errorDescription == nil)
        {
            if ([errorInfo valueForKey:NSAppleScriptErrorMessage])
                *errorDescription =  (NSString *)[errorInfo valueForKey:NSAppleScriptErrorMessage];
        }
        
        return NO;
    }
    else
    {
NSLog(@"runProcessAsAdministrator()success");
        // Set output to the AppleScript's output
        *output = [eventResult stringValue];
        
        return YES;
    }
}

// blackosx - add launchWithPrivilges to run bash script with admin privileges
- (void) launchWithPrivilges:(NSString *)name {
    NSString * output = nil;
    NSString * processErrorDescription = nil;
    BOOL success = [self runProcessAsAdministrator:@"/usr/bin/id"
                                     withArguments:[NSArray arrayWithObjects:@"-un", nil]
                                            output:&output
                                  errorDescription:&processErrorDescription];

    if (!success) // Process failed to run
    {
        // ...look at errorDescription
        NSLog(@"Gone wrong");
        
    }
    else
    {
        // ...process output
        NSLog(@"Worked");
        // blackosx added to run bash script on launch
        NSTask *task = [[NSTask alloc] init];
        NSString *taskPath =
        [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"public/bash/scriptAdmin.sh"];
        [task setLaunchPath: taskPath];
        [task launch];
        [task waitUntilExit];

    }
    
    NSLog(@"%@",name);
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
        
      // blackosx add launchWithPrivilges
    } else if (selector == @selector(launchWithPrivilges:)) {
        result = @"launchWithPrivilges";
        
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
