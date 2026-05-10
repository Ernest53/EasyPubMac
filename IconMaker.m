#import <Cocoa/Cocoa.h>

// MARK: - Drawing helpers

static NSBezierPath *SquirclePath(NSRect rect, CGFloat radius) {
    return [NSBezierPath bezierPathWithRoundedRect:rect xRadius:radius yRadius:radius];
}

static void DrawRoundedRect(NSRect rect, CGFloat radius, NSColor *color) {
    [color setFill];
    [SquirclePath(rect, radius) fill];
}

static void DrawGradientRounded(NSRect rect, CGFloat radius, NSGradient *gradient, CGFloat angle) {
    [gradient drawInBezierPath:SquirclePath(rect, radius) angle:angle];
}

static void DrawShadowed(NSRect rect, CGFloat radius, CGFloat blur, CGFloat yOff, CGFloat alpha) {
    [NSGraphicsContext saveGraphicsState];
    NSShadow *sh = [[NSShadow alloc] init];
    sh.shadowOffset = NSMakeSize(0, yOff);
    sh.shadowBlurRadius = blur;
    sh.shadowColor = [NSColor colorWithWhite:0.0 alpha:alpha];
    [sh set];
    DrawRoundedRect(rect, radius, NSColor.whiteColor);
    [NSGraphicsContext restoreGraphicsState];
}

// MARK: - Main icon drawing

