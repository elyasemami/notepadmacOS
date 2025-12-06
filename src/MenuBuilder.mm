// MenuBuilder.mm
// Menu construction for the XP-style Notepad clone.

#import "MenuBuilder.h"

@interface MenuBuilder ()
@property (nonatomic, strong) NSMenuItem *wordWrapItem;
@property (nonatomic, strong) NSMenuItem *statusBarItem;
@end

@implementation MenuBuilder

- (NSMenu *)buildMainMenuWithTarget:(id)target {
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@""];

    // Application menu (About, Quit).
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"Notepad"];
    NSMenuItem *appMenuItem = [[NSMenuItem alloc] init];
    [appMenuItem setSubmenu:appMenu];

    [appMenu addItem:[self menuItem:@"About Notepad" action:@selector(showAbout:) key:@""]];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItem:[self menuItem:@"Hide Notepad" action:@selector(hide:) key:@"h"]];
    [appMenu addItem:[self menuItem:@"Hide Others" action:@selector(hideOtherApplications:) key:@"H"]];
    [appMenu addItem:[self menuItem:@"Show All" action:@selector(unhideAllApplications:) key:@""]];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItem:[self menuItem:@"Quit Notepad" action:@selector(terminate:) key:@"q"]];
    [mainMenu addItem:appMenuItem];

    // File menu.
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"File"];
    NSMenuItem *fileItem = [[NSMenuItem alloc] init];
    [fileItem setSubmenu:fileMenu];
    [fileMenu addItem:[self menuItem:@"New" action:@selector(newDocument:) key:@"n" target:target]];
    [fileMenu addItem:[self menuItem:@"Open..." action:@selector(openDocument:) key:@"o" target:target]];
    [fileMenu addItem:[self menuItem:@"Save" action:@selector(saveDocument:) key:@"s" target:target]];
    [fileMenu addItem:[self menuItem:@"Save As..." action:@selector(saveDocumentAs:) key:@"S" target:target]];
    [fileMenu addItem:[NSMenuItem separatorItem]];
    [fileMenu addItem:[self menuItem:@"Page Setup..." action:@selector(showPageSetup:) key:@"P" target:target]];
    [fileMenu addItem:[self menuItem:@"Print..." action:@selector(printDocument:) key:@"p" target:target]];
    [mainMenu addItem:fileItem];

    // Edit menu.
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"Edit"];
    NSMenuItem *editItem = [[NSMenuItem alloc] init];
    [editItem setSubmenu:editMenu];

    [editMenu addItem:[self menuItem:@"Undo" action:@selector(undo:) key:@"z"]];
    [editMenu addItem:[self menuItem:@"Redo" action:@selector(redo:) key:@"Z"]];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItem:[self menuItem:@"Cut" action:@selector(cut:) key:@"x"]];
    [editMenu addItem:[self menuItem:@"Copy" action:@selector(copy:) key:@"c"]];
    [editMenu addItem:[self menuItem:@"Paste" action:@selector(paste:) key:@"v"]];
    [editMenu addItem:[self menuItem:@"Delete" action:@selector(deleteForward:) key:@"\u0008"]];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItem:[self menuItem:@"Find..." action:@selector(showFind:) key:@"f" target:target]];
    [editMenu addItem:[self menuItem:@"Find Next" action:@selector(findNext:) key:@"g" target:target]];
    [editMenu addItem:[self menuItem:@"Go To..." action:@selector(goToLine:) key:@"l" target:target]];
    [editMenu addItem:[NSMenuItem separatorItem]];
    [editMenu addItem:[self menuItem:@"Select All" action:@selector(selectAll:) key:@"a"]];
    [editMenu addItem:[self menuItem:@"Time/Date" action:@selector(insertTimeDate:) key:@"d" target:target]];
    [mainMenu addItem:editItem];

    // Format menu.
    NSMenu *formatMenu = [[NSMenu alloc] initWithTitle:@"Format"];
    NSMenuItem *formatItem = [[NSMenuItem alloc] init];
    [formatItem setSubmenu:formatMenu];

    self.wordWrapItem = [self menuItem:@"Word Wrap" action:@selector(toggleWordWrap:) key:@"" target:target];
    [formatMenu addItem:self.wordWrapItem];
    [formatMenu addItem:[self menuItem:@"Font..." action:@selector(showFontPanel:) key:@"" target:target]];
    [mainMenu addItem:formatItem];

    // View menu.
    NSMenu *viewMenu = [[NSMenu alloc] initWithTitle:@"View"];
    NSMenuItem *viewItem = [[NSMenuItem alloc] init];
    [viewItem setSubmenu:viewMenu];
    self.statusBarItem = [self menuItem:@"Status Bar" action:@selector(toggleStatusBar:) key:@"" target:target];
    [viewMenu addItem:self.statusBarItem];
    [mainMenu addItem:viewItem];

    // Help menu.
    NSMenu *helpMenu = [[NSMenu alloc] initWithTitle:@"Help"];
    NSMenuItem *helpItem = [[NSMenuItem alloc] init];
    [helpItem setSubmenu:helpMenu];
    [helpMenu addItem:[self menuItem:@"About Notepad" action:@selector(showAbout:) key:@"" target:target]];
    [mainMenu addItem:helpItem];

    return mainMenu;
}

- (NSMenuItem *)menuItem:(NSString *)title action:(SEL)action key:(NSString *)key {
    return [self menuItem:title action:action key:key target:nil];
}

- (NSMenuItem *)menuItem:(NSString *)title action:(SEL)action key:(NSString *)key target:(id)target {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = target;
    return item;
}

- (void)setWordWrapChecked:(BOOL)checked {
    [self.wordWrapItem setState:checked ? NSControlStateValueOn : NSControlStateValueOff];
}

- (void)setStatusBarChecked:(BOOL)checked {
    [self.statusBarItem setState:checked ? NSControlStateValueOn : NSControlStateValueOff];
}

@end
