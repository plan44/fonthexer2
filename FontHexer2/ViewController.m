//
//  ViewController.m
//  FontHexer2
//
//  Created by Lukas Zeller on 15.12.2023.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Set up the font menu with available fonts
  NSArray *fontFamilyNames = [NSFontManager.sharedFontManager availableFontFamilies];
  [self.fontPopup addItemsWithTitles:fontFamilyNames];

  [self updateLabelFont:nil];
}


- (void)setRepresentedObject:(id)representedObject
{
  [super setRepresentedObject:representedObject];

  // Update the view, if already loaded.
}


- (IBAction)showFontPicker:(id)sender
{
  NSFontPanel *fontPanel = [NSFontPanel sharedFontPanel];
  [fontPanel setDelegate:self];
  [fontPanel makeKeyAndOrderFront:nil];
}



- (void)changeFont:(NSFontManager*)fontManager
{
  NSFont *selectedFont = [fontManager convertFont:[fontManager selectedFont]];

  // Apply the selected font to your label or perform other actions
  [self.outputLabel setFont:selectedFont];
}


- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fontPanel
{
  return NSFontPanelModeMaskFace|NSFontPanelModeMaskCollection;
}



- (BOOL)changeAttributes:(id)sender
{
  return YES;
}



- (IBAction)fontSizeChanged:(id)sender
{
  // Get the slider value
  [self updateLabelFont: sender];
}



- (IBAction)updateLabelFont:(id)sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];

  NSString *fontName = [self.fontPopup titleOfSelectedItem];
  CGFloat fontSize = [self.fontSizeSlider floatValue]; // Use slider's value

  NSFont *newFont = [NSFont fontWithName:fontName size:fontSize];

  if ([self.boldCheckbox state] == NSControlStateValueOn) {
      newFont = [fontManager convertFont:newFont toHaveTrait:NSBoldFontMask];
  }

  if ([self.italicCheckbox state] == NSControlStateValueOn) {
      newFont = [fontManager convertFont:newFont toHaveTrait:NSItalicFontMask];
  }

  [self.outputLabel setFont:newFont];
}


- (IBAction)samplePixels:(id)sender
{
  [self sampleColorsInGridCells];
}


// MARK: sample

#if GUGUS
- (void)sampleColorsInGridCells {
    // Get the bounds of the view
    NSRect bounds = [self bounds];

    // Get the ViewController
    ViewController *viewController = (ViewController *)self.window.contentViewController;

    // Create the bitmap representation
    NSImage *image = [[NSImage alloc] initWithSize:self.label.bounds.size];

    // Create a graphics context with a scale of 1.0
    NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:[[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]]];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:context];
    CGContextRef ctx = [context CGContext];
    CGContextScaleCTM(ctx, 1.0, 1.0);

    // Render the label into the context
    [self.label.layer renderInContext:ctx];

    [NSGraphicsContext restoreGraphicsState];

    // Create the bitmap representation from the graphics context
    NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithCGImage:[context.CGContext
                                                                             createCGImage:[context.bitmapImageRep CGImage]
                                                                             fromRect:[context.bitmapImageRep rect]]];

    // Iterate through each cell and sample the color at the center
    for (NSInteger row = 0; row < numRows; row++) {
        for (NSInteger col = 0; col < numCols; col++) {
            CGFloat x = bounds.origin.x + (col + 0.5) * cellWidth + self.originX;
            CGFloat y = bounds.origin.y + (row + 0.5) * cellHeight + self.originY;

            // Check if the color at the center of the cell is dark
            BOOL isDarkColor = [viewController isColorAtPointDark:NSMakePoint(x, y) inBitmap:bitmapRep];

            // Do something with the result (e.g., print it)
            NSLog(@"Is color at cell (%ld, %ld) dark? %@", (long)row, (long)col, isDarkColor ? @"YES" : @"NO");
        }
    }
}
#endif



- (void)sampleColorsInGridCells
{
  // Get the bounds of the view
  NSRect bounds = [self.samplingGrid bounds];

  NSInteger numRows = 10;
  NSInteger numCols = 10;

  // Create the bitmap representation
  NSBitmapImageRep *bitmapRep;

  // Create a graphics context with a scale of 1.0
  NSGraphicsContext *context = [NSGraphicsContext graphicsContextWithBitmapImageRep:[[NSBitmapImageRep alloc] initWithData:[NSData data]]];
  [NSGraphicsContext saveGraphicsState];
  [NSGraphicsContext setCurrentContext:context];
  CGContextRef ctx = [context CGContext];
  CGContextScaleCTM(ctx, 1.0, 1.0);

  // Render the label into the context
  [self.outputLabel.layer renderInContext:ctx];

  [NSGraphicsContext restoreGraphicsState];

  // Retrieve the bitmap representation from the context
  bitmapRep = [context.bitmapImageRep copy];

//  // Get the content of the label's layer as an image
//  NSImage *image = [[NSImage alloc] initWithSize:self.outputLabel.bounds.size];
//
//  [image lockFocus];
//  [self.outputLabel.layer renderInContext:[NSGraphicsContext currentContext].CGContext];
//  [image unlockFocus];
//
//  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];
//
//  // Log the contents of the image (debugging purposes)
////  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
////  NSString *documentsDirectory = [paths firstObject];
////  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"debug_image.png"];
////  NSData *pngData = [bitmapRep representationUsingType:NSPNGFileType properties:@{}];
////  [pngData writeToFile:filePath atomically:YES];


  // Iterate through each cell and sample the color at the center
  NSMutableString* chartext = [NSMutableString string];
  for (NSInteger row = 0; row < numRows; row++) {
    for (NSInteger col = 0; col < numCols; col++) {
      CGFloat x = bounds.origin.x + ((CGFloat)col + 0.5) * self.samplingGrid.cellSize + self.samplingGrid.originX;
      CGFloat y = bounds.origin.y + ((CGFloat)row + 0.5) * self.samplingGrid.cellSize + self.samplingGrid.originY;

      // Sample the color at the center of the cell
      BOOL isDark = [self isColorAtPointDark:NSMakePoint(x, y) inBitmap:bitmapRep];
      [chartext appendString:isDark ? @"X" : @"."];

      // Do something with the sampled color (e.g., print it)
      NSLog(@"Dark at cell (%ld, %ld) coord (%ld, %ld): %d", (long)row, (long)col, (long)x, (long)y, isDark);

    }
    [chartext appendString:@"\n"];
  }
  NSLog(@"Pixels:\n%@\n",chartext);
}


- (BOOL)isColorAtPointDark:(NSPoint)point inBitmap:(NSBitmapImageRep *)bitmapRep
{
  // Sample the color at the specified point from the image
  // Adjust the y-coordinate to match the image's coordinate system
  CGFloat h = bitmapRep.size.height;
  point.y = h - point.y;
  NSLog(@"Smapling at bitmap coord (%ld, %ld) - bitmap size (%ld, %ld)", (long)point.x, (long)point.y, (long)bitmapRep.size.width, (long)bitmapRep.size.height);

  // Sample the color at the specified point from the existing bitmap
  NSColor *color = [bitmapRep colorAtX:point.x y:point.y];

  // Convert the color to the device RGB color space
  NSColorSpace *pixelColorSpace = [NSColorSpace genericGrayColorSpace];
  NSColor *grayColor = [color colorUsingColorSpace:pixelColorSpace];

  CGFloat intensity = grayColor.whiteComponent;

  return intensity<0.5;
}

@end
