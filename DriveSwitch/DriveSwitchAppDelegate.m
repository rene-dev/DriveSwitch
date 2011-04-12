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
    // Insert code here to initialize your application
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
    [statusItem setAction:@selector(openWin:)];
    //Sets the tooptip for our item
    [statusItem setToolTip:@"Hardwrk Switch"];
    //Enables highlighting
    [statusItem setHighlightMode:YES];
}

-(void)openWin:(id)sender{
    NSEvent *event = [NSApp currentEvent];
    if([event modifierFlags] & NSAlternateKeyMask) {
        NSLog(@"control click");
    } else {
        [self switchESD:@""];
    }
}

-(IBAction)switchESD:(id)sender{
    
    if ([[[statusMenu itemAtIndex:0] title ] isEqualToString:@"Stopped"]) {
        
        
        runSystemCommand(@"diskutil mount /dev/disk1s2");
        [[statusMenu itemAtIndex:0] setTitle:@"Running"];
        [statusItem setImage:menuAlternateIcon];
    } else {
        runSystemCommand(@"diskutil eject /dev/disk1s2");
        [[statusMenu itemAtIndex:0] setTitle:@"Stopped"];
        [statusItem setImage:menuIcon];
    }
    
}

void runSystemCommand(NSString *cmd)
{
    [NSTask launchedTaskWithLaunchPath:@"/bin/sh"
                             arguments:[NSArray arrayWithObjects:@"-c", cmd, nil]];
}

@end