static void DrawGeneratedIconAtSize(CGFloat sz, NSString *outputPath) {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(sz, sz)];
    [image lockFocus];

    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);

    CGFloat s = sz;
    CGFloat p = s / 1024.0;  // proportion

    // =============================================
    // 1. Background squircle
    // =============================================
    NSRect bg = NSMakeRect(0, 0, s, s);
    CGFloat bgRadius = s * 0.22;

    [NSGraphicsContext saveGraphicsState];
    NSShadow *bgShadow = [[NSShadow alloc] init];
    bgShadow.shadowOffset = NSMakeSize(0, -s * 0.008);
    bgShadow.shadowBlurRadius = s * 0.05;
    bgShadow.shadowColor = [NSColor colorWithWhite:0.0 alpha:0.22];
    [bgShadow set];

    // Warm amber gradient (#C9802E → #965A1C → #6B3F0E)
    NSGradient *bgGrad = [[NSGradient alloc] initWithColorsAndLocations:
        [NSColor colorWithRed:0.78 green:0.49 blue:0.16 alpha:1.0], 0.0,
        [NSColor colorWithRed:0.62 green:0.37 blue:0.11 alpha:1.0], 0.55,
        [NSColor colorWithRed:0.45 green:0.26 blue:0.07 alpha:1.0], 1.0,
        nil
    ];
    DrawGradientRounded(bg, bgRadius, bgGrad, 270);
    [NSGraphicsContext restoreGraphicsState];

    // =============================================
    // 2. Subtle inner sheen (glass highlight)
    // =============================================
    NSRect sheenR = NSMakeRect(s * 0.07, s * 0.78, s * 0.86, s * 0.22);
    NSBezierPath *sheenPath = SquirclePath(sheenR, bgRadius * 0.5);
    NSGradient *sheenGrad = [[NSGradient alloc] initWithColorsAndLocations:
        [NSColor colorWithWhite:1.0 alpha:0.14], 0.0,
        [NSColor colorWithWhite:1.0 alpha:0.0], 1.0, nil
    ];
    [sheenGrad drawInBezierPath:sheenPath angle:270];

    // =============================================
    // 3. Bottom highlight (subtle reflection)
    // =============================================
    NSRect reflectR = NSMakeRect(s * 0.12, s * 0.02, s * 0.76, s * 0.10);
    NSBezierPath *reflectPath = SquirclePath(reflectR, s * 0.04);
    NSGradient *reflectGrad = [[NSGradient alloc] initWithColorsAndLocations:
        [NSColor colorWithWhite:1.0 alpha:0.08], 0.0,
        [NSColor colorWithWhite:1.0 alpha:0.0], 1.0, nil
    ];
    [reflectGrad drawInBezierPath:reflectPath angle:90];

    // =============================================
    // 4. Open book
    // =============================================
    CGFloat bookW = s * 0.56;
    CGFloat bookH = s * 0.48;
    CGFloat bookX = (s - bookW) / 2.0;
    CGFloat bookY = s * 0.22;
    CGFloat pageR = s * 0.04;

    // Book shadow
    NSRect bookShadowR = NSMakeRect(bookX, bookY - s * 0.01, bookW, bookH + s * 0.02);
    [NSGraphicsContext saveGraphicsState];
    NSShadow *bookSh = [[NSShadow alloc] init];
    bookSh.shadowOffset = NSMakeSize(0, -s * 0.012);
    bookSh.shadowBlurRadius = s * 0.035;
    bookSh.shadowColor = [NSColor colorWithWhite:0.0 alpha:0.28];
    [bookSh set];
    DrawRoundedRect(bookShadowR, pageR, NSColor.whiteColor);
    [NSGraphicsContext restoreGraphicsState];

    // Left page — warm white
    CGFloat pageW = bookW * 0.475;
    CGFloat pageGap = bookW * 0.05;       // center gap
    CGFloat pageY = bookY;
    CGFloat pageH = bookH;

    NSRect leftPageR = NSMakeRect(bookX, pageY, pageW, pageH);
    NSBezierPath *leftPage = SquirclePath(leftPageR, pageR);
    [[NSColor colorWithRed:0.99 green:0.97 blue:0.93 alpha:1.0] setFill];  // warm cream
    [leftPage fill];

    // Right page
    NSRect rightPageR = NSMakeRect(bookX + pageW + pageGap, pageY, pageW, pageH);
    NSBezierPath *rightPage = SquirclePath(rightPageR, pageR);
    [[NSColor colorWithRed:0.99 green:0.97 blue:0.93 alpha:1.0] setFill];
    [rightPage fill];

    // Page edge shadow (left page, right edge)
    NSRect leftEdgeR = NSMakeRect(NSMaxX(leftPageR) - pageR * 0.5, pageY, pageR, pageH);
    DrawRoundedRect(leftEdgeR, pageR * 0.3,
        [NSColor colorWithWhite:0.0 alpha:0.04]);

    // Page edge shadow (right page, left edge)
    NSRect rightEdgeR = NSMakeRect(rightPageR.origin.x, pageY, pageR * 0.5, pageH);
    DrawRoundedRect(rightEdgeR, pageR * 0.3,
        [NSColor colorWithWhite:0.0 alpha:0.04]);

    // =============================================
    // 5. Spine crease
    // =============================================
    CGFloat spineX = bookX + pageW + pageGap * 0.5 - s * 0.004;
    NSBezierPath *spine = [NSBezierPath bezierPath];
    spine.lineWidth = MAX(1.8, s * 0.006);
    [spine moveToPoint:NSMakePoint(spineX, pageY + pageR * 0.6)];
    [spine lineToPoint:NSMakePoint(spineX, NSMaxY(leftPageR) - pageR * 0.6)];
    [[NSColor colorWithRed:0.35 green:0.25 blue:0.15 alpha:0.45] setStroke];
    [spine stroke];

    // =============================================
    // 6. Text lines on left page
    // =============================================
    CGFloat lineColor[4] = {0.25, 0.20, 0.14, 0.30};
    NSColor *lineClr = [NSColor colorWithRed:lineColor[0] green:lineColor[1] blue:lineColor[2] alpha:lineColor[3]];
    [lineClr setStroke];

    CGFloat textStartX = bookX + s * 0.035;
    CGFloat textEndX = bookX + pageW - s * 0.025;
    CGFloat textCenterX = (textStartX + textEndX) / 2.0;
    CGFloat lineBaseY = pageY + s * 0.08;
    CGFloat lineGap = s * 0.036;
    CGFloat lineThick = MAX(1.2, s * 0.004);

    // Left page lines (shorter lines at bottom to suggest paragraph structure)
    CGFloat lineLengths[5] = {0.60, 0.55, 0.50, 0.45, 0.38};
    for (int i = 0; i < 5; i++) {
        CGFloat lenFrac = lineLengths[i];
        CGFloat lineW = (textEndX - textStartX) * lenFrac;
        CGFloat lineX = textStartX + (textEndX - textStartX - lineW) * 0.5;
        CGFloat y = lineBaseY + i * lineGap;
        NSBezierPath *ln = [NSBezierPath bezierPath];
        ln.lineWidth = lineThick;
        ln.lineCapStyle = NSLineCapStyleRound;
        [ln moveToPoint:NSMakePoint(lineX, y)];
        [ln lineToPoint:NSMakePoint(lineX + lineW, y)];
        [ln stroke];
    }

    // A longer "title" line near the top
    CGFloat titleLineY = lineBaseY + 6 * lineGap + s * 0.02;
    NSBezierPath *titleLine = [NSBezierPath bezierPath];
    titleLine.lineWidth = lineThick * 1.5;
    titleLine.lineCapStyle = NSLineCapStyleRound;
    CGFloat titleW = (textEndX - textStartX) * 0.45;
    [titleLine moveToPoint:NSMakePoint(textCenterX - titleW * 0.5, titleLineY)];
    [titleLine lineToPoint:NSMakePoint(textCenterX + titleW * 0.5, titleLineY)];
    [[[NSColor colorWithRed:0.25 green:0.20 blue:0.14 alpha:0.5] colorWithAlphaComponent:0.35] setStroke];
    [titleLine stroke];

    // =============================================
    // 7. Text lines on right page
    // =============================================
    CGFloat rTextStartX = rightPageR.origin.x + s * 0.025;
    CGFloat rTextEndX = NSMaxX(rightPageR) - s * 0.035;
    CGFloat rTextCenterX = (rTextStartX + rTextEndX) / 2.0;

    CGFloat rLineLengths[5] = {0.58, 0.62, 0.52, 0.56, 0.42};
    for (int i = 0; i < 5; i++) {
        CGFloat lenFrac = rLineLengths[i];
        CGFloat lineW = (rTextEndX - rTextStartX) * lenFrac;
        CGFloat lineX = rTextStartX + (rTextEndX - rTextStartX - lineW) * 0.5;
        CGFloat y = lineBaseY + i * lineGap;
        NSBezierPath *ln = [NSBezierPath bezierPath];
        ln.lineWidth = lineThick;
        ln.lineCapStyle = NSLineCapStyleRound;
        [ln moveToPoint:NSMakePoint(lineX, y)];
        [ln lineToPoint:NSMakePoint(lineX + lineW, y)];
        [ln stroke];
    }

    // Right page title
    NSBezierPath *rTitleLine = [NSBezierPath bezierPath];
    rTitleLine.lineWidth = lineThick * 1.5;
    rTitleLine.lineCapStyle = NSLineCapStyleRound;
    CGFloat rTitleW = (rTextEndX - rTextStartX) * 0.40;
    [rTitleLine moveToPoint:NSMakePoint(rTextCenterX - rTitleW * 0.5, titleLineY)];
    [rTitleLine lineToPoint:NSMakePoint(rTextCenterX + rTitleW * 0.5, titleLineY)];
    [[[NSColor colorWithRed:0.25 green:0.20 blue:0.14 alpha:0.5] colorWithAlphaComponent:0.32] setStroke];
    [rTitleLine stroke];

    // =============================================
    // 8. Bookmark ribbon
    // =============================================
    CGFloat ribbonX = bookX + bookW * 0.5;
    CGFloat ribbonTop = NSMaxY(leftPageR) - s * 0.01;
    CGFloat ribbonBot = ribbonTop + s * 0.20;
    CGFloat ribbonW = s * 0.028;

    // Ribbon tail triangle
    NSBezierPath *ribbon = [NSBezierPath bezierPath];
    [ribbon moveToPoint:NSMakePoint(ribbonX - ribbonW, ribbonTop)];
    [ribbon lineToPoint:NSMakePoint(ribbonX + ribbonW, ribbonTop)];
    [ribbon lineToPoint:NSMakePoint(ribbonX + ribbonW, ribbonBot)];
    [ribbon lineToPoint:NSMakePoint(ribbonX, ribbonBot - s * 0.018)];  // V-notch
    [ribbon lineToPoint:NSMakePoint(ribbonX - ribbonW, ribbonBot)];
    [ribbon closePath];

    NSGradient *ribbonGrad = [[NSGradient alloc] initWithColorsAndLocations:
        [NSColor colorWithRed:0.88 green:0.52 blue:0.15 alpha:1.0], 0.0,  // warm amber
        [NSColor colorWithRed:0.75 green:0.42 blue:0.10 alpha:1.0], 1.0,
        nil
    ];
    [ribbonGrad drawInBezierPath:ribbon angle:0];

    // =============================================
    // 9. "E" letter (light, integrated into the book)
    // =============================================
    CGFloat eSize = s * 0.09;
    NSDictionary *eAttrs = @{
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Bold" size:eSize] ?: [NSFont boldSystemFontOfSize:eSize],
        NSForegroundColorAttributeName: [NSColor colorWithRed:0.78 green:0.49 blue:0.16 alpha:1.0]
    };
    NSString *eStr = @"E";
    NSSize eSz = [eStr sizeWithAttributes:eAttrs];
    CGFloat eX = textCenterX - eSz.width * 0.5;
    CGFloat eY = titleLineY + s * 0.018;
    [eStr drawAtPoint:NSMakePoint(eX, eY) withAttributes:eAttrs];

    // Right page "Pub" text (faint)
    CGFloat pubSize = s * 0.028;
    NSDictionary *pubAttrs = @{
        NSFontAttributeName: [NSFont fontWithName:@"HelveticaNeue-Medium" size:pubSize] ?: [NSFont systemFontOfSize:pubSize],
        NSForegroundColorAttributeName: [NSColor colorWithRed:0.45 green:0.35 blue:0.22 alpha:0.35]
    };
    NSString *pubStr = @"Pub";
    NSSize pubSz = [pubStr sizeWithAttributes:pubAttrs];
    CGFloat pubX = rTextCenterX - pubSz.width * 0.5;
    CGFloat pubY = titleLineY + s * 0.020;
    [pubStr drawAtPoint:NSMakePoint(pubX, pubY) withAttributes:pubAttrs];

    // =============================================
    // 10. Sparkle / magic star (top-right area)
    // =============================================
    CGFloat starX = bookX + bookW * 0.88;
    CGFloat starY = NSMaxY(leftPageR) + s * 0.04;
    CGFloat starR = s * 0.035;

    // Glow behind the star
    NSRect glowR = NSMakeRect(starX - starR * 2.0, starY - starR * 2.0, starR * 4.0, starR * 4.0);
    NSGradient *glowGrad = [[NSGradient alloc] initWithColorsAndLocations:
        [NSColor colorWithRed:1.0 green:0.85 blue:0.45 alpha:0.25], 0.0,
        [NSColor colorWithRed:1.0 green:0.85 blue:0.45 alpha:0.0], 1.0, nil
    ];
    [glowGrad drawInBezierPath:SquirclePath(glowR, starR * 2.0) angle:0];

    // 4-pointed sparkle
    NSBezierPath *sparkle = [NSBezierPath bezierPath];
    CGFloat sp = starR;
    [sparkle moveToPoint:NSMakePoint(starX, starY + sp * 1.6)];
    [sparkle lineToPoint:NSMakePoint(starX + sp * 0.35, starY + sp * 0.35)];
    [sparkle lineToPoint:NSMakePoint(starX + sp * 1.6, starY)];
    [sparkle lineToPoint:NSMakePoint(starX + sp * 0.35, starY - sp * 0.35)];
    [sparkle lineToPoint:NSMakePoint(starX, starY - sp * 1.6)];
    [sparkle lineToPoint:NSMakePoint(starX - sp * 0.35, starY - sp * 0.35)];
    [sparkle lineToPoint:NSMakePoint(starX - sp * 1.6, starY)];
    [sparkle lineToPoint:NSMakePoint(starX - sp * 0.35, starY + sp * 0.35)];
    [sparkle closePath];

    [[NSColor colorWithRed:1.0 green:0.90 blue:0.55 alpha:1.0] setFill];
    [sparkle fill];

    // Diamond center of sparkle
    NSRect diamondR = NSMakeRect(starX - sp * 0.25, starY - sp * 0.25, sp * 0.5, sp * 0.5);
    DrawRoundedRect(diamondR, sp * 0.15, [NSColor colorWithRed:1.0 green:0.95 blue:0.80 alpha:1.0]);

    // =============================================
    // 11. Tiny sparkle dots
    // =============================================
    CGPoint dots[3] = {
        {starX - sp * 1.0, starY + sp * 1.8},
        {starX + sp * 1.3, starY - sp * 1.2},
        {starX - sp * 0.6, starY - sp * 2.0}
    };
    for (int i = 0; i < 3; i++) {
        NSRect dotR = NSMakeRect(dots[i].x - sp * 0.18, dots[i].y - sp * 0.18, sp * 0.36, sp * 0.36);
        DrawRoundedRect(dotR, sp * 0.18, [NSColor colorWithRed:1.0 green:0.92 blue:0.60 alpha:0.7]);
    }

    // =============================================
    // Output
    // =============================================
    [image unlockFocus];

    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    rep.size = NSMakeSize(sz, sz);
    NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    [pngData writeToFile:outputPath atomically:YES];
}

