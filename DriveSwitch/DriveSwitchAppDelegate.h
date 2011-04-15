//
//  DriveSwitchAppDelegate.h
//  DriveSwitch
//
//  Created by Rene Hopf on 4/4/11.
//  Copyright 2011 Reroo. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface DriveSwitchAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate> {
@private
    NSWindow *window;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSPanel *settingsPanel;
    IBOutlet NSTextField *disk;
    NSStatusItem * statusItem;
    NSImage *iconOff;
    NSImage *iconOn;
    NSUserDefaults* defaults;
    bool running;
}

@property (assign) IBOutlet NSWindow *window;

- (void) toggleDrive;
- (IBAction) showSettings:(id)sender;
- (void) runSystemCommand:(NSString *)cmd;
- (void) clickIcon;

@end
