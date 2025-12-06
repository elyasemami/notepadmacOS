// EditorView.mm
// Cocoa View implementation for the XP-style Notepad UI.

#import "EditorView.h"

@interface EditorView ()
@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) NSView *statusBar;
@property (nonatomic, strong) NSTextField *statusLeftLabel;
@property (nonatomic, strong) NSTextField *statusRightLabel;
@property (nonatomic, strong) NSLayoutConstraint *statusBarHeightConstraint;
@end

@implementation EditorView

- (instancetype)init {
    self = [super init];
    if (!self) {
        return nil;
    }

    NSRect frame = NSMakeRect(0, 0, 900, 650);
    _window = [[NSWindow alloc] initWithContentRect:frame
                                          styleMask:(NSWindowStyleMaskTitled |
                                                     NSWindowStyleMaskClosable |
                                                     NSWindowStyleMaskResizable |
                                                     NSWindowStyleMaskMiniaturizable)
                                            backing:NSBackingStoreBuffered
                                              defer:NO];
    [_window setTitle:@"Untitled - Notepad"];

    NSView *content = [[NSView alloc] initWithFrame:frame];
    _window.contentView = content;

    _scrollView = [[NSScrollView alloc] initWithFrame:content.bounds];
    _scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    _scrollView.hasVerticalScroller = YES;
    _scrollView.hasHorizontalScroller = NO;
    _scrollView.borderType = NSBezelBorder;

    _textView = [[NSTextView alloc] initWithFrame:content.bounds];
    _textView.translatesAutoresizingMaskIntoConstraints = YES;
    _textView.minSize = NSMakeSize(0.0, content.bounds.size.height);
    _textView.maxSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    _textView.verticallyResizable = YES;
    _textView.horizontallyResizable = NO;
    _textView.autoresizingMask = NSViewWidthSizable;
    _textView.richText = NO;
    _textView.usesFontPanel = NO;
    _textView.automaticQuoteSubstitutionEnabled = NO;
    _textView.automaticDashSubstitutionEnabled = NO;
    _textView.automaticDataDetectionEnabled = NO;
    _textView.automaticTextReplacementEnabled = NO;
    _textView.automaticSpellingCorrectionEnabled = NO;
    _textView.textContainerInset = NSMakeSize(8, 8);
    [_textView setUsesRuler:NO];
    [_textView setAllowsUndo:YES];

    NSFont *defaultFont = [NSFont fontWithName:@"Menlo" size:14.0];
    if (!defaultFont) {
        defaultFont = [NSFont userFixedPitchFontOfSize:13.0];
    }
    [_textView setFont:defaultFont];

    _scrollView.documentView = _textView;
    [content addSubview:_scrollView];

    _statusBar = [[NSView alloc] init];
    _statusBar.translatesAutoresizingMaskIntoConstraints = NO;
    _statusBar.wantsLayer = YES;
    _statusBar.layer.backgroundColor = [[NSColor windowBackgroundColor] CGColor];

    _statusLeftLabel = [self createStatusLabel:@"Windows XP Notepad (macOS)"];
    _statusRightLabel = [self createStatusLabel:@"Ln 1, Col 1"];

    [_statusBar addSubview:_statusLeftLabel];
    [_statusBar addSubview:_statusRightLabel];
    [content addSubview:_statusBar];

    [self setupConstraintsForContent:content];

    _statusBarVisible = YES;
    _wordWrapEnabled = YES;
    [self setWordWrapEnabled:YES];
    [self setStatusBarVisible:YES];

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(windowDidResize:)
                                                 name:NSWindowDidResizeNotification
                                               object:_window];

    return self;
}

- (NSTextField *)createStatusLabel:(NSString *)text {
    NSTextField *label = [[NSTextField alloc] init];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    label.editable = NO;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.font = [NSFont systemFontOfSize:12.0];
    label.alignment = NSTextAlignmentLeft;
    label.stringValue = text;
    return label;
}

- (void)setupConstraintsForContent:(NSView *)content {
    NSView *scroll = self.scrollView;
    NSView *status = self.statusBar;
    NSDictionary *views = NSDictionaryOfVariableBindings(scroll, status);

    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[scroll]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views]];
    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-8-[status]-8-|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views]];
    [content addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[scroll][status]|"
                                                                    options:0
                                                                    metrics:nil
                                                                      views:views]];

    self.statusBarHeightConstraint = [NSLayoutConstraint constraintWithItem:status
                                                                   attribute:NSLayoutAttributeHeight
                                                                   relatedBy:NSLayoutRelationEqual
                                                                      toItem:nil
                                                                   attribute:NSLayoutAttributeNotAnAttribute
                                                                  multiplier:1.0
                                                                    constant:24.0];
    [status addConstraint:self.statusBarHeightConstraint];

    // Layout for status labels.
    [self.statusLeftLabel.leadingAnchor constraintEqualToAnchor:status.leadingAnchor constant:6.0].active = YES;
    [self.statusLeftLabel.centerYAnchor constraintEqualToAnchor:status.centerYAnchor].active = YES;

    [self.statusRightLabel.trailingAnchor constraintEqualToAnchor:status.trailingAnchor constant:-6.0].active = YES;
    [self.statusRightLabel.centerYAnchor constraintEqualToAnchor:status.centerYAnchor].active = YES;
}

- (void)attachTextDelegate:(id<NSTextViewDelegate>)delegate {
    self.textView.delegate = delegate;
}

- (void)setDocumentTitle:(NSString *)title dirty:(BOOL)isDirty {
    NSString *display = title.length > 0 ? title : @"Untitled";
    NSString *full = [NSString stringWithFormat:@"%@%@ - Notepad", (isDirty ? @"*" : @""), display];
    [self.window setTitle:full];
}

- (void)updateStatusWithLine:(NSInteger)line column:(NSInteger)column length:(NSUInteger)length {
    NSString *right = [NSString stringWithFormat:@"Ln %ld, Col %ld    Length: %lu",
                       (long)line, (long)column, (unsigned long)length];
    self.statusRightLabel.stringValue = right;
}

- (void)setText:(NSString *)text {
    if (!text) {
        text = @"";
    }
    [self.textView setString:text];
}

- (NSString *)text {
    return [self.textView string] ?: @"";
}

- (void)setEditorFont:(NSFont *)font {
    if (!font) {
        return;
    }
    [self.textView setFont:font];
}

- (void)setStatusBarVisible:(BOOL)visible {
    _statusBarVisible = visible;
    self.statusBar.hidden = !visible;
    self.statusBarHeightConstraint.constant = visible ? 24.0 : 0.0;
}

- (void)setWordWrapEnabled:(BOOL)enabled {
    _wordWrapEnabled = enabled;
    NSTextView *tv = self.textView;
    NSScrollView *scroll = self.scrollView;
    tv.horizontallyResizable = !enabled;
    tv.textContainer.widthTracksTextView = enabled;
    scroll.hasHorizontalScroller = !enabled;
    if (enabled) {
        tv.textContainer.containerSize = NSMakeSize(scroll.contentSize.width, CGFLOAT_MAX);
    } else {
        tv.textContainer.containerSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    }
}

- (void)windowDidResize:(NSNotification *)notification {
    if (self.wordWrapEnabled) {
        NSTextView *tv = self.textView;
        NSScrollView *scroll = self.scrollView;
        tv.textContainer.containerSize = NSMakeSize(scroll.contentSize.width, CGFLOAT_MAX);
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
