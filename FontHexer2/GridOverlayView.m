//
//  GridOverlayView.m
//  FontHexer2
//
//  Created by Lukas Zeller on 20.12.2023.
//

#import "GridOverlayView.h"

@implementation GridOverlayView


- (instancetype)initWithCoder:(NSCoder *)coder
{
  self = [super initWithCoder:coder];
  if (self) {
    [self commonInitialization];
  }
  return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if (self) {
    [self commonInitialization];
  }
  return self;
}

- (void)commonInitialization
{
  [self setWantsLayer:YES];
  self.cellSize = 33;
  self.originX = 0;
  self.originY = 0;
}


- (void)mouseDown:(NSEvent *)event {
    self.initialMouseLocation = [event locationInWindow];
}

- (void)mouseDragged:(NSEvent *)event {
    NSPoint currentMouseLocation = [event locationInWindow];
    CGFloat deltaX = currentMouseLocation.x - self.initialMouseLocation.x;
    CGFloat deltaY = currentMouseLocation.y - self.initialMouseLocation.y;

    self.originX += deltaX;
    self.originY += deltaY;

    self.initialMouseLocation = currentMouseLocation;

    [self setNeedsDisplay:YES];
}



- (void)drawRect:(NSRect)dirtyRect
{
  [super drawRect:dirtyRect];

  // Set the background color of the view to clear
  [[NSColor clearColor] setFill];
  NSRectFill(dirtyRect);

  // Set the color and thickness of the grid lines
  [[NSColor grayColor] setStroke];
  CGFloat lineWidth = 1.0;

  // Get the bounds of the view
  NSRect bounds = [self bounds];

  // Calculate the number of rows and columns based on the cell size and offset
  NSInteger numRows = (bounds.size.height - fabs(self.originY)) / self.cellSize;
  NSInteger numCols = (bounds.size.width - fabs(self.originX)) / self.cellSize;

  // Draw horizontal grid lines
  for (NSInteger row = 0; row <= numRows; row++) {
      NSBezierPath *line = [NSBezierPath bezierPath];
      CGFloat y = bounds.origin.y + row * self.cellSize + self.originY;
      [line moveToPoint:NSMakePoint(bounds.origin.x, y)];
      [line lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, y)];
      [line setLineWidth:lineWidth];
      [line stroke];
  }

  // Draw vertical grid lines
  for (NSInteger col = 0; col <= numCols; col++) {
      NSBezierPath *line = [NSBezierPath bezierPath];
      CGFloat x = bounds.origin.x + col * self.cellSize + self.originX;
      [line moveToPoint:NSMakePoint(x, bounds.origin.y)];
      [line lineToPoint:NSMakePoint(x, bounds.origin.y + bounds.size.height)];
      [line setLineWidth:lineWidth];
      [line stroke];
  }

  // Draw the origin point
  NSBezierPath *originPath = [NSBezierPath bezierPath];
  CGFloat originX = bounds.origin.x + self.originX;
  CGFloat originY = bounds.origin.y + self.originY;
  CGFloat originSize = 10.0;
  [originPath appendBezierPathWithArcWithCenter:NSMakePoint(originX, originY) radius:originSize / 2.0 startAngle:0.0 endAngle:360.0];
  [[NSColor redColor] setFill];  // Set the fill color (you can change this color)
  [originPath fill];
}


@end
