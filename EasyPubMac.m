#import <Cocoa/Cocoa.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <QuartzCore/QuartzCore.h>

// MARK: - Color Constants (icon-inspired sage theme)

static NSColor *AccentAmber(void) {
    return [NSColor colorWithRed:0.43 green:0.50 blue:0.36 alpha:1.0];
}
static NSColor *AccentAmberLight(void) {
    return [NSColor colorWithRed:0.78 green:0.68 blue:0.43 alpha:1.0];
}
static NSColor *AccentAmberDark(void) {
    return [NSColor colorWithRed:0.27 green:0.33 blue:0.22 alpha:1.0];
}
static NSColor *SubtleBorder(void) {
    return [NSColor colorWithRed:0.84 green:0.82 blue:0.77 alpha:1.0];
}
static NSColor *WindowBackground(void) {
    return [NSColor colorWithRed:0.95 green:0.93 blue:0.88 alpha:1.0];
}
static NSColor *WarmGrayText(void) {
    return [NSColor colorWithRed:0.45 green:0.44 blue:0.38 alpha:1.0];
}
static NSColor *HeroDarkStart(void) {
    return [NSColor colorWithRed:0.18 green:0.23 blue:0.16 alpha:1.0];
}
static NSColor *HeroDarkEnd(void) {
    return [NSColor colorWithRed:0.36 green:0.43 blue:0.30 alpha:1.0];
}
static NSFont *AppSerifFont(CGFloat size) {
    return [NSFont fontWithName:@"Songti SC" size:size]
        ?: [NSFont fontWithName:@"STSong" size:size]
        ?: [NSFont fontWithName:@"Times New Roman" size:size]
        ?: [NSFont systemFontOfSize:size];
}
static NSFont *AppSerifBoldFont(CGFloat size) {
    NSFont *font = AppSerifFont(size);
    NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
    return boldFont ?: [NSFont boldSystemFontOfSize:size];
}

// MARK: - TxtDropView (TXT drag-and-drop)

@interface TxtDropView : NSView <NSDraggingDestination>
@property (nonatomic, copy) void (^onDrop)(NSString *filePath);
@property (nonatomic, strong) NSTextField *fileLabel;
@property (nonatomic, strong) NSTextField *hintLabel;
@end

@implementation TxtDropView {
    BOOL _draggingHighlight;
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.wantsLayer = YES;
        self.layer.cornerRadius = 10.0;
        self.layer.shadowColor = [[NSColor colorWithWhite:0.0 alpha:0.06] CGColor];
        self.layer.shadowOffset = NSMakeSize(0, 2);
        self.layer.shadowRadius = 6.0;
        self.layer.shadowOpacity = 1.0;
        self.layer.borderWidth = 1.0;
        self.layer.borderColor = [SubtleBorder() CGColor];
        self.layer.backgroundColor = [NSColor.whiteColor CGColor];
        [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];

        NSTextField *hint = [self hintLabel];
        [self addSubview:hint];
        self.hintLabel = hint;

        NSTextField *label = [self fileLabel];
        [self addSubview:label];
        self.fileLabel = label;
    }
    return self;
}

- (NSTextField *)hintLabel {
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(16, 38, self.bounds.size.width - 32, 18)];
    label.stringValue = @"当前文件";
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    label.textColor = [NSColor secondaryLabelColor];
    label.font = AppSerifFont(11);
    label.autoresizingMask = NSViewWidthSizable;
    return label;
}

- (NSTextField *)fileLabel {
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(16, 10, self.bounds.size.width - 202, 26)];
    label.stringValue = @"拖拽 TXT 文件到此处，或点击右侧按钮";
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    label.textColor = [NSColor labelColor];
    label.font = AppSerifBoldFont(16);
    label.autoresizingMask = NSViewWidthSizable;
    return label;
}

- (void)setFileName:(NSString *)name {
    self.fileLabel.stringValue = name ?: @"拖拽 TXT 文件到此处，或点击右侧按钮";
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([self hasTxtURL:sender]) {
        _draggingHighlight = YES;
        self.layer.borderColor = [AccentAmber() CGColor];
        self.layer.borderWidth = 2.0;
        self.layer.backgroundColor = [[NSColor colorWithRed:0.99 green:0.97 blue:0.93 alpha:1.0] CGColor];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    _draggingHighlight = NO;
    self.layer.borderColor = [SubtleBorder() CGColor];
    self.layer.borderWidth = 1.0;
    self.layer.backgroundColor = [NSColor.whiteColor CGColor];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSString *path = [self txtPathFromDrag:sender];
    if (path) {
        if (self.onDrop) self.onDrop(path);
        return YES;
    }
    return NO;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    _draggingHighlight = NO;
    self.layer.borderColor = [SubtleBorder() CGColor];
    self.layer.borderWidth = 1.0;
    self.layer.backgroundColor = [NSColor.whiteColor CGColor];
}

- (BOOL)hasTxtURL:(id<NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls = [sender.draggingPasteboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    for (NSURL *url in urls) {
        if ([url.pathExtension.lowercaseString isEqualToString:@"txt"]) return YES;
    }
    return NO;
}

- (NSString *)txtPathFromDrag:(id<NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls = [sender.draggingPasteboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    for (NSURL *url in urls) {
        if ([url.pathExtension.lowercaseString isEqualToString:@"txt"]) return url.path;
    }
    return nil;
}

@end


// MARK: - DropZoneView (cover image drag-and-drop with preview)

@interface DropZoneView : NSView <NSDraggingDestination>
@property (nonatomic, copy) NSString *filePath;
@property (nonatomic, copy) void (^onDrop)(NSString *filePath);
@property (nonatomic, copy) void (^onClear)(void);
@end

@implementation DropZoneView {
    NSTextField *_placeholderLabel;
    NSTextField *_hintLabel;
    NSImageView *_imageView;
}

- (instancetype)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) [self setup];
    return self;
}

- (void)setup {
    self.wantsLayer = YES;
    self.layer.cornerRadius = 10.0;
    self.layer.borderWidth = 2.0;
    self.layer.borderColor = [SubtleBorder() CGColor];
    self.layer.backgroundColor = [[NSColor colorWithWhite:0.97 alpha:1.0] CGColor];
    [self registerForDraggedTypes:@[NSPasteboardTypeFileURL]];
    self.autoresizingMask = NSViewNotSizable;

    NSRect b = self.bounds;

    // Image preview (hidden when empty)
    _imageView = [[NSImageView alloc] initWithFrame:NSMakeRect(4, 4, b.size.width - 8, b.size.height - 8)];
    _imageView.imageScaling = NSImageScaleProportionallyUpOrDown;
    _imageView.imageAlignment = NSImageAlignCenter;
    _imageView.wantsLayer = YES;
    _imageView.layer.cornerRadius = 8.0;
    _imageView.layer.masksToBounds = YES;
    _imageView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    _imageView.hidden = YES;
    [self addSubview:_imageView];

    // Placeholder text
    _placeholderLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(8, b.size.height / 2 + 6, b.size.width - 16, 20)];
    _placeholderLabel.stringValue = @"拖拽封面图片到此处";
    _placeholderLabel.bezeled = NO;
    _placeholderLabel.drawsBackground = NO;
    _placeholderLabel.editable = NO;
    _placeholderLabel.selectable = NO;
    _placeholderLabel.textColor = [NSColor colorWithWhite:0.50 alpha:1.0];
    _placeholderLabel.font = AppSerifBoldFont(13);
    _placeholderLabel.alignment = NSTextAlignmentCenter;
    _placeholderLabel.autoresizingMask = NSViewWidthSizable;
    [self addSubview:_placeholderLabel];

    // Hint text
    _hintLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(8, b.size.height / 2 - 14, b.size.width - 16, 14)];
    _hintLabel.stringValue = @"JPG / PNG / GIF / WebP / SVG";
    _hintLabel.bezeled = NO;
    _hintLabel.drawsBackground = NO;
    _hintLabel.editable = NO;
    _hintLabel.selectable = NO;
    _hintLabel.textColor = [NSColor colorWithWhite:0.68 alpha:1.0];
    _hintLabel.font = AppSerifFont(10);
    _hintLabel.alignment = NSTextAlignmentCenter;
    _hintLabel.autoresizingMask = NSViewWidthSizable;
    [self addSubview:_hintLabel];

    // Click gesture for file picker
    NSClickGestureRecognizer *click = [[NSClickGestureRecognizer alloc] initWithTarget:self action:@selector(handleClick:)];
    [self addGestureRecognizer:click];
}

