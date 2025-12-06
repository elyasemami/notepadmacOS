// AppController.h
// Controller for the XP-style Notepad clone.
//
// Bridges user actions from the Cocoa UI to the C++ model while
// orchestrating menu commands, prompts, and status updates.

#import <Cocoa/Cocoa.h>

class DocumentModel;
@class EditorView;
@class MenuBuilder;

@interface AppController : NSObject <NSApplicationDelegate, NSTextViewDelegate>

- (instancetype)init;

// Document commands.
- (IBAction)newDocument:(id)sender;
- (IBAction)openDocument:(id)sender;
- (IBAction)saveDocument:(id)sender;
- (IBAction)saveDocumentAs:(id)sender;
- (IBAction)printDocument:(id)sender;
- (IBAction)showPageSetup:(id)sender;

// Edit commands.
- (IBAction)insertTimeDate:(id)sender;
- (IBAction)goToLine:(id)sender;
- (IBAction)showFind:(id)sender;
- (IBAction)findNext:(id)sender;

// View/format commands.
- (IBAction)toggleWordWrap:(id)sender;
- (IBAction)toggleStatusBar:(id)sender;
- (IBAction)showFontPanel:(id)sender;

// Help commands.
- (IBAction)showAbout:(id)sender;

@end