static void WritePNGFromImage(NSImage *image, CGFloat sz, NSString *outputPath) {
    CGImageRef cgImage = [image CGImageForProposedRect:NULL context:nil hints:nil];
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithCGImage:cgImage];
    rep.size = NSMakeSize(sz, sz);
    NSData *pngData = [rep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
    [pngData writeToFile:outputPath atomically:YES];
}

static void DrawImageIconAtSize(CGFloat sz, NSString *outputPath, NSString *sourcePath) {
    NSImage *source = [[NSImage alloc] initWithContentsOfFile:sourcePath];
    if (!source) {
        DrawGeneratedIconAtSize(sz, outputPath);
        return;
    }

    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(sz, sz)];
    [image lockFocus];

    [[NSColor clearColor] setFill];
    NSRectFill(NSMakeRect(0, 0, sz, sz));

    CGContextRef ctx = [[NSGraphicsContext currentContext] CGContext];
    CGContextSetInterpolationQuality(ctx, kCGInterpolationHigh);

    NSSize sourceSize = source.size;
    CGFloat sourceSide = MIN(sourceSize.width, sourceSize.height);

    // VS Code 的图标主体约占 80%+ 画布。当前 EasyPub 图标主体偏小，
    // 中心裁切到 87.5% 后再铺满，可以得到相近的视觉尺寸和留白。
    CGFloat cropSide = sourceSide * 0.875;
    NSRect crop = NSMakeRect((sourceSize.width - cropSide) / 2.0,
                             (sourceSize.height - cropSide) / 2.0,
                             cropSide,
                             cropSide);
    NSRect dest = NSMakeRect(0, 0, sz, sz);
    NSDictionary *hints = @{ NSImageHintInterpolation: @(NSImageInterpolationHigh) };
    [source drawInRect:dest
              fromRect:crop
             operation:NSCompositingOperationSourceOver
              fraction:1.0
        respectFlipped:NO
                 hints:hints];

    [image unlockFocus];
    WritePNGFromImage(image, sz, outputPath);
}

