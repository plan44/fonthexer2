//
//  GridOverlayView.m
//  FontHexer2
//
//  Created by Lukas Zeller on 20.12.2023.
//

#import "GridOverlayView.h"

@implementation GridOverlayView


- (instancetype)initWithFrame:(NSRect)frameRect
{
  self = [super initWithFrame:frameRect];
  if (self) {
    [self setWantsLayer:YES];
    // ... existing initialization code ...
  }
  return self;
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

  // Define the number of rows and columns in the grid
  NSInteger numRows = 10;
  NSInteger numCols = 10;

  // Calculate the width and height of each cell in the grid
  CGFloat cellWidth = bounds.size.width / numCols;
  CGFloat cellHeight = bounds.size.height / numRows;

  // Draw horizontal grid lines
  for (NSInteger row = 1; row < numRows; row++) {
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(bounds.origin.x, bounds.origin.y + row * cellHeight)];
    [line lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, bounds.origin.y + row * cellHeight)];
    [line setLineWidth:lineWidth];
    [line stroke];
  }

  // Draw vertical grid lines
  for (NSInteger col = 1; col < numCols; col++) {
    NSBezierPath *line = [NSBezierPath bezierPath];
    [line moveToPoint:NSMakePoint(bounds.origin.x + col * cellWidth, bounds.origin.y)];
    [line lineToPoint:NSMakePoint(bounds.origin.x + col * cellWidth, bounds.origin.y + bounds.size.height)];
    [line setLineWidth:lineWidth];
    [line stroke];
  }

  // Calculate the position of the draggable point
  NSPoint origin = NSMakePoint(self.bounds.origin.x + self.originX, self.bounds.origin.y + self.originY);

  // Position the draggable point at the calculated position
  CGFloat pointSize = 10.0;
  if (!self.draggablePoint) {
      self.draggablePoint = [[DraggablePointView alloc] initWithFrame:NSMakeRect(0, 0, pointSize, pointSize)];
      [self addSubview:self.draggablePoint];
  }
  [self.draggablePoint setFrame:NSMakeRect(origin.x - pointSize / 2.0, origin.y - pointSize / 2.0, pointSize, pointSize)];
}

@end
