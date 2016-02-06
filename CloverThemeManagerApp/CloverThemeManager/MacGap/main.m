//
//  main.m
//  MacGap
//
//  Created by Alex MacCaw on 08/01/2012.
//  Copyright (c) 2012 Twitter. All rights reserved.
//

#import <Cocoa/Cocoa.h>

int main(int argc, char *argv[])
{
    [ud setObject:kCTM_SUFeedURL forKey:@"SUFeedURL"];
    [ud synchronize];
    return NSApplicationMain(argc, (const char **)argv);
}