// MARK: - ICNS writer

static void AppendU32(NSMutableData *data, uint32_t value) {
    uint32_t be = CFSwapInt32HostToBig(value);
    [data appendBytes:&be length:sizeof(be)];
}

static void WriteICNS(NSString *iconsetPath, NSString *outputPath) {
    NSArray<NSDictionary *> *entries = @[
        @{@"type": @"icp4", @"name": @"icon_16x16.png"},
        @{@"type": @"icp5", @"name": @"icon_32x32.png"},
        @{@"type": @"icp6", @"name": @"icon_32x32@2x.png"},
        @{@"type": @"ic07", @"name": @"icon_128x128.png"},
        @{@"type": @"ic08", @"name": @"icon_256x256.png"},
        @{@"type": @"ic09", @"name": @"icon_512x512.png"},
        @{@"type": @"ic10", @"name": @"icon_512x512@2x.png"}
    ];

    NSMutableData *body = [NSMutableData data];
    for (NSDictionary *entry in entries) {
        NSString *type = entry[@"type"];
        NSString *path = [iconsetPath stringByAppendingPathComponent:entry[@"name"]];
        NSData *pngData = [NSData dataWithContentsOfFile:path];
        if (!pngData) continue;

        const char *typeBytes = [type UTF8String];
        [body appendBytes:typeBytes length:4];
        AppendU32(body, (uint32_t)(8 + pngData.length));
        [body appendData:pngData];
    }

    NSMutableData *icns = [NSMutableData data];
    const char header[] = {'i', 'c', 'n', 's'};
    [icns appendBytes:header length:4];
    AppendU32(icns, (uint32_t)(8 + body.length));
    [icns appendData:body];
    [icns writeToFile:outputPath atomically:YES];
}

