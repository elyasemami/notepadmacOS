// AppController.mm
// Controller implementation for the XP-style Notepad clone.

#import "AppController.h"

#import "DocumentModel.h"
#import "EditorView.h"
#import "MenuBuilder.h"

#include <memory>
#include <string>

static NSString *const kUntitledName = @"Untitled";

@interface AppController () {
    std::unique_ptr<DocumentModel> model_;
}
@property (nonatomic, strong) EditorView *editorView;
@property (nonatomic, strong) MenuBuilder *menuBuilder;
@property (nonatomic, strong) NSDateFormatter *timeFormatter;
@property (nonatomic, copy) NSString *lastFindString;
@property (nonatomic, assign) BOOL suppressDirtyFlag;
@property (nonatomic, assign) BOOL wordWrapEnabled;
@property (nonatomic, assign) BOOL statusBarVisible;
@end

@implementation AppController

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }
    model_ = std::make_unique<DocumentModel>();
    _editorView = [[EditorView alloc] init];
    _menuBuilder = [[MenuBuilder alloc] init];
    _timeFormatter = [[NSDateFormatter alloc] init];
    [_timeFormatter setDateFormat:@"HH:mm MM/dd/yyyy"];
    _wordWrapEnabled = YES;
    _statusBarVisible = YES;
    _suppressDirtyFlag = NO;
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    [NSApp setMainMenu:[self.menuBuilder buildMainMenuWithTarget:self]];
    [self.menuBuilder setWordWrapChecked:YES];
    [self.menuBuilder setStatusBarChecked:YES];

    // Ensure the app is frontmost and ready for keyboard events when launched from CLI.
    [NSApp setActivationPolicy:NSApplicationActivationPolicyRegular];
    [NSApp activateIgnoringOtherApps:YES];

    [self.editorView attachTextDelegate:self];
    [self.editorView.window center];
    [self.editorView.window makeKeyAndOrderFront:nil];
    [self.editorView.window makeFirstResponder:self.editorView.textView];
    [self updateStatusFromSelection];
}

- (NSApplicationTerminateReply)applicationShouldTerminate:(NSApplication *)sender {
    if ([self promptToSaveIfNeeded]) {
        return NSTerminateNow;
    }
    return NSTerminateCancel;
}

#pragma mark - File commands

- (IBAction)newDocument:(id)sender {
    if (![self promptToSaveIfNeeded]) {
        return;
    }
    self.suppressDirtyFlag = YES;
    [self.editorView setText:@""];
    self.suppressDirtyFlag = NO;
    model_->setText("");
    model_->setFilePath("");
    model_->markClean();
    [self updateWindowTitle];
    [self updateStatusFromSelection];
}

- (IBAction)openDocument:(id)sender {
    if (![self promptToSaveIfNeeded]) {
        return;
    }

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    if ([panel runModal] != NSModalResponseOK) {
        return;
    }

    NSURL *url = panel.URL;
    std::string error;
    if (!model_->loadFromFile(url.path.UTF8String, error)) {
        [self showError:[NSString stringWithUTF8String:error.c_str()]];
        return;
    }

    NSString *text = [[NSString alloc] initWithBytes:model_->text().data()
                                              length:model_->text().size()
                                            encoding:NSUTF8StringEncoding];
    if (!text) {
        text = [[NSString alloc] initWithBytes:model_->text().data()
                                        length:model_->text().size()
                                      encoding:NSISOLatin1StringEncoding];
    }

    self.suppressDirtyFlag = YES;
    [self.editorView setText:text ?: @""];
    self.suppressDirtyFlag = NO;
    model_->markClean();
    [self updateWindowTitle];
    [self updateStatusFromSelection];
}

- (IBAction)saveDocument:(id)sender {
    [self syncModelFromView];
    if (!model_->hasFilePath()) {
        [self saveDocumentAs:sender];
        return;
    }
    std::string error;
    if (!model_->save(error)) {
        [self showError:[NSString stringWithUTF8String:error.c_str()]];
        return;
    }
    [self updateWindowTitle];
}

