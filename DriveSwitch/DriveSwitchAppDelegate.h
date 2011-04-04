//
//  DriveSwitchAppDelegate.h
//  DriveSwitch
//
//  Created by Rene Hopf on 4/4/11.
//  Copyright 2011 Reroo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DriveSwitchAppDelegate : NSObject <NSApplicationDelegate> {
@private
    NSWindow *window;
}

@property (assign) IBOutlet NSWindow *window;

@end
