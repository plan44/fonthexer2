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
  NSArray* glyph = [self sampleColorsInGridCells];
  NSLog(@"Glyph with %ld cols", glyph.count);
}


// MARK: sample

- (NSArray*)sampleColorsInGridCells
{
  NSMutableArray* cols = [NSMutableArray array];

  // Get the bounds of the view
  NSRect bounds = [self.samplingGrid bounds];

  NSInteger numRows = (bounds.size.height-self.samplingGrid.originY)/self.samplingGrid.cellSize;
  NSInteger numCols = (bounds.size.width-self.samplingGrid.originX)/self.samplingGrid.cellSize;

  // Get the content of the label's layer as an image
  NSImage *image = [[NSImage alloc] initWithSize:self.outputLabel.bounds.size];
  [image lockFocus];
  [self.outputLabel.layer renderInContext:[NSGraphicsContext currentContext].CGContext];
  [image unlockFocus];

  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];

  // Log the contents of the image (debugging purposes)
//  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//  NSString *documentsDirectory = [paths firstObject];
//  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"debug_image.png"];
//  NSData *pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
//  [pngData writeToFile:filePath atomically:YES];

  // get the scaling, might be retina as we are rendering in the window context, apparently
  NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
  CGFloat scale = [mainWindow backingScaleFactor];

  // Iterate through each cell and sample the color at the center
  NSMutableString* chartext = [NSMutableString string];
  NSInteger glyphWidth = 0;
  NSInteger glyphHeight = 0;
  for (NSInteger col = 0; col < numCols; col++) {
    [chartext appendFormat:@"%02ld: ", (long)col];
    NSMutableArray* rowpixels = [NSMutableArray array];
    for (NSInteger row = 0; row < numRows; row++) {
      CGFloat x = bounds.origin.x + (((CGFloat)col + 0.5) * self.samplingGrid.cellSize + self.samplingGrid.originX) * scale;
      CGFloat y = bounds.origin.y + (((CGFloat)row + 0.5) * self.samplingGrid.cellSize + self.samplingGrid.originY) * scale;

      CGPoint pt = NSMakePoint(x, y);
      // Note: NO NEED to Adjust the y-coordinate, apparently bitmapRep is also in Core Graphics orientation
      //pt.y = bitmapRep.size.height*scale - pt.y;

      // Sample the color from the image
      BOOL isDark = [self isColorAtPointDark:pt inBitmap:bitmapRep];
      if (isDark) glyphWidth = col+1;
      if (isDark && row>=glyphHeight) glyphHeight = row+1;
      [chartext appendString:isDark ? @"X" : @"."];
      [rowpixels addObject:@(isDark)];

      // Do something with the sampled color (e.g., print it)
      NSLog(@"Dark at cell (%ld, %ld) coord (%ld, %ld): %d", (long)row, (long)col, (long)x, (long)y, isDark);

    }
    // end of row
    [chartext appendString:@"\n"];
    [rowpixels removeObjectsInRange:NSMakeRange(glyphHeight, rowpixels.count-glyphHeight)];
    [cols addObject:rowpixels];
  }
  NSLog(@"Glyph (width:%ld, maxheight:%ld)\n%@\n", (long)glyphWidth, (long)glyphHeight, chartext);
  // remove the extra cols
  [cols removeObjectsInRange:NSMakeRange(glyphWidth, cols.count-glyphWidth)];
  return cols;
}


- (BOOL)isColorAtPointDark:(NSPoint)point inBitmap:(NSBitmapImageRep *)bitmapRep
{
  // Sample the color at the specified point from the existing bitmap
  NSColor *color = [bitmapRep colorAtX:point.x y:point.y];

  // Convert the color to the device RGB color space
  NSColorSpace *pixelColorSpace = [NSColorSpace genericGrayColorSpace];
  NSColor *grayColor = [color colorUsingColorSpace:pixelColorSpace];

  CGFloat intensity = grayColor.whiteComponent;

  return intensity<0.5;
}

@end
