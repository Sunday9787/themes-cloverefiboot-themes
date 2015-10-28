//
//  Relaunch.m
//  relaunch
//
//  Created by Micky1979 on 27/10/15.
//  Copyright © 2015 CloverThemeManager. All rights reserved.
//

#import "Relaunch.h"

@interface Relaunch ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation Relaunch

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    // Blackosx - Clean any items from the App Support dir which could
    // cause a problem initiating the app if something changed server side.
    
    // Remove App Support theme.html
    NSError *error;
    NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:
                      @"Library/Application Support/CloverThemeManager/theme.html"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:path])
    {
        [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        
        if (error) NSLog(@"Clean and Relaunch: failed to remove theme.html.\n");
    }
    else
    {
        NSLog (@"Clean and Relaunch: theme.html was not present.");
    }
    
    // Remove App Support index.git
    error = nil;
    NSString *indexPath = [NSHomeDirectory() stringByAppendingPathComponent:
                      @"Library/Application Support/CloverThemeManager/index.git"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:indexPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:indexPath error:&error];
        
        if (error) NSLog(@"Clean and Relaunch: failed to remove index.git.\n");
    }
    else
    {
        NSLog (@"Clean and Relaunch: index.git was not present.");
    }
    
    // As we've removed the bare-git repo index.git then it makes sense to
    // remove the themes dir as that gets checked out from index.git
    
    // Remove App Support themes directory
    error = nil;
    NSString *themesDirPath = [NSHomeDirectory() stringByAppendingPathComponent:
                           @"Library/Application Support/CloverThemeManager/themes"];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:themesDirPath])
    {
        [[NSFileManager defaultManager] removeItemAtPath:themesDirPath error:&error];
        
        if (error) NSLog(@"Clean and Relaunch: failed to remove themes dir.\n");
    }
    else
    {
        NSLog (@"Clean and Relaunch: themes dir was not present.");
    }
    
    // Relaunch CloverThemeManager after a one second delay to allow the main
    // bash script enough time to exit once the pid of CloverThemeManager ends.
    [self performSelector:@selector(relaunch) withObject:nil afterDelay:1.0];
}

- (void)relaunch
{
    NSString *myBundlePath = [[NSBundle mainBundle] bundlePath];
    
    NSString *ThemeManagerPath = [[[myBundlePath stringByDeletingLastPathComponent]
                                   stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
    NSLog(@"Relaunching %@\n", ThemeManagerPath);
    [[NSWorkspace sharedWorkspace] launchApplication:ThemeManagerPath];
    [NSApp terminate:self];
}

@end
