// EditorView.h
// Cocoa-based View for the XP-style Notepad window.
//
// Responsible only for building and updating the UI: window, text area,
// status bar, and view-level toggles like word wrap and font.

#import <Cocoa/Cocoa.h>

@interface EditorView : NSObject

@property (nonatomic, readonly) NSWindow *window;
@property (nonatomic, readonly) NSTextView *textView;
@property (nonatomic, assign) BOOL statusBarVisible;
@property (nonatomic, assign) BOOL wordWrapEnabled;

// Builds the window, text view, and status bar.
- (instancetype)init;

// Delegates text change notifications to the given object.
- (void)attachTextDelegate:(id<NSTextViewDelegate>)delegate;

// Updates the right side of the status bar.
- (void)updateStatusWithLine:(NSInteger)line column:(NSInteger)column length:(NSUInteger)length;

// Sets window title and dirty indicator.
- (void)setDocumentTitle:(NSString *)title dirty:(BOOL)isDirty;

// Text setters/getters.
- (void)setText:(NSString *)text;
- (NSString *)text;

// Font setter for the editor body.
- (void)setEditorFont:(NSFont *)font;

// Resizes layout when status bar toggles.
- (void)setStatusBarVisible:(BOOL)visible;

// Toggles word wrap behavior on the text view and scroll view.
- (void)setWordWrapEnabled:(BOOL)enabled;

@end