- (void)setFilePath:(NSString *)filePath {
    _filePath = [filePath copy];
    if (filePath) {
        NSImage *image = [[NSImage alloc] initWithContentsOfFile:filePath];
        if (image) {
            // Show image preview
            _imageView.image = image;
            _imageView.hidden = NO;
            _placeholderLabel.hidden = YES;
            _hintLabel.hidden = YES;
        } else {
            // Fallback: show filename
            _imageView.hidden = YES;
            _placeholderLabel.stringValue = filePath.lastPathComponent;
            _placeholderLabel.hidden = NO;
            _hintLabel.hidden = NO;
            _hintLabel.stringValue = @"图片无法加载，点击重新选择";
        }
        self.layer.backgroundColor = [[NSColor colorWithRed:0.99 green:0.97 blue:0.93 alpha:1.0] CGColor];
    } else {
        _imageView.image = nil;
        _imageView.hidden = YES;
        _placeholderLabel.stringValue = @"拖拽封面图片到此处";
        _placeholderLabel.hidden = NO;
        _hintLabel.stringValue = @"JPG / PNG / GIF / WebP / SVG";
        _hintLabel.hidden = NO;
        self.layer.backgroundColor = [[NSColor colorWithWhite:0.97 alpha:1.0] CGColor];
    }
}

- (void)resetAppearance {
    if (self.filePath) {
        self.layer.backgroundColor = [[NSColor colorWithRed:0.99 green:0.97 blue:0.93 alpha:1.0] CGColor];
    } else {
        self.layer.backgroundColor = [[NSColor colorWithWhite:0.97 alpha:1.0] CGColor];
    }
    self.layer.borderColor = [SubtleBorder() CGColor];
    [self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    // Only draw dashed border when no image is loaded
    if (_imageView.isHidden) {
        NSBezierPath *path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(self.bounds, 3, 3) xRadius:8 yRadius:8];
        CGFloat dashes[] = {6, 4};
        [path setLineDash:dashes count:2 phase:0];
        [[NSColor colorWithWhite:0.80 alpha:1.0] setStroke];
        [path stroke];
    }
}

- (NSDragOperation)draggingEntered:(id<NSDraggingInfo>)sender {
    if ([self hasImageURL:sender]) {
        self.layer.borderColor = [AccentAmber() CGColor];
        self.layer.backgroundColor = [[NSColor colorWithRed:0.99 green:0.97 blue:0.93 alpha:1.0] CGColor];
        [self setNeedsDisplay:YES];
        return NSDragOperationCopy;
    }
    return NSDragOperationNone;
}

- (void)draggingExited:(id<NSDraggingInfo>)sender {
    [self resetAppearance];
}

- (BOOL)performDragOperation:(id<NSDraggingInfo>)sender {
    NSString *path = [self imagePathFromDrag:sender];
    if (path) {
        self.filePath = path;
        if (self.onDrop) self.onDrop(path);
        return YES;
    }
    return NO;
}

- (void)draggingEnded:(id<NSDraggingInfo>)sender {
    [self resetAppearance];
}

- (BOOL)hasImageURL:(id<NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls = [sender.draggingPasteboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    for (NSURL *url in urls) {
        NSString *ext = url.pathExtension.lowercaseString;
        if ([@[@"jpg", @"jpeg", @"png", @"gif", @"webp", @"svg"] containsObject:ext]) return YES;
    }
    return NO;
}

- (NSString *)imagePathFromDrag:(id<NSDraggingInfo>)sender {
    NSArray<NSURL *> *urls = [sender.draggingPasteboard readObjectsForClasses:@[[NSURL class]] options:@{NSPasteboardURLReadingFileURLsOnlyKey: @YES}];
    for (NSURL *url in urls) {
        NSString *ext = url.pathExtension.lowercaseString;
        if ([@[@"jpg", @"jpeg", @"png", @"gif", @"webp", @"svg"] containsObject:ext]) return url.path;
    }
    return nil;
}

- (void)handleClick:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypeImage];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.message = @"选择一张图片作为书籍封面";
    if ([panel runModal] == NSModalResponseOK) {
        self.filePath = panel.URL.path;
        if (self.onDrop) self.onDrop(self.filePath);
    }
}

@end


// MARK: - AppDelegate

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTableViewDataSource, NSTableViewDelegate, NSTextFieldDelegate>
@property NSWindow *window;
@property NSString *selectedFilePath;
@property NSString *selectedCoverPath;
@property NSString *selectedFontPath;
@property DropZoneView *coverDropZone;
@property TxtDropView *txtDropView;
@property NSArray<NSDictionary *> *chapters;
@property NSTextField *fileValueLabel;
@property NSTextField *titleField;
@property NSTextField *authorField;
@property NSTextField *languageField;
@property NSTextField *fontSizeField;
@property NSTextField *lineHeightField;
@property NSTextField *indentField;
@property NSTextField *fontPathField;
@property NSButton *removeBlankCheckbox;
@property NSButton *justifyCheckbox;
@property NSButton *coverCheckbox;
@property NSTextField *statusLabel;
@property NSTextField *chapterCountLabel;
@property NSTextField *wordCountLabel;
@property NSProgressIndicator *progressIndicator;
@property NSButton *exportButton;
@property NSButton *refreshButton;
@property NSTableView *tableView;
@property NSTextView *previewTextView;
@property NSTextField *previewTitleLabel;
@property NSTextField *previewMetaLabel;
@property NSUInteger analysisRequestID;

// CSS Editor
@property (strong) NSPanel *cssPanel;
@property (strong) NSTextView *cssTextView;

// Chapter Preview Panel
@property (strong) NSPanel *chapterPanel;
@end

@implementation AppDelegate

