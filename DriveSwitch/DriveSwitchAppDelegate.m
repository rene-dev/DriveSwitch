//
//  DriveSwitchAppDelegate.m
//  DriveSwitch
//
//  Created by Rene Hopf on 4/4/11.
//  Copyright 2011 Reroo. All rights reserved.
//

#import "DriveSwitchAppDelegate.h"

id objcptr;

void initSleepNotifications (void)
{
	static io_connect_t	rootPort;
	
	IONotificationPortRef	notificationPort;
	io_object_t		notifier;
    
	rootPort = IORegisterForSystemPower(&rootPort, &notificationPort, sleepCallback, &notifier);
	if (! rootPort) {
		NSLog(@"IORegisterForSystemPower failed");
	}
	CFRunLoopAddSource (CFRunLoopGetCurrent(), IONotificationPortGetRunLoopSource(notificationPort), kCFRunLoopDefaultMode);
}

void sleepCallback (void *rootPort, io_service_t y, natural_t msgType, void *msgArgument)
{
    if (msgType == kIOMessageSystemHasPoweredOn) {
        [objcptr wakeUp];
    }
}

@implementation DriveSwitchAppDelegate

@synthesize window,outputText;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    objcptr = self;
    initSleepNotifications();
    defaults = [NSUserDefaults standardUserDefaults];
    disk.stringValue = [defaults objectForKey:@"disk"];
    mountPath = [[NSMutableString alloc] init];
    [self updateMounted];
    if (isMounted) {
        [statusItem setImage:iconOn];
    }else{
        [statusItem setImage:iconOff];
    }
    
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
    filemanager = [NSFileManager defaultManager];
}

-(void)clickIcon{
    NSEvent *event = [NSApp currentEvent];
    if([event modifierFlags] & NSAlternateKeyMask) {
        [statusItem popUpStatusItemMenu:statusMenu];
    } else {
        [self toggleDrive];
    }
}

-(void)lsof{
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setLaunchPath:@"/usr/sbin/lsof"];
    [task setArguments:@[@"-Fc",mountPath]];
    [task setStandardOutput:outputPipe];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(readCompleted:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[outputPipe fileHandleForReading]];
    [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    [task launch];
    [task release];
}

- (IBAction)list:(id)sender {
    [self lsof];
    /*
    NSArray *keys = [NSArray arrayWithObjects:NSURLVolumeNameKey, NSURLVolumeIsEjectableKey, NSURLVolumeIsBrowsableKey, nil];
    NSArray *disks = [filemanager mountedVolumeURLsIncludingResourceValuesForKeys:keys options:0];
    for (NSURL *diskk in disks) {
        //NSError *error;
        //NSNumber *isRemovable;
        //NSString *volumeName;
        //[disk getResourceValue:&isRemovable forKey:NSURLVolumeIsRemovableKey error:&error];
        //if ([isRemovable boolValue]) {
        //    [url getResourceValue:&volumeName forKey:NSURLVolumeNameKey error:&error];
        //    NSLog(@"%@", volumeName);
        //}
        NSLog(@"%@",[diskk absoluteString]);
    }
    */
}

- (IBAction)checkMounted:(id)sender {
    [self updateMounted];
    if (isMounted) {
        [statusItem setImage:iconOn];
    }else{
        [statusItem setImage:iconOff];
    }
}

- (void)updateMounted{
    NSTask *task = [[NSTask alloc] init];
    NSPipe *outputPipe = [NSPipe pipe];
    [task setLaunchPath:@"/sbin/mount"];
    [task setStandardOutput:outputPipe];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mountReadCompleted:) name:NSFileHandleReadToEndOfFileCompletionNotification object:[outputPipe fileHandleForReading]];
    [[outputPipe fileHandleForReading] readToEndOfFileInBackgroundAndNotify];
    [task launch];
    [task waitUntilExit];
    [task release];
}

- (void)readCompleted:(NSNotification *)notification {
    NSString *outStr = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
    //self.outputText.string = [self.outputText.string stringByAppendingString:[NSString stringWithFormat:@"\n%@", outStr]];
    
    for (NSString *line in [outStr componentsSeparatedByString:@"\n"]){
        if ([line length] > 1 && [[line substringToIndex:1] isEqual: @"c"]) {
            //NSLog(@"%@",[line substringFromIndex:1]);
            [self debugLog:[line substringFromIndex:1]];
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
    [outStr release];
    //NSLog(@"%@",outStr);
}

- (void)mountReadCompleted:(NSNotification *)notification {
    NSString *outStr = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
    //self.outputText.string = [self.outputText.string stringByAppendingString:[NSString stringWithFormat:@"\n%@", outStr]];
    isMounted = NO;
    for (NSString *line in [outStr componentsSeparatedByString:@"\n"]){
        if ([line length] > 1) {
            NSArray *words = [line componentsSeparatedByString:@" "];
            if([[NSString stringWithFormat:@"/dev/%@",disk.stringValue] isEqual:words[0]]){
                [mountPath setString:words[2]];
                isMounted = YES;
            }
            
        }
    }
    if (isMounted) {
        [self debugLog:[NSString stringWithFormat:@"is mounted at %@",mountPath]];
    }else{
        [self debugLog:@"not found"];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
    [outStr release];
    //NSLog(@"%@",outStr);
}

- (void)debugLog:(NSString *)string{
    self.outputText.string = [self.outputText.string stringByAppendingString:[NSString stringWithFormat:@"\n%@", string]];
    NSRange range;
    range = NSMakeRange([self.outputText.string length], 0);
    [self.outputText scrollRangeToVisible:range];
}

-(void)toggleDrive{
    [self debugLog:@"toggle"];
    if (isMounted) {
        [self debugLog:@"unmounting...."];
        [self unmount];
        [self updateMounted];
        if (isMounted) {
            [self debugLog:@"blocked by:"];
            [self lsof];
        }else{
            [self debugLog:@"unmounted"];
            [statusItem setImage:iconOff];
        }

    } else {
        [self debugLog:@"mounting...."];
        [self mount];
        [self updateMounted];
        [statusItem setImage:iconOn];
    }
}

- (IBAction)showSettings:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [settingsPanel makeKeyAndOrderFront:self];
}

- (IBAction)showDebug:(id)sender {
    [[NSApplication sharedApplication] activateIgnoringOtherApps:TRUE];
    [debugPanel makeKeyAndOrderFront:self];
}

- (void)windowWillClose:(NSNotification *)aNotification{
    [defaults setObject:disk.stringValue forKey:@"disk"];
    [defaults synchronize];
}

- (void) mount{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/diskutil"];
    [task setArguments:@[@"mount",[NSString stringWithFormat:@"/dev/%@",disk.stringValue]]];
    [task launch];
    [task waitUntilExit];
    [task release];
}

- (void) unmount{
    NSTask *task = [[NSTask alloc] init];
    [task setLaunchPath:@"/usr/sbin/diskutil"];
    [task setArguments:@[@"eject",[NSString stringWithFormat:@"/dev/%@",disk.stringValue]]];
    [task launch];
    [task waitUntilExit];
    [task release];
}

-(void)wakeUp{
    [self debugLog:@"Received wake event"];
    //[self runSystemCommand:[NSString stringWithFormat:@"diskutil eject /dev/%@",disk.stringValue]];
    //[statusItem setImage:iconOff];
}

@end