// MARK: - Main

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        if (argc < 2) return 1;

        NSString *outputRoot = [NSString stringWithUTF8String:argv[1]];
        NSString *sourcePath = argc >= 4 ? [NSString stringWithUTF8String:argv[3]] : nil;
        NSFileManager *fm = [NSFileManager defaultManager];
        [fm createDirectoryAtPath:outputRoot withIntermediateDirectories:YES attributes:nil error:nil];

        NSArray<NSDictionary *> *targets = @[
            @{@"name": @"icon_16x16.png", @"size": @16},
            @{@"name": @"icon_16x16@2x.png", @"size": @32},
            @{@"name": @"icon_32x32.png", @"size": @32},
            @{@"name": @"icon_32x32@2x.png", @"size": @64},
            @{@"name": @"icon_128x128.png", @"size": @128},
            @{@"name": @"icon_128x128@2x.png", @"size": @256},
            @{@"name": @"icon_256x256.png", @"size": @256},
            @{@"name": @"icon_256x256@2x.png", @"size": @512},
            @{@"name": @"icon_512x512.png", @"size": @512},
            @{@"name": @"icon_512x512@2x.png", @"size": @1024}
        ];

        for (NSDictionary *target in targets) {
            @autoreleasepool {
                NSString *path = [outputRoot stringByAppendingPathComponent:target[@"name"]];
                if (sourcePath.length > 0) {
                    DrawImageIconAtSize([target[@"size"] doubleValue], path, sourcePath);
                } else {
                    DrawGeneratedIconAtSize([target[@"size"] doubleValue], path);
                }
            }
        }

        if (argc >= 3) {
            NSString *icnsPath = [NSString stringWithUTF8String:argv[2]];
            WriteICNS(outputRoot, icnsPath);
        }
    }
    return 0;
}
