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

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (retain, nonatomic) WindowController *windowController;

// Blackosx added
// ref: http://stackoverflow.com/questions/15842226/how-to-enable-main-menu-item-copy
@property (assign) IBOutlet NSWindow *window;
@property (strong) IBOutlet NSMenuItem *openLog;


@end
