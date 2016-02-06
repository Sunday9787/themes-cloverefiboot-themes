//
//  AppDelegate.h
//  MacGap
//
//  Created by Alex MacCaw on 08/01/2012.
//  Copyright (c) 2012 Twitter. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "Classes/ContentView.h"
#import "WindowController.h"
#import <Sparkle/Sparkle.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (retain, nonatomic) WindowController *windowController;

// Blackosx added
// ref: http://stackoverflow.com/questions/15842226/how-to-enable-main-menu-item-copy
@property (assign) IBOutlet NSWindow *window;
@property (assign) IBOutlet NSWindow *SparkleWindow;
@property (strong) IBOutlet NSMenuItem *openLog;
@property (strong) IBOutlet NSMenuItem *openSparklePref;
@property (strong) IBOutlet NSMenuItem *sparkleCheckForUpdates;


@property (assign) IBOutlet NSButton *SparkleAutoCheck;
@property (assign) IBOutlet NSButton *SparkleAutoDownload;
@property (assign) IBOutlet NSPopUpButton *SparkleTimingPopup;
@property (assign) IBOutlet NSTextField *SparkleLastUpdateField;
@end
