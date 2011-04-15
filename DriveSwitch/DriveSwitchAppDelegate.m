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
}

-(void)awakeFromNib{
    
    //Create the NSStatusBar and set its length
    statusItem = [[[NSStatusBar systemStatusBar] statusItemWithLength:NSSquareStatusItemLength] retain];
    
    //Used to detect where our files are
    NSBundle *bundle = [NSBundle mainBundle];
    
    //Allocates and loads the images into the application which will be used for our NSStatusItem
    menuIcon = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-off" ofType:@"png"]];
    menuAlternateIcon = [[NSImage alloc] initWithContentsOfFile:[bundle pathForResource:@"icon-on" ofType:@"png"]];
    
    //Sets the images in our NSStatusItem
    [statusItem setImage:menuIcon];
    
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
        NSLog(@"control click");
        //[settingsPanel setIsVisible:YES];
        [statusItem popUpStatusItemMenu:statusMenu];
    } else {
        [self toggleDrive];
    }
}

-(void)toggleDrive{
    
    if (!running) {
        runSystemCommand(@"diskutil mount /dev/disk1s2");
        running = 1;
        [statusItem setImage:menuAlternateIcon];
    } else {
        runSystemCommand(@"diskutil eject /dev/disk1s2");
        running = 0;
        [statusItem setImage:menuIcon];
    }
}

- (IBAction)showSettings:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [settingsPanel makeKeyAndOrderFront:self];
}

void runSystemCommand(NSString *cmd)
{
    //[NSTask launchedTaskWithLaunchPath:@"/bin/sh"
      //                       arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
    NSLog(@"%@",cmd);
}

@end