- (IBAction)saveDocumentAs:(id)sender {
    [self syncModelFromView];
    NSSavePanel *panel = [NSSavePanel savePanel];
    if ([panel runModal] != NSModalResponseOK) {
        return;
    }
    NSURL *url = panel.URL;
    std::string error;
    if (!model_->saveAs(url.path.UTF8String, error)) {
        [self showError:[NSString stringWithUTF8String:error.c_str()]];
        return;
    }
    [self updateWindowTitle];
}

- (IBAction)showPageSetup:(id)sender {
    [[NSPageLayout pageLayout] runModal];
}

- (IBAction)printDocument:(id)sender {
    NSPrintOperation *op = [NSPrintOperation printOperationWithView:self.editorView.textView];
    [op runOperationModalForWindow:self.editorView.window delegate:nil didRunSelector:NULL contextInfo:NULL];
}

#pragma mark - Edit commands

- (IBAction)insertTimeDate:(id)sender {
    NSString *stamp = [self.timeFormatter stringFromDate:[NSDate date]];
    NSTextView *tv = self.editorView.textView;
    [tv insertText:stamp replacementRange:tv.selectedRange];
    [self markDirty];
}

- (IBAction)goToLine:(id)sender {
    if (self.wordWrapEnabled) {
        [self showError:@"Go To is disabled when Word Wrap is on. Turn off Word Wrap first."];
        return;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Go To Line";
    alert.informativeText = @"Enter a line number:";

    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [field setStringValue:@"1"];
    alert.accessoryView = field;

    NSInteger response = [alert runModal];
    if (response != NSAlertFirstButtonReturn) {
        return;
    }

    NSInteger targetLine = field.integerValue;
    if (targetLine <= 0) {
        NSBeep();
        return;
    }

    NSString *text = [self.editorView text];
    NSArray<NSString *> *lines = [text componentsSeparatedByString:@"\n"];
    if (targetLine > (NSInteger)[lines count]) {
        [self showError:@"Line number is out of range."];
        return;
    }

    NSUInteger offset = 0;
    for (NSInteger i = 0; i < targetLine - 1; ++i) {
        offset += [lines[i] length] + 1; // newline
    }

    NSRange range = NSMakeRange(offset, 0);
    [self.editorView.textView setSelectedRange:range];
    [self.editorView.textView scrollRangeToVisible:range];
    [self updateStatusFromSelection];
}

- (IBAction)showFind:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Find";
    alert.informativeText = @"Enter text to find:";
    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 220, 24)];
    if (self.lastFindString.length > 0) {
        field.stringValue = self.lastFindString;
    }
    alert.accessoryView = field;
    [alert addButtonWithTitle:@"Find Next"];
    [alert addButtonWithTitle:@"Cancel"];

    NSInteger response = [alert runModal];
    if (response != NSAlertFirstButtonReturn) {
        return;
    }

    self.lastFindString = field.stringValue;
    if (![self performFindNext]) {
        [self showError:@"Text not found."];
    }
}

- (IBAction)findNext:(id)sender {
    if (self.lastFindString.length == 0) {
        [self showFind:sender];
        return;
    }
    if (![self performFindNext]) {
        [self showError:@"Text not found."];
    }
}

#pragma mark - Format/View commands

- (IBAction)toggleWordWrap:(id)sender {
    self.wordWrapEnabled = !self.wordWrapEnabled;
    [self.editorView setWordWrapEnabled:self.wordWrapEnabled];
    [self.menuBuilder setWordWrapChecked:self.wordWrapEnabled];
}

- (IBAction)toggleStatusBar:(id)sender {
    self.statusBarVisible = !self.statusBarVisible;
    [self.editorView setStatusBarVisible:self.statusBarVisible];
    [self.menuBuilder setStatusBarChecked:self.statusBarVisible];
}

- (IBAction)showFontPanel:(id)sender {
    [[NSFontManager sharedFontManager] orderFrontFontPanel:self];
    [[NSFontManager sharedFontManager] setTarget:self];
}