- (instancetype)init {
    self = [super init];
    if (self) [self buildMenu];
    return self;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    self.chapters = @[];
    [self buildWindow];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

// MARK: - Helpers

- (NSView *)cardView:(NSRect)frame {
    NSView *view = [[NSView alloc] initWithFrame:frame];
    view.wantsLayer = YES;
    view.layer.backgroundColor = [NSColor.whiteColor CGColor];
    view.layer.cornerRadius = 10.0;
    view.layer.shadowColor = [[NSColor colorWithWhite:0.0 alpha:0.06] CGColor];
    view.layer.shadowOffset = NSMakeSize(0, 2);
    view.layer.shadowRadius = 6.0;
    view.layer.shadowOpacity = 1.0;
    view.layer.borderWidth = 1.0;
    view.layer.borderColor = [SubtleBorder() CGColor];
    return view;
}

- (NSTextField *)label:(NSString *)text frame:(NSRect)frame size:(CGFloat)size bold:(BOOL)bold color:(NSColor *)color {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    label.textColor = color;
    label.font = bold ? AppSerifBoldFont(size) : AppSerifFont(size);
    return label;
}

- (NSTextField *)wrappingLabel:(NSString *)text frame:(NSRect)frame size:(CGFloat)size bold:(BOOL)bold color:(NSColor *)color {
    NSTextField *label = [self label:text frame:frame size:size bold:bold color:color];
    label.usesSingleLineMode = NO;
    label.lineBreakMode = NSLineBreakByWordWrapping;
    return label;
}

- (NSTextField *)textField:(NSRect)frame {
    NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
    field.bezelStyle = NSTextFieldRoundedBezel;
    field.font = AppSerifFont(13);
    return field;
}

- (NSButton *)checkbox:(NSString *)title frame:(NSRect)frame {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    button.buttonType = NSButtonTypeSwitch;
    button.title = title;
    button.font = AppSerifFont(12);
    return button;
}

- (NSButton *)primaryButton:(NSString *)title frame:(NSRect)frame {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    button.bezelStyle = NSBezelStyleRounded;
    button.title = title;
    button.font = AppSerifBoldFont(13);
    button.bezelColor = AccentAmber();
    button.contentTintColor = NSColor.whiteColor;
    return button;
}

- (NSButton *)secondaryButton:(NSString *)title frame:(NSRect)frame {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    button.bezelStyle = NSBezelStyleRounded;
    button.title = title;
    button.font = AppSerifFont(12);
    button.bezelColor = [NSColor colorWithWhite:0.88 alpha:1.0];
    return button;
}

- (NSView *)separatorAtY:(CGFloat)y width:(CGFloat)width offsetX:(CGFloat)offsetX {
    NSView *sep = [[NSView alloc] initWithFrame:NSMakeRect(offsetX, y, width - offsetX * 2, 1)];
    sep.wantsLayer = YES;
    sep.layer.backgroundColor = [SubtleBorder() CGColor];
    return sep;
}

- (NSView *)separatorAtY:(CGFloat)y width:(CGFloat)width {
    return [self separatorAtY:y width:width offsetX:16];
}

// MARK: - CSS Editor Panel

- (void)createCSSPanelIfNeeded {
    if (self.cssPanel) return;

    self.cssPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 520, 400)
                                               styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView)
                                                 backing:NSBackingStoreBuffered
                                                   defer:NO];
    self.cssPanel.title = @"自定义 CSS 样式";
    self.cssPanel.releasedWhenClosed = NO;
    self.cssPanel.hidesOnDeactivate = NO;
    self.cssPanel.becomesKeyOnlyIfNeeded = NO;
    self.cssPanel.minSize = NSMakeSize(400, 300);

    NSView *content = self.cssPanel.contentView;
    content.wantsLayer = YES;
    content.layer.backgroundColor = [[NSColor colorWithRed:0.97 green:0.96 blue:0.94 alpha:1.0] CGColor];

    // Header
    NSTextField *header = [self label:@"自定义 CSS" frame:NSMakeRect(20, 355, 300, 28) size:18 bold:YES color:[NSColor labelColor]];
    [content addSubview:header];

    NSTextField *subheader = [self wrappingLabel:@"添加自定义 CSS 样式覆盖 EPUB 的默认排版。例如修改字体、间距、页边距等。" frame:NSMakeRect(20, 330, 480, 24) size:12 bold:NO color:[NSColor secondaryLabelColor]];
    [content addSubview:subheader];

    // CSS editor text view
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 40, 480, 274)];
    scrollView.hasVerticalScroller = YES;
    scrollView.hasHorizontalScroller = NO;
    scrollView.autohidesScrollers = YES;
    scrollView.borderType = NSLineBorder;
    scrollView.drawsBackground = YES;
    scrollView.backgroundColor = NSColor.whiteColor;

    NSTextView *textView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, 480, 274)];
    textView.font = AppSerifFont(12);
    textView.textColor = [NSColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:1.0];
    textView.backgroundColor = NSColor.whiteColor;
    textView.string = self.cssTextView.string ?: @"/* 在这里输入自定义 CSS */\n\n";
    textView.editable = YES;
    textView.richText = NO;
    textView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
    textView.textContainerInset = NSMakeSize(10, 10);
    scrollView.documentView = textView;
    self.cssTextView = textView;
    [content addSubview:scrollView];

    // Help label
    NSTextField *helpLabel = [self label:@"" frame:NSMakeRect(20, 14, 360, 18) size:11 bold:NO color:[NSColor secondaryLabelColor]];
    helpLabel.stringValue = @"此 CSS 会合并到 EPUB 的默认样式中。不支持在 CSS 中引用外部资源。";
    [content addSubview:helpLabel];

    // Done button
    NSButton *doneButton = [[NSButton alloc] initWithFrame:NSMakeRect(420, 10, 80, 26)];
    doneButton.bezelStyle = NSBezelStyleRounded;
    doneButton.title = @"完成";
    doneButton.font = AppSerifBoldFont(13);
    doneButton.bezelColor = AccentAmber();
    doneButton.contentTintColor = NSColor.whiteColor;
    doneButton.target = self;
    doneButton.action = @selector(cssPanelDone:);
    [content addSubview:doneButton];

    // Preview button (test apply)
    NSButton *applyButton = [[NSButton alloc] initWithFrame:NSMakeRect(340, 10, 74, 26)];
    applyButton.bezelStyle = NSBezelStyleRounded;
    applyButton.title = @"保存";
    applyButton.font = AppSerifFont(12);
    applyButton.bezelColor = [NSColor colorWithWhite:0.88 alpha:1.0];
    applyButton.target = self;
    applyButton.action = @selector(cssPanelDone:);
    [content addSubview:applyButton];
}

- (IBAction)showCSSPanel:(id)sender {
    [self createCSSPanelIfNeeded];

    [self.cssPanel makeKeyAndOrderFront:nil];
    if (!self.cssPanel.isVisible) {
        [self.cssPanel center];
    }
    [self.cssPanel makeKeyWindow];
}

- (IBAction)cssPanelDone:(id)sender {
    [self.cssPanel close];
    NSString *css = self.cssTextView.string;
    if (css.length > 0 && [css hasPrefix:@"/* "]) {
        // Only show status if there's actual CSS beyond the placeholder
        NSString *trimmed = [css stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length > 10) {
            self.statusLabel.stringValue = @"已应用自定义 CSS 样式。";
        }
    }
}

// MARK: - Chapter Preview Panel

