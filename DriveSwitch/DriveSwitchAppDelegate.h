//
//  DriveSwitchAppDelegate.h
//  DriveSwitch
//
//  Created by Rene Hopf on 4/4/11.
//  Copyright 2011 Reroo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <IOKit/pwr_mgt/IOPMLib.h>
#import <IOKit/IOMessage.h>

void initSleepNotifications (void);
void sleepCallback (void *rootPort, io_service_t y, natural_t msgType, void *msgArgument);

@interface DriveSwitchAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate> {
@private
    NSFileManager * filemanager;
    NSWindow *window;
    IBOutlet NSMenu *statusMenu;
    IBOutlet NSPanel *settingsPanel;
    IBOutlet NSPanel *debugPanel;
    IBOutlet NSTextField *disk;
    NSStatusItem * statusItem;
    NSImage *iconOff;
    NSImage *iconOn;
    NSUserDefaults* defaults;
    bool isMounted;
    NSMutableString *mountPath;
    IBOutlet NSTextView *outputText;
}

@property (assign) IBOutlet NSWindow *window;
@property (unsafe_unretained) NSTextView *outputText;

- (IBAction) list:(id)sender;
- (IBAction) checkMounted:(id)sender;
- (void) toggleDrive;
- (IBAction) showSettings:(id)sender;
- (IBAction) showDebug:(id)sender;
- (void) clickIcon;
- (void) wakeUp;
- (void) updateMounted;
- (void) readCompleted:(NSNotification *)notification;
- (void) mountReadCompleted:(NSNotification *)notification;
- (void) debugLog:(NSString *)string;
- (void) unmount;
- (void) mount;
- (void) lsof;
@end
