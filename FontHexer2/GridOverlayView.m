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

static CGFloat const cellWidth = 40.0;
static CGFloat const cellHeight = 40.0;

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];

    // Set the background color of the view to clear
    [[NSColor clearColor] setFill];
    NSRectFill(dirtyRect);

    // Set the color and thickness of the grid lines
    [[NSColor grayColor] setStroke];
    CGFloat lineWidth = 1.0;

    // Get the bounds of the view
    NSRect bounds = [self bounds];

    // Calculate the number of rows and columns based on the cell size
    NSInteger numRows = bounds.size.height / cellHeight;
    NSInteger numCols = bounds.size.width / cellWidth;

    // Draw horizontal grid lines
    for (NSInteger row = 1; row < numRows; row++) {
        NSBezierPath *line = [NSBezierPath bezierPath];
        CGFloat y = bounds.origin.y + row * cellHeight - self.originY;
        [line moveToPoint:NSMakePoint(bounds.origin.x, y)];
        [line lineToPoint:NSMakePoint(bounds.origin.x + bounds.size.width, y)];
        [line setLineWidth:lineWidth];
        [line stroke];
    }

    // Draw vertical grid lines
    for (NSInteger col = 1; col < numCols; col++) {
        NSBezierPath *line = [NSBezierPath bezierPath];
        CGFloat x = bounds.origin.x + col * cellWidth - self.originX;
        [line moveToPoint:NSMakePoint(x, bounds.origin.y)];
        [line lineToPoint:NSMakePoint(x, bounds.origin.y + bounds.size.height)];
        [line setLineWidth:lineWidth];
        [line stroke];
    }

    // Calculate the position of the draggable point
    NSPoint origin = NSMakePoint(bounds.origin.x + self.originX, bounds.origin.y + self.originY);

    // Position the draggable point at the calculated position
    CGFloat pointSize = 10.0;
    if (!self.draggablePoint) {
        self.draggablePoint = [[DraggablePointView alloc] initWithFrame:NSMakeRect(0, 0, pointSize, pointSize)];
        [self addSubview:self.draggablePoint];
    }
    [self.draggablePoint setFrame:NSMakeRect(origin.x - pointSize / 2.0, origin.y - pointSize / 2.0, pointSize, pointSize)];
}


@end