- (void)createChapterPanelIfNeeded {
    if (self.chapterPanel) return;

    self.chapterPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(0, 0, 940, 580)
                                                   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable | NSWindowStyleMaskFullSizeContentView)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    self.chapterPanel.title = @"章节预览";
    self.chapterPanel.releasedWhenClosed = NO;
    self.chapterPanel.hidesOnDeactivate = NO;
    self.chapterPanel.becomesKeyOnlyIfNeeded = NO;
    self.chapterPanel.minSize = NSMakeSize(800, 450);

    NSView *cv = self.chapterPanel.contentView;
    cv.wantsLayer = YES;
    cv.layer.backgroundColor = [[NSColor colorWithRed:0.97 green:0.96 blue:0.94 alpha:1.0] CGColor];

    // Header
    NSTextField *header = [self label:@"章节预览" frame:NSMakeRect(20, 542, 200, 24) size:18 bold:YES color:[NSColor labelColor]];
    [cv addSubview:header];

    NSTextField *subheader = [self wrappingLabel:@"导出前可以先确认拆章是否准确，选中左侧章节后右侧会显示内容片段。"
                                           frame:NSMakeRect(20, 518, 600, 20) size:12 bold:NO color:[NSColor secondaryLabelColor]];
    [cv addSubview:subheader];

    // Chapter table on left
    NSScrollView *tableScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 16, 400, 492)];
    tableScroll.hasVerticalScroller = YES;
    tableScroll.drawsBackground = YES;
    tableScroll.backgroundColor = NSColor.whiteColor;
    tableScroll.borderType = NSLineBorder;

    self.tableView = [[NSTableView alloc] initWithFrame:tableScroll.bounds];
    self.tableView.backgroundColor = NSColor.whiteColor;
    self.tableView.gridColor = [NSColor colorWithWhite:0.94 alpha:1.0];
    self.tableView.intercellSpacing = NSMakeSize(0, 0);
    self.tableView.rowHeight = 36;
    self.tableView.selectionHighlightStyle = NSTableViewSelectionHighlightStyleRegular;

    NSTableColumn *chapterColumn = [[NSTableColumn alloc] initWithIdentifier:@"title"];
    chapterColumn.title = @"章节";
    chapterColumn.width = 160;
    NSTableColumn *previewColumn = [[NSTableColumn alloc] initWithIdentifier:@"preview"];
    previewColumn.title = @"预览";
    previewColumn.width = 220;
    [self.tableView addTableColumn:chapterColumn];
    [self.tableView addTableColumn:previewColumn];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.headerView = nil;
    tableScroll.documentView = self.tableView;
    [cv addSubview:tableScroll];

    // Preview pane on right
    NSView *previewPane = [[NSView alloc] initWithFrame:NSMakeRect(436, 16, 488, 492)];
    previewPane.wantsLayer = YES;
    previewPane.layer.backgroundColor = [NSColor.whiteColor CGColor];
    previewPane.layer.cornerRadius = 8.0;
    previewPane.layer.shadowColor = [[NSColor colorWithWhite:0.0 alpha:0.06] CGColor];
    previewPane.layer.shadowOffset = NSMakeSize(0, 2);
    previewPane.layer.shadowRadius = 6.0;
    previewPane.layer.shadowOpacity = 1.0;
    previewPane.layer.borderWidth = 1.0;
    previewPane.layer.borderColor = [[NSColor colorWithWhite:0.88 alpha:1.0] CGColor];

    self.previewTitleLabel = [self label:@"章节内容预览" frame:NSMakeRect(16, 458, 360, 20) size:15 bold:YES color:[NSColor labelColor]];
    [previewPane addSubview:self.previewTitleLabel];
    self.previewMetaLabel = [self wrappingLabel:@"选中左侧章节后，这里会显示内容片段。"
                                          frame:NSMakeRect(16, 436, 400, 18) size:12 bold:NO color:[NSColor secondaryLabelColor]];
    [previewPane addSubview:self.previewMetaLabel];

    NSView *sep = [[NSView alloc] initWithFrame:NSMakeRect(16, 428, 456, 1)];
    sep.wantsLayer = YES;
    sep.layer.backgroundColor = [[NSColor colorWithWhite:0.88 alpha:1.0] CGColor];
    [previewPane addSubview:sep];

    NSScrollView *textScroll = [[NSScrollView alloc] initWithFrame:NSMakeRect(16, 12, 456, 408)];
    textScroll.hasVerticalScroller = YES;
    textScroll.drawsBackground = YES;
    textScroll.backgroundColor = [NSColor colorWithWhite:0.98 alpha:1.0];
    textScroll.borderType = NSLineBorder;

    self.previewTextView = [[NSTextView alloc] initWithFrame:textScroll.bounds];
    self.previewTextView.editable = NO;
    self.previewTextView.richText = NO;
    self.previewTextView.font = AppSerifFont(14);
    self.previewTextView.string = @"还没有章节内容可预览。";
    self.previewTextView.backgroundColor = [NSColor colorWithWhite:0.98 alpha:1.0];
    self.previewTextView.textColor = [NSColor colorWithRed:0.20 green:0.16 blue:0.12 alpha:1.0];
    self.previewTextView.textContainerInset = NSMakeSize(14, 14);
    textScroll.documentView = self.previewTextView;
    [previewPane addSubview:textScroll];
    [cv addSubview:previewPane];

    // Close button
    NSButton *closeBtn = [[NSButton alloc] initWithFrame:NSMakeRect(840, 542, 80, 26)];
    closeBtn.bezelStyle = NSBezelStyleRounded;
    closeBtn.title = @"关闭";
    closeBtn.font = AppSerifBoldFont(13);
    closeBtn.bezelColor = AccentAmber();
    closeBtn.contentTintColor = NSColor.whiteColor;
    closeBtn.target = self;
    closeBtn.action = @selector(chapterPanelDone:);
    [cv addSubview:closeBtn];
}

- (IBAction)showChapterPanel:(id)sender {
    [self createChapterPanelIfNeeded];

    // Auto-refresh data when opening the panel
    if (self.selectedFilePath.length > 0) {
        [self refreshPreview:nil];
    }

    [self.chapterPanel makeKeyAndOrderFront:nil];
    if (!self.chapterPanel.isVisible) {
        [self.chapterPanel center];
    }
    [self.chapterPanel makeKeyWindow];
}

- (IBAction)chapterPanelDone:(id)sender {
    [self.chapterPanel close];
}

// MARK: - Build Window

