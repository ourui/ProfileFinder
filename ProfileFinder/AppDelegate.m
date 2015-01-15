//
//  AppDelegate.m
//  ProfileFinder
//
//  Created by wangrui on 15-1-15.
//  Copyright (c) 2015年 wangrui. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()<NSWindowDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSTableView *mainTable;
@property (nonatomic,strong)NSMutableArray *profiles;
@property (nonatomic,strong)NSTask *task;
@property (nonatomic,copy)NSString *writePath;
@property (nonatomic,strong)NSMutableArray *fileNames;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    
    self.profiles = [NSMutableArray array];
    self.fileNames = [NSMutableArray array];
    
    NSFileManager *manger = [NSFileManager defaultManager];
    
    NSURL *library = [[manger URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *provisonURL = [library URLByAppendingPathComponent:@"MobileDevice/Provisioning Profiles"];
    
    self.writePath = provisonURL.path;
    
    NSDirectoryEnumerator *fileEnumerator = [manger enumeratorAtPath:provisonURL.path];
    
    for (NSString *fileName in fileEnumerator) {
        
        if (![[fileEnumerator.fileAttributes objectForKey:NSFileExtensionHidden] boolValue] ) {
            
            [self.fileNames addObject:fileName];
            
            self.task = [[NSTask alloc] init];
            [self.task setLaunchPath:@"/usr/bin/security"];
            
            NSArray *arguments = @[@"cms",@"-D",@"-i",[provisonURL.path stringByAppendingPathComponent:fileName]];
            [self.task setArguments:arguments];
            
            NSPipe *pipe=[NSPipe pipe];
            [self.task setStandardOutput:pipe];
            [self.task setStandardError:pipe];
            NSFileHandle *handle=[pipe fileHandleForReading];
            [self.task launch];
            
            [self waitTask:handle];
        }
    }
    
    [self.mainTable setDoubleAction:@selector(doubleClickAtIndex:)];
    [self.mainTable reloadData];
}

- (void)waitTask:(NSFileHandle *)hanler {
        
    NSString *reslut = [[NSString alloc] initWithData:[hanler readDataToEndOfFile] encoding:NSASCIIStringEncoding];
    
    NSString *path = [self.writePath stringByAppendingString:@"tempdata"];
    [reslut writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
        
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:path];
    
    if (dict) {
        [self.profiles addObject:dict];
    }
    
    [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
                          
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}


- (void)showInfinderWithName:(NSString *)fileName {
    NSFileManager *manger = [NSFileManager defaultManager];
    
    NSURL *library = [[manger URLsForDirectory:NSLibraryDirectory inDomains:NSUserDomainMask] lastObject];
    NSURL *provisonURL = [library URLByAppendingPathComponent:@"MobileDevice/Provisioning Profiles"];
    provisonURL = [provisonURL URLByAppendingPathComponent:fileName];
    
    NSArray *fileURLs = [NSArray arrayWithObjects:provisonURL,nil];
    [[NSWorkspace sharedWorkspace] activateFileViewerSelectingURLs:fileURLs];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.profiles.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    NSTextField *textfield = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, tableColumn.width, 20)];
    textfield.backgroundColor= [NSColor clearColor];
    [textfield setBezeled:YES];
    [textfield setBordered:NO];
    
    NSDictionary *info = self.profiles[row];
    NSString *key = [tableView.tableColumns indexOfObject:tableColumn] == 0? @"Name":@"UUID";
    
    [textfield setStringValue:info[key]];
    
    return textfield;
}

- (void)doubleClickAtIndex:(id)sender {
     NSInteger row = [sender clickedRow];
    
    [self showInfinderWithName:self.fileNames[row]];
}


#pragma mark - Window
- (void)windowWillClose:(NSNotification *)notification {
    exit(0);
}

- (BOOL)windowShouldZoom:(NSWindow *)window toFrame:(NSRect)newFrame {
    return NO;
}

- (NSSize)windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize {    
    NSSize max = CGSizeMake(530, 400);
    NSSize min = CGSizeMake(300, 200);
    
    NSSize ret = frameSize;
    if (frameSize.width > max.width) {
        ret.width = max.width;
    }
    
    if (frameSize.height > max.height) {
        ret.height = max.height;
    }
    
    if (frameSize.width < min.width) {
        ret.width = min.width;
    }
    
    if (frameSize.height < min.height) {
        ret.height = min.height;
    }

    return ret;
}



@end
