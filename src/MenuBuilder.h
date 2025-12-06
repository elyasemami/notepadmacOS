// MenuBuilder.h
// Builds the menu bar for the XP-style Notepad clone.
//
// Keeps menu construction separate from the controller to keep files small.

#import <Cocoa/Cocoa.h>

@interface MenuBuilder : NSObject

// Produces and returns the main menu configured with Notepad-like sections.
- (NSMenu *)buildMainMenuWithTarget:(id)target;

// Toggles checkmarks on format/view items.
- (void)setWordWrapChecked:(BOOL)checked;
- (void)setStatusBarChecked:(BOOL)checked;

@end