- (void)buildWindow {
    CGFloat WW = 980;
    CGFloat WH = 680;

    NSRect frame = NSMakeRect(0, 0, WW, WH);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskMiniaturizable)
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    self.window.titlebarAppearsTransparent = YES;
    self.window.titleVisibility = NSWindowTitleHidden;
    self.window.minSize = NSMakeSize(WW, WH);
    self.window.maxSize = NSMakeSize(WW, WH);
    [self.window center];
    [self.window setTitle:@"EasyPubMac"];
    [self.window makeKeyAndOrderFront:nil];
    self.window.movableByWindowBackground = YES;

    NSView *content = self.window.contentView;
    content.wantsLayer = YES;
    content.layer.backgroundColor = [WindowBackground() CGColor];
    content.autoresizesSubviews = NO;

    __weak typeof(self) weakSelf = self;

    // Top brand bar, inspired by the green book in the app icon.
    NSView *brandBar = [[NSView alloc] initWithFrame:NSMakeRect(0, WH - 82, WW, 82)];
    brandBar.wantsLayer = YES;
    CAGradientLayer *barGrad = [CAGradientLayer layer];
    barGrad.frame = brandBar.bounds;
    barGrad.colors = @[
        (id)[HeroDarkStart() CGColor],
        (id)[HeroDarkEnd() CGColor],
    ];
    barGrad.startPoint = CGPointMake(0, 0.5);
    barGrad.endPoint = CGPointMake(1, 0.5);
    [brandBar.layer addSublayer:barGrad];
    [content addSubview:brandBar];

    NSTextField *brandTitle = [self label:@"EasyPubMac" frame:NSMakeRect(28, 36, 260, 30) size:24 bold:YES color:NSColor.whiteColor];
    [brandBar addSubview:brandTitle];
    NSTextField *brandSub = [self label:@"TXT to EPUB · 本地转换 · 自定义封面" frame:NSMakeRect(30, 16, 340, 18) size:12 bold:NO color:[NSColor colorWithWhite:0.94 alpha:0.88]];
    [brandBar addSubview:brandSub];

    // File and stats row.
    CGFloat fileY = 522;
    TxtDropView *fileCard = [[TxtDropView alloc] initWithFrame:NSMakeRect(28, fileY, 610, 70)];
    self.txtDropView = fileCard;
    fileCard.onDrop = ^(NSString *path) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.selectedFilePath = path;
            strongSelf.window.representedURL = [NSURL fileURLWithPath:path];
            [strongSelf.txtDropView setFileName:path.lastPathComponent];
            if (strongSelf.titleField.stringValue.length == 0)
                strongSelf.titleField.stringValue = [path.lastPathComponent stringByDeletingPathExtension] ?: @"";
            [strongSelf refreshPreview:nil];
        }
    };
    NSButton *chooseBtn = [[NSButton alloc] initWithFrame:NSMakeRect(446, 18, 148, 34)];
    chooseBtn.bezelStyle = NSBezelStyleRounded;
    chooseBtn.title = @"选择 TXT 文件";
    chooseBtn.font = AppSerifBoldFont(13);
    chooseBtn.bezelColor = AccentAmberLight();
    chooseBtn.contentTintColor = [NSColor colorWithRed:0.18 green:0.16 blue:0.10 alpha:1.0];
    chooseBtn.target = self;
    chooseBtn.action = @selector(chooseFile:);
    chooseBtn.keyEquivalent = @"o";
    chooseBtn.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [fileCard addSubview:chooseBtn];
    [content addSubview:fileCard];

    NSView *chapterStat = [self cardView:NSMakeRect(656, fileY, 132, 70)];
    [chapterStat addSubview:[self label:@"识别章节" frame:NSMakeRect(16, 40, 90, 18) size:11 bold:NO color:[NSColor secondaryLabelColor]]];
    self.chapterCountLabel = [self label:@"0" frame:NSMakeRect(16, 13, 100, 26) size:22 bold:YES color:AccentAmberDark()];
    [chapterStat addSubview:self.chapterCountLabel];
    [content addSubview:chapterStat];

    NSView *wordStat = [self cardView:NSMakeRect(806, fileY, 146, 70)];
    [wordStat addSubview:[self label:@"预估字数" frame:NSMakeRect(16, 40, 90, 18) size:11 bold:NO color:[NSColor secondaryLabelColor]]];
    self.wordCountLabel = [self label:@"0" frame:NSMakeRect(16, 13, 116, 26) size:22 bold:YES color:AccentAmberDark()];
    [wordStat addSubview:self.wordCountLabel];
    [content addSubview:wordStat];

    // Main settings card.
    NSView *card = [self cardView:NSMakeRect(28, 28, 924, 468)];
    [content addSubview:card];

    CGFloat CW = card.bounds.size.width;
    CGFloat leftX = 28;
    CGFloat leftW = 566;
    CGFloat rightX = 638;
    CGFloat rightW = CW - rightX - 28;
    CGFloat coverBoxW = 190;
    CGFloat coverBoxX = rightX + (rightW - coverBoxW) / 2;

    [card addSubview:[self label:@"书籍信息" frame:NSMakeRect(leftX, 418, 140, 22) size:16 bold:YES color:[NSColor labelColor]]];
    [card addSubview:[self label:@"编辑元数据，导出时会写入 EPUB 文件。" frame:NSMakeRect(leftX, 394, 320, 18) size:12 bold:NO color:WarmGrayText()]];

    [card addSubview:[self label:@"书名" frame:NSMakeRect(leftX, 350, 46, 20) size:12 bold:NO color:[NSColor labelColor]]];
    self.titleField = [self textField:NSMakeRect(86, 344, 508, 30)];
    [card addSubview:self.titleField];

    [card addSubview:[self label:@"作者" frame:NSMakeRect(leftX, 306, 46, 20) size:12 bold:NO color:[NSColor labelColor]]];
    self.authorField = [self textField:NSMakeRect(86, 300, 230, 30)];
    [self.authorField setStringValue:@"佚名"];
    [card addSubview:self.authorField];

    [card addSubview:[self label:@"语言" frame:NSMakeRect(344, 306, 46, 20) size:12 bold:NO color:[NSColor labelColor]]];
    self.languageField = [self textField:NSMakeRect(396, 300, 126, 30)];
    [self.languageField setStringValue:@"zh-CN"];
    [card addSubview:self.languageField];

    [card addSubview:[self separatorAtY:270 width:leftW + 56 offsetX:leftX]];
    [card addSubview:[self label:@"排版设置" frame:NSMakeRect(leftX, 238, 140, 22) size:16 bold:YES color:[NSColor labelColor]]];

    [card addSubview:[self label:@"字号 %" frame:NSMakeRect(leftX, 198, 56, 20) size:12 bold:NO color:[NSColor labelColor]]];
    self.fontSizeField = [self textField:NSMakeRect(86, 192, 82, 30)];
    [self.fontSizeField setStringValue:@"100"];
    [card addSubview:self.fontSizeField];

    [card addSubview:[self label:@"行距 %" frame:NSMakeRect(202, 198, 56, 20) size:12 bold:NO color:[NSColor labelColor]]];
    self.lineHeightField = [self textField:NSMakeRect(260, 192, 82, 30)];
    [self.lineHeightField setStringValue:@"130"];
    [card addSubview:self.lineHeightField];

    [card addSubview:[self label:@"缩进" frame:NSMakeRect(376, 198, 46, 20) size:12 bold:NO color:[NSColor labelColor]]];
    self.indentField = [self textField:NSMakeRect(424, 192, 82, 30)];
    [self.indentField setStringValue:@"2"];
    [card addSubview:self.indentField];

    [card addSubview:[self label:@"字体" frame:NSMakeRect(leftX, 154, 46, 20) size:12 bold:NO color:[NSColor labelColor]]];
    self.fontPathField = [self textField:NSMakeRect(86, 148, 296, 30)];
    self.fontPathField.enabled = NO;
    self.fontPathField.placeholderString = @"无";
    self.fontPathField.stringValue = @"";
    [card addSubview:self.fontPathField];

    NSButton *chooseFontBtn = [self secondaryButton:@"选择字体" frame:NSMakeRect(396, 148, 86, 30)];
    chooseFontBtn.target = self;
    chooseFontBtn.action = @selector(chooseFontFile:);
    [card addSubview:chooseFontBtn];

    NSButton *clearFontBtn = [self secondaryButton:@"清除" frame:NSMakeRect(492, 148, 78, 30)];
    clearFontBtn.target = self;
    clearFontBtn.action = @selector(clearFontFile:);
    [card addSubview:clearFontBtn];

    self.removeBlankCheckbox = [self checkbox:@"去除空白行" frame:NSMakeRect(leftX, 108, 120, 22)];
    self.justifyCheckbox = [self checkbox:@"两端对齐" frame:NSMakeRect(160, 108, 120, 22)];
    self.coverCheckbox = [self checkbox:@"生成封面页" frame:NSMakeRect(292, 108, 140, 22)];
    self.removeBlankCheckbox.state = NSControlStateValueOn;
    self.justifyCheckbox.state = NSControlStateValueOn;
    self.coverCheckbox.state = NSControlStateValueOn;
    [card addSubview:self.removeBlankCheckbox];
    [card addSubview:self.justifyCheckbox];
    [card addSubview:self.coverCheckbox];

    [card addSubview:[self separatorAtY:82 width:leftW + 56 offsetX:leftX]];

    NSButton *cssButton = [[NSButton alloc] initWithFrame:NSMakeRect(leftX, 34, 136, 30)];
    cssButton.bezelStyle = NSBezelStyleRoundRect;
    cssButton.title = @"高级 CSS";
    cssButton.font = AppSerifFont(12);
    cssButton.buttonType = NSButtonTypeMomentaryPushIn;
    cssButton.contentTintColor = AccentAmberDark();
    cssButton.target = self;
    cssButton.action = @selector(showCSSPanel:);
    [card addSubview:cssButton];

    NSButton *previewBtn = [[NSButton alloc] initWithFrame:NSMakeRect(180, 34, 136, 30)];
    previewBtn.bezelStyle = NSBezelStyleRoundRect;
    previewBtn.title = @"预览章节";
    previewBtn.font = AppSerifFont(12);
    previewBtn.buttonType = NSButtonTypeMomentaryPushIn;
    previewBtn.contentTintColor = AccentAmberDark();
    previewBtn.target = self;
    previewBtn.action = @selector(showChapterPanel:);
    [card addSubview:previewBtn];

    NSButton *refreshBtn = [[NSButton alloc] initWithFrame:NSMakeRect(332, 34, 112, 30)];
    refreshBtn.bezelStyle = NSBezelStyleRoundRect;
    refreshBtn.title = @"刷新预览";
    refreshBtn.font = AppSerifFont(12);
    refreshBtn.buttonType = NSButtonTypeMomentaryPushIn;
    refreshBtn.contentTintColor = AccentAmberDark();
    self.refreshButton = refreshBtn;
    refreshBtn.target = self;
    refreshBtn.action = @selector(refreshPreview:);
    [card addSubview:refreshBtn];

    // Cover module gets its own fixed column, so it cannot overlap the form.
    NSView *coverDivider = [[NSView alloc] initWithFrame:NSMakeRect(rightX - 24, 34, 1, 386)];
    coverDivider.wantsLayer = YES;
    coverDivider.layer.backgroundColor = [SubtleBorder() CGColor];
    [card addSubview:coverDivider];

    [card addSubview:[self label:@"封面" frame:NSMakeRect(rightX, 418, 120, 22) size:16 bold:YES color:[NSColor labelColor]]];
    [card addSubview:[self label:@"拖入图片或点击封面框选择。" frame:NSMakeRect(rightX, 394, rightW, 18) size:12 bold:NO color:WarmGrayText()]];

    DropZoneView *dropZone = [[DropZoneView alloc] initWithFrame:NSMakeRect(coverBoxX, 150, coverBoxW, 226)];
    self.coverDropZone = dropZone;
    dropZone.onDrop = ^(NSString *path) {
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.selectedCoverPath = path;
            strongSelf.coverCheckbox.state = NSControlStateValueOn;
            strongSelf.statusLabel.stringValue = @"已选择自定义封面图片。";
        }
    };
    dropZone.onClear = ^{
        typeof(self) strongSelf = weakSelf;
        if (strongSelf) {
            strongSelf.selectedCoverPath = nil;
            strongSelf.coverCheckbox.state = NSControlStateValueOn;
            strongSelf.statusLabel.stringValue = @"已移除自定义封面图片。";
        }
    };
    [card addSubview:dropZone];

    NSButton *chooseCoverButton = [self secondaryButton:@"选择封面" frame:NSMakeRect(coverBoxX, 108, 92, 30)];
    chooseCoverButton.target = self;
    chooseCoverButton.action = @selector(chooseCoverImage:);
    [card addSubview:chooseCoverButton];

    NSButton *clearCoverButton = [self secondaryButton:@"移除" frame:NSMakeRect(coverBoxX + 104, 108, 86, 30)];
    clearCoverButton.target = self;
    clearCoverButton.action = @selector(clearCoverImage:);
    [card addSubview:clearCoverButton];

    [card addSubview:[self separatorAtY:82 width:CW]];
    NSButton *exportBtn = [[NSButton alloc] initWithFrame:NSMakeRect(coverBoxX, 34, coverBoxW, 34)];
    exportBtn.bezelStyle = NSBezelStyleRounded;
    exportBtn.title = @"导出 EPUB";
    exportBtn.font = AppSerifBoldFont(14);
    exportBtn.bezelColor = AccentAmber();
    exportBtn.contentTintColor = NSColor.whiteColor;
    self.exportButton = exportBtn;
    exportBtn.target = self;
    exportBtn.action = @selector(exportEPUB:);
    exportBtn.keyEquivalent = @"e";
    exportBtn.keyEquivalentModifierMask = NSEventModifierFlagCommand;
    [card addSubview:exportBtn];

    self.statusLabel = [self wrappingLabel:@"拖拽 TXT 到文件卡片开始。"
                                     frame:NSMakeRect(28, 8, 560, 18)
                                      size:12 bold:NO color:WarmGrayText()];
    [card addSubview:self.statusLabel];
    self.progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(884, 44, 14, 14)];
    self.progressIndicator.style = NSProgressIndicatorStyleSpinning;
    self.progressIndicator.controlSize = NSControlSizeSmall;
    self.progressIndicator.displayedWhenStopped = NO;
    [card addSubview:self.progressIndicator];
}

