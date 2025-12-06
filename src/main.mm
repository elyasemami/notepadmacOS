// main.mm
// Entry point for the XP-style Notepad clone.

#import <Cocoa/Cocoa.h>
#import "AppController.h"

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        AppController *controller = [[AppController alloc] init];
        [app setDelegate:controller];
        [app run];
    }
    return 0;
}