- (void)changeFont:(id)sender {
    NSFontManager *manager = [NSFontManager sharedFontManager];
    NSFont *newFont = [manager convertFont:self.editorView.textView.font];
    [self.editorView setEditorFont:newFont];
}

#pragma mark - Help commands

- (IBAction)showAbout:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Notepad for macOS";
    alert.informativeText = @"Windows XP-style Notepad rebuilt in C++/Cocoa.\nFeatures: word wrap, status bar, find, go to line, time/date, print.";
    [alert runModal];
}

#pragma mark - Delegate helpers

- (void)textDidChange:(NSNotification *)notification {
    [self markDirty];
    [self updateStatusFromSelection];
}

- (void)textViewDidChangeSelection:(NSNotification *)notification {
    [self updateStatusFromSelection];
}

- (BOOL)promptToSaveIfNeeded {
    if (!model_->isDirty()) {
        return YES;
    }

    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"Do you want to save changes?";
    alert.informativeText = @"Your changes will be lost if you don't save them.";
    [alert addButtonWithTitle:@"Save"];
    [alert addButtonWithTitle:@"Don't Save"];
    [alert addButtonWithTitle:@"Cancel"];

    NSInteger response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) { // Save
        [self saveDocument:nil];
        return !model_->isDirty();
    } else if (response == NSAlertSecondButtonReturn) { // Don't Save
        return YES;
    }
    return NO;
}

- (void)markDirty {
    if (self.suppressDirtyFlag) {
        return;
    }
    std::string text = [self.editorView.text UTF8String] ? [self.editorView.text UTF8String] : "";
    model_->setText(text);
    [self updateWindowTitle];
}

- (void)syncModelFromView {
    std::string text = [self.editorView.text UTF8String] ? [self.editorView.text UTF8String] : "";
    model_->setText(text);
}

- (void)updateWindowTitle {
    NSString *name = model_->hasFilePath() ? [NSString stringWithUTF8String:model_->filePath().c_str()] : kUntitledName;
    [self.editorView setDocumentTitle:[name lastPathComponent] dirty:model_->isDirty()];
}

- (void)updateStatusFromSelection {
    NSTextView *tv = self.editorView.textView;
    NSString *string = tv.string ?: @"";
    NSRange selection = tv.selectedRange;
    NSUInteger location = MIN(selection.location, string.length);
    NSUInteger line = 1;
    NSUInteger column = 1;

    NSUInteger idx = 0;
    while (idx < location) {
        NSRange r = [string rangeOfString:@"\n" options:0 range:NSMakeRange(idx, location - idx)];
        if (r.location == NSNotFound) {
            break;
        }
        line += 1;
        idx = r.location + 1;
    }
    column = location - idx + 1;

    [self.editorView updateStatusWithLine:(NSInteger)line column:(NSInteger)column length:string.length];
}

- (void)showError:(NSString *)message {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = message ?: @"An error occurred.";
    [alert runModal];
}

- (BOOL)performFindNext {
    if (self.lastFindString.length == 0) {
        return NO;
    }

    NSTextView *tv = self.editorView.textView;
    NSString *haystack = tv.string ?: @"";
    NSString *needle = self.lastFindString;

    NSRange selection = tv.selectedRange;
    NSUInteger start = selection.location + selection.length;
    if (start > haystack.length) {
        start = 0;
    }
    NSRange searchRange = NSMakeRange(start, haystack.length - start);
    NSRange found = [haystack rangeOfString:needle options:NSCaseInsensitiveSearch range:searchRange];
    if (found.location == NSNotFound) {
        found = [haystack rangeOfString:needle options:NSCaseInsensitiveSearch range:NSMakeRange(0, start)];
    }
    if (found.location == NSNotFound) {
        return NO;
    }
    [tv setSelectedRange:found];
    [tv scrollRangeToVisible:found];
    [self updateStatusFromSelection];
    return YES;
}

@end