// MARK: - Menu

- (void)buildMenu {
    NSMenu *mainMenu = [[NSMenu alloc] initWithTitle:@""];

    NSMenuItem *appItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSMenu *appMenu = [[NSMenu alloc] initWithTitle:@"EasyPubMac"];
    [appMenu addItem:[[NSMenuItem alloc] initWithTitle:@"关于 EasyPubMac" action:@selector(showAbout:) keyEquivalent:@""]];
    [appMenu addItem:[NSMenuItem separatorItem]];
    [appMenu addItem:[[NSMenuItem alloc] initWithTitle:@"退出 EasyPubMac" action:@selector(terminate:) keyEquivalent:@"q"]];
    appItem.submenu = appMenu;
    [mainMenu addItem:appItem];

    NSMenuItem *fileItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSMenu *fileMenu = [[NSMenu alloc] initWithTitle:@"文件"];
    [self addMenuItem:fileMenu title:@"选择 TXT 文件..." action:@selector(chooseFile:) key:@"o" target:self];
    [self addMenuItem:fileMenu title:@"选择封面图片..." action:@selector(chooseCoverImage:) key:@"c" target:self shift:YES];
    [self addMenuItem:fileMenu title:@"自定义 CSS..." action:@selector(showCSSPanel:) key:@"s" target:self shift:YES];
    [self addMenuItem:fileMenu title:@"刷新预览" action:@selector(refreshPreview:) key:@"r" target:self];
    [self addMenuItem:fileMenu title:@"导出 EPUB..." action:@selector(exportEPUB:) key:@"e" target:self];
    fileItem.submenu = fileMenu;
    [mainMenu addItem:fileItem];

    NSMenuItem *editItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSMenu *editMenu = [[NSMenu alloc] initWithTitle:@"编辑"];
    [editMenu addItem:[[NSMenuItem alloc] initWithTitle:@"剪切" action:@selector(cut:) keyEquivalent:@"x"]];
    [editMenu addItem:[[NSMenuItem alloc] initWithTitle:@"复制" action:@selector(copy:) keyEquivalent:@"c"]];
    [editMenu addItem:[[NSMenuItem alloc] initWithTitle:@"粘贴" action:@selector(paste:) keyEquivalent:@"v"]];
    [editMenu addItem:[[NSMenuItem alloc] initWithTitle:@"全选" action:@selector(selectAll:) keyEquivalent:@"a"]];
    editItem.submenu = editMenu;
    [mainMenu addItem:editItem];

    NSMenuItem *windowItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSMenu *windowMenu = [[NSMenu alloc] initWithTitle:@"窗口"];
    [windowMenu addItem:[[NSMenuItem alloc] initWithTitle:@"最小化" action:@selector(performMiniaturize:) keyEquivalent:@"m"]];
    [windowMenu addItem:[[NSMenuItem alloc] initWithTitle:@"缩放" action:@selector(performZoom:) keyEquivalent:@""]];
    windowItem.submenu = windowMenu;
    [mainMenu addItem:windowItem];

    // Window menu also holds CSS panel reference
    NSMenuItem *toolsItem = [[NSMenuItem alloc] initWithTitle:@"" action:nil keyEquivalent:@""];
    NSMenu *toolsMenu = [[NSMenu alloc] initWithTitle:@"工具"];
    NSMenuItem *cssMenuItem = [[NSMenuItem alloc] initWithTitle:@"自定义 CSS..." action:@selector(showCSSPanel:) keyEquivalent:@"s"];
    cssMenuItem.target = self;
    cssMenuItem.keyEquivalentModifierMask = NSEventModifierFlagCommand | NSEventModifierFlagShift;
    [toolsMenu addItem:cssMenuItem];
    toolsItem.submenu = toolsMenu;
    [mainMenu addItem:toolsItem];

    [NSApp setMainMenu:mainMenu];
}

