//
//  AppDelegate.m
//  MacGap
//
//  Created by Alex MacCaw on 08/01/2012.
//  Copyright (c) 2012 Twitter. All rights reserved.
//
//  Edited by Blackosx - October 2014
//
#import "AppDelegate.h"

#define BASH_TO_JS_LOG "/tmp/CloverThemeManager/bashToJs"

@implementation AppDelegate

@synthesize windowController;


#pragma mark app initialization
- (void) applicationWillFinishLaunching:(NSNotification *)aNotification
{
    [self loadSparkleSettings];
    if (floor(kCFCoreFoundationVersionNumber) >= kCFCoreFoundationVersionNumber10_9)
    {
#define MAVERICKS_ONWARDS 1
    }
}

-(BOOL)applicationShouldHandleReopen:(NSApplication*)application
                   hasVisibleWindows:(BOOL)visibleWindows{
    if(!visibleWindows){
        [self.windowController.window makeKeyAndOrderFront: nil];
    }
    return YES;
}

- (void) applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.windowController = [[WindowController alloc] initWithURL: kStartPage];
    [self.windowController showWindow: [NSApplication sharedApplication].delegate];
    self.windowController.contentView.webView.alphaValue = 1.0;
    self.windowController.contentView.alphaValue = 1.0;
    [self.windowController showWindow:self];
    
    // blackosx added to run bash script on launch
    NSTask *task = [[NSTask alloc] init];
    NSString *taskPath =
    [NSString stringWithFormat:@"%@/%@",[[NSBundle mainBundle] resourcePath], @"public/bash/script.sh"];
    [task setLaunchPath: taskPath];
    [task launch];
    //[task waitUntilExit];
    
    // blackosx add redirect the nslog output to file instead of console
    // Create a directory in tmp
    // http://www.techotopia.com/index.php/Working_with_Directories_in_Objective-C
    NSFileManager *filemgr;
    filemgr = [NSFileManager defaultManager];
    NSURL *newDir = [NSURL fileURLWithPath:@"/tmp/CloverThemeManager"];
    [filemgr createDirectoryAtURL: newDir withIntermediateDirectories:YES attributes: nil error:nil];
    
    // Changing to a Different Directory
    NSString *currentpath;
    filemgr = [NSFileManager defaultManager];
    currentpath = [filemgr currentDirectoryPath];
    NSLog (@"Current directory is %@", currentpath);
    if ([filemgr changeCurrentDirectoryPath: @"/tmp/CloverThemeManager"] == NO)
        NSLog (@"Cannot change directory.");
    currentpath = [filemgr currentDirectoryPath];
    NSLog (@"Current directory is %@", currentpath);
    
    // Set log path
    // http://stackoverflow.com/questions/3184235/how-to-redirect-the-nslog-output-to-file-instead-of-console
    NSString *logPath = [currentpath stringByAppendingPathComponent:@"jsToBash"];
    freopen([logPath fileSystemRepresentation],"a+",stderr);
    
    // blackosx - create file to act as log for bash to send messages to javascript
    [[NSFileManager defaultManager] createFileAtPath:@"/tmp/CloverThemeManager/bashToJs" contents:nil attributes:nil];
    
    // test writing to file
    //NSString *str = @"1@Test\n2@Arse\n3@Box\n4@Car\n5@Raver\n6@Chicken\n7@Random\n8@Key\n9@Otter\n";
    //[str writeToFile:@BASH_TO_JS_LOG atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark helper functions
- (NSString *)pathForTemporaryFileWithPrefix:(NSString *)prefix
{
    NSString *  result;
    CFUUIDRef   uuid;
    CFStringRef uuidStr;
    
    uuid = CFUUIDCreate(NULL);
    assert(uuid != NULL);
    
    uuidStr = CFUUIDCreateString(NULL, uuid);
    assert(uuidStr != NULL);
    
    result = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@", prefix, uuidStr]];
    assert(result != nil);
    
    CFRelease(uuidStr);
    CFRelease(uuid);
    
    return result;
}

// Blackosx added to respond to menu item action to open log file in Finder
// ref: http://stackoverflow.com/questions/15842226/how-to-enable-main-menu-item-copy
- (IBAction)openLog:(id)sender;
{
    NSString * path    = @"/tmp/CloverThemeManager/CloverThemeManagerLog.txt";
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        NSURL    * fileURL = [NSURL fileURLWithPath: path];
        NSWorkspace * ws = [NSWorkspace sharedWorkspace];
        [ws openURL: fileURL];
    }
    else
    {
#if __has_feature(objc_arc)
        // working in ARC
        NSAlert* alert = [[NSAlert alloc] init];
#else
        // non ARC
        NSAlert* alert = [[[NSAlert alloc] init] autorelease];
#endif
        [alert setMessageText: @"CloverThemeManagerLog.txt does not exist!"];
        [alert addButtonWithTitle: @"OK"];
        [alert runModal];
    }
}

