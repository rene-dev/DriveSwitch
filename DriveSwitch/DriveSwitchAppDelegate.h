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
    IBOutlet NSMenu *statusMenu;
    NSStatusItem * statusItem;
    NSImage *menuIcon;
    NSImage *menuAlternateIcon;
}

@property (assign) IBOutlet NSWindow *window;

-(IBAction)switchESD:(id)sender;

void runSystemCommand(NSString *cmd);
-(void)openWin:(id)sender;

@end