- (void)addMenuItem:(NSMenu *)menu title:(NSString *)title action:(SEL)action key:(NSString *)key target:(id)target {
    [self addMenuItem:menu title:title action:action key:key target:target shift:NO];
}

- (void)addMenuItem:(NSMenu *)menu title:(NSString *)title action:(SEL)action key:(NSString *)key target:(id)target shift:(BOOL)shift {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = target;
    item.keyEquivalentModifierMask = shift ? (NSEventModifierFlagCommand | NSEventModifierFlagShift) : NSEventModifierFlagCommand;
    [menu addItem:item];
}

// MARK: - Actions

- (IBAction)showAbout:(id)sender {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"EasyPubMac";
    alert.informativeText = @"原生 macOS 电子书制作工具，支持 TXT 拆章预览、自定义封面与 EPUB 导出。\n版本 0.3.0 - 图标主题界面";
    [alert runModal];
}

- (NSArray<NSString *> *)backendArgumentsForCommand:(NSString *)command {
    NSMutableArray<NSString *> *args = [NSMutableArray arrayWithArray:@[
        command,
        @"--input", self.selectedFilePath ?: @"",
        @"--title", self.titleField.stringValue ?: @"",
        @"--author", self.authorField.stringValue ?: @"佚名",
        @"--language", self.languageField.stringValue ?: @"zh-CN",
        @"--font-size", self.fontSizeField.stringValue ?: @"100",
        @"--line-height", self.lineHeightField.stringValue ?: @"130",
        @"--indent", self.indentField.stringValue ?: @"2",
    ]];
    [args addObject:(self.removeBlankCheckbox.state == NSControlStateValueOn ? @"--remove-blank-lines" : @"--no-remove-blank-lines")];
    [args addObject:(self.justifyCheckbox.state == NSControlStateValueOn ? @"--justify-text" : @"--no-justify-text")];
    [args addObject:(self.coverCheckbox.state == NSControlStateValueOn ? @"--generate-cover" : @"--no-generate-cover")];
    if (self.selectedCoverPath.length > 0)
        [args addObjectsFromArray:@[@"--cover-image", self.selectedCoverPath]];

    // Add font path if present
    if (self.selectedFontPath.length > 0)
        [args addObjectsFromArray:@[@"--font-path", self.selectedFontPath]];

    // Add custom CSS if present
    NSString *css = self.cssTextView.string ?: @"";
    NSString *trimmed = [css stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmed.length > 0 && ![trimmed hasPrefix:@"/*"] || trimmed.length > 15) {
        // Pass actual CSS content (not just the placeholder comment)
        if (![trimmed isEqualToString:@"/* 在这里输入自定义 CSS */"]) {
            [args addObjectsFromArray:@[@"--custom-css", css]];
        }
    }

    return args;
}

- (void)setWorking:(BOOL)working status:(NSString *)status {
    self.refreshButton.enabled = !working;
    self.exportButton.enabled = !working;
    if (status.length > 0) self.statusLabel.stringValue = status;
    if (working)
        [self.progressIndicator startAnimation:nil];
    else
        [self.progressIndicator stopAnimation:nil];
}

- (NSInteger)runBackendWithArguments:(NSArray<NSString *> *)arguments stdoutData:(NSData **)stdoutData errorText:(NSString **)errorText {
    NSString *scriptPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"easypub_mac.py"];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/python3";
    NSMutableArray *fullArgs = [NSMutableArray arrayWithObject:scriptPath];
    [fullArgs addObjectsFromArray:arguments];
    task.arguments = fullArgs;

    NSPipe *stdoutPipe = [NSPipe pipe];
    NSPipe *stderrPipe = [NSPipe pipe];
    task.standardOutput = stdoutPipe;
    task.standardError = stderrPipe;

    NSMutableData *collectedStdout = [NSMutableData data];
    NSMutableData *collectedStderr = [NSMutableData data];
    NSFileHandle *stdoutHandle = [stdoutPipe fileHandleForReading];
    NSFileHandle *stderrHandle = [stderrPipe fileHandleForReading];

    stdoutHandle.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = [handle availableData];
        if (data.length == 0) { handle.readabilityHandler = nil; return; }
        @synchronized (collectedStdout) { [collectedStdout appendData:data]; }
    };
    stderrHandle.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = [handle availableData];
        if (data.length == 0) { handle.readabilityHandler = nil; return; }
        @synchronized (collectedStderr) { [collectedStderr appendData:data]; }
    };

    @try { [task launch]; }
    @catch (NSException *exception) {
        stdoutHandle.readabilityHandler = nil;
        stderrHandle.readabilityHandler = nil;
        if (errorText) *errorText = exception.reason ?: @"启动后台处理器失败。";
        return -1;
    }

    [task waitUntilExit];
    stdoutHandle.readabilityHandler = nil;
    stderrHandle.readabilityHandler = nil;

    NSData *remainingStdout = [stdoutHandle readDataToEndOfFile];
    if (remainingStdout.length > 0) { @synchronized (collectedStdout) { [collectedStdout appendData:remainingStdout]; } }
    NSData *remainingStderr = [stderrHandle readDataToEndOfFile];
    if (remainingStderr.length > 0) { @synchronized (collectedStderr) { [collectedStderr appendData:remainingStderr]; } }

    if (stdoutData) { @synchronized (collectedStdout) { *stdoutData = [collectedStdout copy]; } }
    if (errorText) {
        NSData *stderrData; @synchronized (collectedStderr) { stderrData = [collectedStderr copy]; }
        *errorText = [[NSString alloc] initWithData:stderrData encoding:NSUTF8StringEncoding] ?: @"";
    }
    return task.terminationStatus;
}

- (NSDictionary *)runAnalyzeWithArguments:(NSArray<NSString *> *)arguments error:(NSString **)errorMessage {
    NSData *stdoutData = nil;
    NSString *stderrText = nil;
    NSInteger status = [self runBackendWithArguments:arguments stdoutData:&stdoutData errorText:&stderrText];
    if (status != 0) { if (errorMessage) *errorMessage = stderrText.length > 0 ? stderrText : @"解析失败."; return nil; }
    NSError *jsonError = nil;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:stdoutData options:0 error:&jsonError];
    if (!json || jsonError) { if (errorMessage) *errorMessage = @"预览数据解析失败。"; return nil; }
    return json;
}

- (BOOL)runExportWithArguments:(NSArray<NSString *> *)arguments toPath:(NSString *)outputPath error:(NSString **)errorMessage {
    NSMutableArray *args = [NSMutableArray arrayWithArray:arguments];
    [args addObjectsFromArray:@[@"--output", outputPath]];
    NSData *stdoutData = nil; NSString *stderrText = nil;
    NSInteger status = [self runBackendWithArguments:args stdoutData:&stdoutData errorText:&stderrText];
    if (status != 0) { if (errorMessage) *errorMessage = stderrText.length > 0 ? stderrText : @"导出失败。"; return NO; }
    return YES;
}

- (IBAction)chooseFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypePlainText];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    if ([panel runModal] == NSModalResponseOK) {
        self.selectedFilePath = panel.URL.path;
        self.window.representedURL = panel.URL;
        [self.txtDropView setFileName:panel.URL.lastPathComponent];
        if (self.titleField.stringValue.length == 0)
            self.titleField.stringValue = [panel.URL.lastPathComponent stringByDeletingPathExtension] ?: @"";
        [self refreshPreview:nil];
    }
}

- (IBAction)chooseCoverImage:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypeImage];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    if ([panel runModal] == NSModalResponseOK) {
        self.selectedCoverPath = panel.URL.path;
        self.coverDropZone.filePath = panel.URL.path;
        self.coverCheckbox.state = NSControlStateValueOn;
        self.statusLabel.stringValue = @"已选择自定义封面图片。";
    }
}

