//
//  DraggablePointView.m
//  FontHexer2
//
//  Created by Lukas Zeller on 20.12.2023.
//

#import "DraggablePointView.h"
#import "GridOverlayView.h"

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@implementation DraggablePointView

- (instancetype)initWithFrame:(NSRect)frame
{
  self = [super initWithFrame:frame];
  if (self) {
    // Set initial appearance
    [self setWantsLayer:YES];
    [self.layer setBackgroundColor:[NSColor.redColor CGColor]];
    [self.layer setCornerRadius:frame.size.width / 2.0];
  }
  return self;
}

- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];
  // Custom drawing code if needed
}


- (void)mouseDown:(NSEvent *)event
{
  [self.superview.window makeFirstResponder:self];
}


- (void)mouseDragged:(NSEvent *)event
{
  NSPoint eventLocation = [event locationInWindow];
  NSPoint localPoint = [self convertPoint:eventLocation fromView:nil];

  // Update the frame of the DraggablePointView
  [NSAnimationContext runAnimationGroup:^(NSAnimationContext *context) {
    [context setDuration:0.1];
    [self setFrameOrigin:NSMakePoint(localPoint.x - self.frame.size.width / 2.0, localPoint.y - self.frame.size.height / 2.0)];

    // Update the origin coordinates in the GridOverlayView
    GridOverlayView *gridView = (GridOverlayView *)self.superview;
    gridView.originX = self.frame.origin.x;
    gridView.originY = self.frame.origin.y;

    [gridView setNeedsDisplay:YES];
  } completionHandler:nil];
}

@end
