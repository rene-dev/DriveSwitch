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
    #ifndef DEBUG
    [debugMenuItem setHidden:YES];
    #endif
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
    if([event modifierFlags] & NSAlternateKeyMask) {//alt click
        [statusItem popUpStatusItemMenu:statusMenu];
    } else {
        [self toggleDrive];
    }
}

-(void)lsof{//list open files
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

- (void)readCompleted:(NSNotification *)notification {//parse lsof output
    NSString *outStr = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
    NSMutableString *apps = [[NSMutableString alloc]initWithString:@"The disk couldn't be unmounted\n because it is in use by\n"];
    
    for (NSString *line in [outStr componentsSeparatedByString:@"\n"]){
        if ([line length] > 1 && [[line substringToIndex:1] isEqual: @"c"]) {
            [apps appendFormat:@"%@ ",[line substringFromIndex:1]];
            [self debugLog:[line substringFromIndex:1]];
        }
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSFileHandleReadToEndOfFileCompletionNotification object:[notification object]];
    [outStr release];
    
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:apps];
    [alert setInformativeText:@"Quit that application and try to unmount the disk again."];
    [alert addButtonWithTitle:@"Ok"];
    [alert runModal];
    [apps release];
    [alert release];
}

- (void)mountReadCompleted:(NSNotification *)notification {//parse mount output
    NSString *outStr = [[NSString alloc] initWithData:[[notification userInfo] objectForKey:NSFileHandleNotificationDataItem] encoding:NSUTF8StringEncoding];
    isMounted = NO;
    for (NSString *line in [outStr componentsSeparatedByString:@"\n"]){
        if ([line length] > 1) {
            NSArray *words = [line componentsSeparatedByString:@" "];
            if([[NSString stringWithFormat:@"/dev/%@",disk.stringValue] isEqual:[words objectAtIndex:0]]){
                [mountPath setString:[words objectAtIndex:2]];
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
}

- (void)debugLog:(NSString *)string{
    #ifdef DEBUG
    self.outputText.string = [self.outputText.string stringByAppendingString:[NSString stringWithFormat:@"\n%@", string]];
    NSRange range;
    range = NSMakeRange([self.outputText.string length], 0);
    [self.outputText scrollRangeToVisible:range];
    #endif
}

-(void)toggleDrive{
    [self debugLog:@"toggle"];
    if (isMounted) {
        [self debugLog:@"unmounting...."];
        [self unmount];
        [self updateMounted];
        if (isMounted) {//if unmount failed
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
    if(isMounted == NO){
        [self unmount];
        [statusItem setImage:iconOff];
    }
}

@end