- (IBAction)clearCoverImage:(id)sender {
    self.selectedCoverPath = nil;
    self.coverDropZone.filePath = nil;
    self.coverCheckbox.state = NSControlStateValueOn;
    self.statusLabel.stringValue = @"已移除自定义封面图片。";
}

- (IBAction)chooseFontFile:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    NSMutableArray<UTType *> *fontTypes = [NSMutableArray array];
    UTType *ttfType = [UTType typeWithFilenameExtension:@"ttf"];
    UTType *otfType = [UTType typeWithFilenameExtension:@"otf"];
    if (ttfType) [fontTypes addObject:ttfType];
    if (otfType) [fontTypes addObject:otfType];
    if (fontTypes.count > 0) panel.allowedContentTypes = fontTypes;
    panel.message = @"选择 TTF 或 OTF 字体文件";
    if ([panel runModal] == NSModalResponseOK) {
        self.selectedFontPath = panel.URL.path;
        self.fontPathField.stringValue = panel.URL.lastPathComponent ?: @"";
        self.statusLabel.stringValue = [NSString stringWithFormat:@"已选择字体：%@", panel.URL.lastPathComponent];
    }
}

- (IBAction)clearFontFile:(id)sender {
    self.selectedFontPath = nil;
    self.fontPathField.stringValue = @"";
    self.statusLabel.stringValue = @"已清除自定义字体。";
}

- (IBAction)refreshPreview:(id)sender {
    if (self.selectedFilePath.length == 0) {
        self.statusLabel.stringValue = @"请先选择 TXT 文件。";
        return;
    }
    self.analysisRequestID += 1;
    NSUInteger requestID = self.analysisRequestID;
    NSArray<NSString *> *arguments = [[self backendArgumentsForCommand:@"analyze"] copy];
    [self setWorking:YES status:@"正在分析 TXT，请稍等..."];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *errorMessage = nil;
        NSDictionary *result = [self runAnalyzeWithArguments:arguments error:&errorMessage];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (requestID != self.analysisRequestID) return;
            [self setWorking:NO status:@""];
            if (!result) { self.statusLabel.stringValue = errorMessage ?: @"预览失败。"; return; }

            self.chapters = result[@"chapters"] ?: @[];
            NSNumber *chapterCount = result[@"chapter_count"] ?: @0;
            self.chapterCountLabel.stringValue = [NSString stringWithFormat:@"%@", chapterCount];
            self.wordCountLabel.stringValue = [NSString stringWithFormat:@"%@", result[@"word_count"] ?: @0];
            [self.txtDropView setFileName:result[@"file_name"] ?: @"未选择文件"];
            BOOL truncated = [result[@"is_truncated"] boolValue];
            if (truncated)
                self.statusLabel.stringValue = [NSString stringWithFormat:@"识别到 %@ 个章节，预览仅显示前 %@ 个，导出会处理全文。", chapterCount, result[@"preview_limit"] ?: @0];
            else
                self.statusLabel.stringValue = [NSString stringWithFormat:@"识别到 %@ 个章节，可以导出 EPUB。", chapterCount];
            [self.tableView reloadData];

            if (self.chapters.count > 0) {
                [self.tableView selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
                [self updatePreviewForIndex:0];
            } else {
                if (self.previewTitleLabel) self.previewTitleLabel.stringValue = @"章节内容预览";
                if (self.previewMetaLabel) self.previewMetaLabel.stringValue = @"没有检测到可预览的章节。";
                if (self.previewTextView) self.previewTextView.string = @"";
            }
        });
    });
}

- (IBAction)exportEPUB:(id)sender {
    if (self.selectedFilePath.length == 0) {
        self.statusLabel.stringValue = @"请先选择 TXT 文件。";
        return;
    }
    NSSavePanel *panel = [NSSavePanel savePanel];
    UTType *epubType = [UTType typeWithFilenameExtension:@"epub"];
    if (epubType) panel.allowedContentTypes = @[epubType];
    NSString *suggestedName = self.titleField.stringValue.length > 0 ? self.titleField.stringValue : [self.selectedFilePath.lastPathComponent stringByDeletingPathExtension];
    panel.nameFieldStringValue = [suggestedName stringByAppendingPathExtension:@"epub"];
    if ([panel runModal] != NSModalResponseOK) return;

    NSArray<NSString *> *arguments = [[self backendArgumentsForCommand:@"export"] copy];
    NSString *outputPath = [panel.URL.path copy];
    [self setWorking:YES status:@"正在导出 EPUB，请稍等..."];

    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
        NSString *errorMessage = nil;
        BOOL ok = [self runExportWithArguments:arguments toPath:outputPath error:&errorMessage];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self setWorking:NO status:@""];
            if (!ok) {
                self.statusLabel.stringValue = errorMessage ?: @"导出失败。";
                NSAlert *alert = [[NSAlert alloc] init];
                alert.messageText = @"导出失败";
                alert.informativeText = self.statusLabel.stringValue;
                [alert runModal];
                return;
            }
            self.statusLabel.stringValue = [NSString stringWithFormat:@"已导出到 %@", outputPath];
            NSAlert *alert = [[NSAlert alloc] init];
            alert.messageText = @"导出完成";
            alert.informativeText = outputPath;
            [alert runModal];
        });
    });
}

// MARK: - TableView

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return self.chapters.count;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSDictionary *chapter = self.chapters[row];
    NSString *identifier = tableColumn.identifier;
    NSTableCellView *cell = [tableView makeViewWithIdentifier:identifier owner:self];
    if (!cell) {
        cell = [[NSTableCellView alloc] initWithFrame:NSMakeRect(0, 0, tableColumn.width, 36)];
        cell.identifier = identifier;
        NSTextField *textField = [[NSTextField alloc] initWithFrame:NSMakeRect(10, 8, tableColumn.width - 20, 20)];
        textField.bezeled = NO;
        textField.drawsBackground = NO;
        textField.editable = NO;
        textField.selectable = NO;
        textField.font = AppSerifFont(12);
        cell.textField = textField;
        [cell addSubview:textField];
    }
    BOOL isTitle = [identifier isEqualToString:@"title"];
    cell.textField.stringValue = isTitle ? (chapter[@"title"] ?: @"") : (chapter[@"preview"] ?: @"");
    cell.textField.font = isTitle ? AppSerifBoldFont(12) : AppSerifFont(12);
    cell.textField.textColor = isTitle ? [NSColor labelColor] : [NSColor secondaryLabelColor];
    return cell;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification {
    NSInteger selected = self.tableView.selectedRow;
    if (selected >= 0 && selected < self.chapters.count)
        [self updatePreviewForIndex:selected];
}

- (void)updatePreviewForIndex:(NSInteger)index {
    if (index < 0 || index >= self.chapters.count) return;
    NSDictionary *chapter = self.chapters[index];
    if (self.previewTitleLabel)
        self.previewTitleLabel.stringValue = chapter[@"title"] ?: @"章节内容预览";
    NSNumber *paragraphCount = chapter[@"paragraph_count"] ?: @0;
    if (self.previewMetaLabel)
        self.previewMetaLabel.stringValue = [NSString stringWithFormat:@"第 %ld / %lu 章 · %@ 段内容", (long)(index + 1), (unsigned long)self.chapters.count, paragraphCount];
    if (self.previewTextView)
        self.previewTextView.string = chapter[@"excerpt"] ?: @"";
}

@end

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        [app setActivationPolicy:NSApplicationActivationPolicyRegular];
        AppDelegate *delegate = [[AppDelegate alloc] init];
        app.delegate = delegate;
        [app activateIgnoringOtherApps:YES];
        [app run];
    }
    return 0;
}
