//
//  ScreenWindow.m
//  ScreenPicker
//
//  Created by durian on 3/26/13.
//  Copyright (c) 2013 durian. All rights reserved.
//

#import "ScreenPickerWindow.h"
#import "ScreenPickerView.h"

@implementation ScreenPickerWindow

- (void)dealloc {
    if (imageRef) {
        CGImageRelease(imageRef);
        imageRef = NULL;
    }
}

- (id)initWithContentRect:(NSRect)contentRect
                styleMask:(NSUInteger)windowStyle
                  backing:(NSBackingStoreType)bufferingType
                    defer:(BOOL)deferCreation
{
    self = [super initWithContentRect:contentRect styleMask:windowStyle backing:bufferingType defer:deferCreation];
    if (self) {
        [self setOpaque:NO];
        [self setBackgroundColor:[NSColor clearColor]];
        [self setLevel:NSPopUpMenuWindowLevel];
        [self setIgnoresMouseEvents:NO];
        
        ScreenPickerView *captureView = [[ScreenPickerView alloc] initWithFrame:self.frame];
        [self setContentView:captureView];
    }
    return self;
}

- (void)mouseMoved:(NSEvent *)event
{
    NSPoint point = [NSEvent mouseLocation];
//    NSLog(@"%s (%.1f, %1.f)", __PRETTY_FUNCTION__, p.x, p.y);

    uint32_t count = 0;
    CGDirectDisplayID display;
    if (CGGetDisplaysWithPoint(NSPointToCGPoint(point), 1, &display, &count) != kCGErrorSuccess)
    {
        return;
    }
    
    CGFloat captureSize = self.frame.size.width / 7;
    NSRect screenFrame = [[NSScreen mainScreen] frame];
    CGFloat x = floor(point.x) - floor(captureSize / 2);
    CGFloat y = screenFrame.size.height - floor(point.y) - floor(captureSize / 2);
    
    CGWindowID windowID = (CGWindowID)[self windowNumber];
    
    if (imageRef) {
        CGImageRelease(imageRef);
        imageRef = NULL;
    }
    imageRef = CGWindowListCreateImage(CGRectMake(x, y, captureSize, captureSize), kCGWindowListOptionOnScreenBelowWindow, windowID, kCGWindowImageNominalResolution);
        
    NSImage *image = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
    
    if (imageRef == NULL) {
        return;
    }
    
    if ([_delegate respondsToSelector:@selector(window:moveToPoint:withImage:)]) {
        [_delegate window:self moveToPoint:point withImage:image];
    }
    
    [self setFrameOrigin:NSMakePoint(floor(point.x) - floor(self.frame.size.width / 2), floor(point.y) - floor(self.frame.size.height / 2))];
    
    ScreenPickerView *captureView = (ScreenPickerView *)self.contentView;
    [captureView setImageRef:imageRef];
    [captureView setNeedsDisplay:YES];
    
    // 设置captureView的color属性
    captureView.color = [self getColorInCenter];
    
    [super mouseMoved:event];
}

- (NSColor *)getColorInCenter {
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    CGFloat centerX = bitmapImageRep.size.width / 2;
    CGFloat centerY = bitmapImageRep.size.height / 2;
    NSColor *color = [bitmapImageRep colorAtX:centerX y:centerY];
    
    return color;
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSLog(@"sco-log: mouseDown");
    
    NSBitmapImageRep *bitmapImageRep = [[NSBitmapImageRep alloc] initWithCGImage:imageRef];
    CGFloat centerX = bitmapImageRep.size.width / 2;
    CGFloat centerY = bitmapImageRep.size.height / 2;
    NSColor *color = [bitmapImageRep colorAtX:centerX y:centerY];
    
    NSLog(@"sco-log: ScreenPickerWindow selected color:%@", color);
    
    // @todo 这里将设置的color传回
    @try {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ScoColorPicked" object:color];
    } @catch (NSException *exception) {
        NSLog(@"sco-log: ScreenPickerWindow postNotificationName ScoColorPicked exception");
    } @finally {
        NSLog(@"sco-log: ScreenPickerWindow postNotificationName ScoColorPicked finally");
    }
    
    NSPoint p = [NSEvent mouseLocation];
    NSRect f = [self frame];
    if (NSPointInRect(p, f)) {
        NSLog(@"sco-log: mouseDown");
        [self orderOut:self];
        
        if ([_delegate respondsToSelector:@selector(window:clickedAtPoint:withColor:)]) {
            NSColor *color = [self getColorInCenter];
            
            [_delegate window:self clickedAtPoint:p withColor:color];
        }
    }
}

- (BOOL)canBecomeKeyWindow {
    return YES;
}

@end