#pragma mark self relaunch + clean
// Micky1979 added the reset option and relaunch function
- (IBAction)reset:(id)sender
{
    
#if __has_feature(objc_arc)
    // working in ARC
    NSAlert* alert = [[NSAlert alloc] init];
#else
    // non ARC
    NSAlert* alert = [[[NSAlert alloc] init] autorelease];
#endif
    
    [alert setMessageText: @"Please confirm you wish to Clean and Relaunch Clover Theme Manager"];
    [alert addButtonWithTitle: @"Clean and Relaunch"];
    [alert addButtonWithTitle: @"Cancel"];
    if ([alert runModal] == NSAlertFirstButtonReturn)
    {
        NSLog (@"Clean and Relaunch chosen");
        [self relaunch];
    }
    else
    {
        NSLog (@"Clean and Relaunch cancelled");
    }
}

- (void)cleanTmpDir
{
    // Moved Micky1979's code from Relaunch.m to here.
    // Delete temporary files from the previous execution:
    NSError *error;
    NSLog(@"Deleting /private/tmp/CloverThemeManager directory.\n");
    if ([[NSFileManager defaultManager] fileExistsAtPath:@"/private/tmp/CloverThemeManager"])
    {
        [[NSFileManager defaultManager] removeItemAtPath:@"/private/tmp/CloverThemeManager" error:&error];
        
        if (error) NSLog(@"Problem encountered deleting /private/tmp/CloverThemeManager directory.\n");
    } else
    {
        NSLog(@"/private/tmp/CloverThemeManager directory not found.\n");
    }
    
    usleep(500000); // 1/2 second
}

- (void)relaunch
{
    
    NSString *relaunchApp = [[[NSBundle mainBundle] builtInPlugInsPath]
                             stringByAppendingPathComponent:@"relaunch.app"];
    
    [[NSWorkspace sharedWorkspace] launchApplication:relaunchApp];
    [NSApp terminate:self];
}

#pragma mark Sparkle updater
- (IBAction)openSparklePref:(id)sender
{
#ifdef MAVERICKS_ONWARDS
    // 10.9 onwards, untill now (10.11.x)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSApp mainWindow] beginSheet:self.SparkleWindow completionHandler:^(NSModalResponse returnCode) {
            
        }];
    });
#else
    // deprecated in 10.9 but used by older OSes
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp beginSheet:self.SparkleWindow  modalForWindow:(NSWindow *)[NSApp mainWindow] modalDelegate:self didEndSelector:nil contextInfo:nil];
    });
#endif
}

- (IBAction)endSparklePref:(id)sender
{
#ifdef MAVERICKS_ONWARDS
    // 10.9 onwards, until now (10.11.x)
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[NSApp mainWindow] sheetParent] endSheet:self.SparkleWindow returnCode:NSModalResponseOK];
        [self.SparkleWindow  orderOut:self];
    });
#else
    // deprecated in 10.9 but used by older OSes
    dispatch_async(dispatch_get_main_queue(), ^{
        [NSApp endSheet:self.SparkleWindow];
        [self.SparkleWindow orderOut:sender];
    });
#endif
}

- (void)loadSparkleSettings
{
    SUUpdater*sharedUpdater = [SUUpdater sharedUpdater];
    
    if ([ud objectForKey:kSULastCheckTime])
    {
        self.SparkleLastUpdateField.stringValue = [ud objectForKey:kSULastCheckTime];
    }
    else
    {
        self.SparkleLastUpdateField.stringValue = @"Never!";
    }
    
    self.SparkleAutoCheck.state = [ud integerForKey:kSUEnableAutomaticChecks] == 0 ? NSOffState : NSOnState;
    self.SparkleAutoDownload.state = [ud integerForKey:kSUAutomaticallyUpdate] == 0 ? NSOffState : NSOnState;
    
    [self.SparkleTimingPopup selectItemWithTag:
     ([ud integerForKey:kSUScheduledCheckInterval] != 0) ? [ud integerForKey:kSUScheduledCheckInterval] : kDefaultCheckInterval];
    
    [sharedUpdater setAutomaticallyChecksForUpdates:([ud integerForKey:kSUEnableAutomaticChecks] == 0 ) ? NO : YES];
    [sharedUpdater setAutomaticallyDownloadsUpdates:([ud integerForKey:kSUAutomaticallyUpdate] == 1 ) ? YES : NO];
    [sharedUpdater setUpdateCheckInterval:self.SparkleTimingPopup.selectedTag];
    
    [self saveSparkleSetting:nil];
}
- (IBAction)saveSparkleSetting:(id)sender
{
 
    self.SparkleTimingPopup.enabled = self.SparkleAutoCheck.state == NSOnState ? NO : YES;
    
    [ud setBool:self.SparkleAutoCheck.state forKey:kSUEnableAutomaticChecks];
    [ud setBool:self.SparkleAutoDownload.state forKey:kSUAutomaticallyUpdate];
    [ud setInteger:self.SparkleTimingPopup.selectedTag forKey:kSUScheduledCheckInterval];
    [ud synchronize];
}

- (IBAction)sparkleCheckForUpdates:(id)sender
{
    [[SUUpdater sharedUpdater] checkForUpdates:sender];
}

#pragma mark tear down
// blackosx added to quit application on window close.
// http://stackoverflow.com/questions/14449986/quitting-an-app-using-the-red-x-button
- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)theApplication
{
    [self cleanTmpDir];
    return YES;
}

// blackosx added to quit application on command-q.
- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)theApplication
{
    [self cleanTmpDir];
    return YES;
}

@end