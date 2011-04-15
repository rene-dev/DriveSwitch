//
//  DriveSwitchAppDelegate.m
//  DriveSwitch
//
//  Created by Rene Hopf on 4/4/11.
//  Copyright 2011 Reroo. All rights reserved.
//

#import "DriveSwitchAppDelegate.h"

@implementation DriveSwitchAppDelegate

@synthesize window;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    running = NO;
    defaults = [NSUserDefaults standardUserDefaults];
    disk.stringValue = [defaults objectForKey:@"disk"];
}

-(void)awakeFromNib{
    //Create the NSStatusBar and set its length
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    iconOff = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-off" ofType:@"png"]];
    iconOn  = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-on" ofType:@"png"]];
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:iconOff];
    
    //Tells the NSStatusItem what menu to load
    //[statusItem setMenu:statusMenu];
    [statusItem setAction:@selector(clickIcon)];
    //Sets the tooptip for our item
    [statusItem setToolTip:@"Drive Switch"];
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}

-(void)clickIcon{
    NSEvent *event = [NSApp currentEvent];
    if([event modifierFlags] & NSAlternateKeyMask) {
        [statusItem popUpStatusItemMenu:statusMenu];
    } else {
        [self toggleDrive];
    }
}

-(void)toggleDrive{
    if (running) {
        [self runSystemCommand:[NSString stringWithFormat:@"diskutil eject /dev/%@",disk.stringValue]];
        running = 0;
        [statusItem setImage:iconOff];
    } else {
        [self runSystemCommand:[NSString stringWithFormat:@"diskutil mount /dev/%@",disk.stringValue]];
        running = 1;
        [statusItem setImage:iconOn];
    }
}

- (IBAction)showSettings:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [settingsPanel makeKeyAndOrderFront:self];
}

- (void)windowWillClose:(NSNotification *)aNotification{
    [defaults setObject:disk.stringValue forKey:@"disk"];
    [defaults synchronize];
}

- (void) runSystemCommand:(NSString *)cmd{
    [NSTask launchedTaskWithLaunchPath:@"/bin/sh" arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
}

@end
