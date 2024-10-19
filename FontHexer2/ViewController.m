//
//  ViewController.m
//  FontHexer2
//
//  Created by Lukas Zeller on 15.12.2023.
//

#import "ViewController.h"
#import "P44FontGenerator.h"

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];

  // Set up the font menu with available fonts
  NSArray *fontFamilyNames = [NSFontManager.sharedFontManager availableFontFamilies];
  [self.fontPopup addItemsWithTitles:fontFamilyNames];

}

- (void)viewWillAppear
{
  [self.sampleCharsTextField setStringValue:@"gfA0"];
  [NSFontManager.sharedFontManager setSelectedFont:self.outputLabel.font isMultiple:NO];
  [self fontSizeChanged:nil];
  [self setDefaultCharset:nil];
  [self showSampleChars:nil];
}


- (IBAction)showFontPicker:(id)sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSFontPanel *fontPanel = [fontManager fontPanel:YES];
  [fontPanel setDelegate:self];
  [fontPanel makeKeyAndOrderFront:nil];
}


- (void)changeFont:(NSFontManager*)fontManager
{
  NSFont *originalSelection = [fontManager selectedFont];
  if (originalSelection) {
    NSLog(@"Originally selected font: %@", originalSelection.fontName);
  }
  CGFloat fontSize = [self.fontSizeSlider floatValue]; // Use slider's value
  NSFont *selectedFont = [fontManager convertFont:originalSelection toSize:fontSize];
  if (selectedFont) {
    NSLog(@"Selected font: %@", selectedFont.fontName);
  }
  [fontManager setSelectedFont:selectedFont isMultiple:NO];
  [self updateLabelFont: nil];
}


- (NSFontPanelModeMask)validModesForFontPanel:(NSFontPanel *)fontPanel
{
  return NSFontPanelModeMaskFace|NSFontPanelModeMaskCollection;
}



- (BOOL)changeAttributes:(id)sender
{
  return YES;
}


- (IBAction)fontSettingsChanged:(id)sender
{
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  NSString *fontName = [self.fontPopup titleOfSelectedItem];
  CGFloat fontSize = [self.fontSizeSlider floatValue]; // Use slider's value
  [self.fontNameTextField setStringValue:[self makeP44fontNameFrom:fontName]];
  NSFont *newFont = [NSFont fontWithName:fontName size:fontSize];
  if ([self.boldCheckbox state] == NSControlStateValueOn) {
    newFont = [fontManager convertFont:newFont toHaveTrait:NSBoldFontMask];
  }
  if ([self.italicCheckbox state] == NSControlStateValueOn) {
    newFont = [fontManager convertFont:newFont toHaveTrait:NSItalicFontMask];
  }
  [fontManager setSelectedFont:newFont isMultiple:NO];
  [self updateLabelFont: nil];
}


- (IBAction)fontSizeChanged:(id)sender
{
  // font size slider changes
  NSFontManager *fontManager = [NSFontManager sharedFontManager];
  CGFloat fontSize = [self.fontSizeSlider floatValue]; // Use slider's value
  NSFont *newFont = [fontManager convertFont:fontManager.selectedFont toSize:fontSize];
  [fontManager setSelectedFont:newFont isMultiple:NO];
  [self updateLabelFont: nil];
}


- (NSString *)makeP44fontNameFrom:(NSString*)inputString
{
  NSError *error = nil;

  // Define a regular expression pattern to match non-alphanumeric characters
  NSString *pattern = @"[^a-zA-Z0-9]";

  // Create a regular expression with the specified pattern
  NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:&error];

  // Replace matches with an underscore
  NSString *resultString = [regex stringByReplacingMatchesInString:inputString
                                                           options:0
                                                             range:NSMakeRange(0, [inputString length])
                                                      withTemplate:@"_"];
  if (error) {
    NSLog(@"Error creating regular expression: %@", error.localizedDescription);
  }
  return resultString;
}


- (IBAction)updateLabelFont: (id)sender
{
  [self.outputLabel setFont:[NSFontManager sharedFontManager].selectedFont];
}



- (FILE *)getFileToWriteToWithDefault:(NSString*)aDefaultName andExtension:(NSString*)aExtension
{
  NSSavePanel *savePanel = [NSSavePanel savePanel];

  // Set the allowed file types
  [savePanel setAllowedFileTypes:@[aExtension]];

  // set the default name
  if (aDefaultName) {
    [savePanel setNameFieldStringValue:aDefaultName];
  }

  // Display the Save dialog
  NSInteger result = [savePanel runModal];

  // Check if the user clicked the Save button
  if (result == NSModalResponseOK) {
    // Get the selected file URL
    NSURL *fileURL = [savePanel URL];

    // Convert the file URL to a file path
    const char *filePath = [[fileURL path] UTF8String];

    // Open the file for writing
    FILE *file = fopen(filePath, "w");

    // Check if the file was opened successfully
    if (file != NULL) {
      return file;
    } else {
      NSLog(@"Failed to open file for writing.");
    }
  }
  // Return NULL if there was an error or if the user canceled the Save operation
  return NULL;
}





- (IBAction)setDefaultCharset:(id)sender
{
  NSMutableString* chs = [NSMutableString string];

  // ASCII
  for(char c = ' '; c<0x7F; c++) {
    [chs appendFormat:@"%c", c];
  }
  // our special chars we'd like to have
  [chs appendString:@"ÀÁÂÄÈÉÊÖÜàáâäçèéêëìíîïöü–’•"];
  [self.charsetTextField setStringValue:chs];
}



- (IBAction)sampleFont:(id)sender
{
  NSString* charsToRender = self.charsetTextField.stringValue;

  NSDictionary* fontDict = [NSMutableDictionary dictionary];
  // create empty placeholder glyph (will be syntesized when exported)
  [fontDict setValue:@[@[@(NO)]] forKey:@"placeholder"];
  for (NSUInteger i = 0; i < [charsToRender length]; ) {
    NSRange range = [charsToRender rangeOfComposedCharacterSequenceAtIndex:i];
    // extract composed chars (usually: none)
    NSString *character = [charsToRender substringWithRange:range];

    // Extract the UTF-8 sequence(s) for the current character
    const char* utf8char = [character UTF8String];
    // Use character as needed
    NSLog(@"\n\n=================\nNext char: %@ (%ld UTF8 bytes), range=(%ld, %ld))", character, (long)strlen(utf8char), (long)range.location, (long)range.length);

    // put the char in the label
    [self.outputLabel setStringValue:character];

    // sample the char
    NSArray* glyph = [self sampleColorsInGridCells];
    NSLog(@"---------- Glyph with %ld cols", glyph.count);

    // save in font dict
    [fontDict setValue:glyph forKey:character];

    // Move to the next character
    i = NSMaxRange(range);
  }
  [self showSampleChars:nil];

  // now create font source file
  if ([self.cppCheckbox state] == NSControlStateValueOn) {
    FILE* outputfile = [self getFileToWriteToWithDefault:[@"font_" stringByAppendingString:self.fontNameTextField.stringValue] andExtension:@"cpp"];
    if (outputfile) {
      [P44FontGenerator generateFontSourceNamed:self.fontNameTextField.stringValue withCopyright:self.copyrightTextField.stringValue fromData:fontDict intoFILE:outputfile];
      fclose(outputfile);
    }
  }
  if ([self.lrgfCheckbox state] == NSControlStateValueOn) {
    FILE* outputfile = [self getFileToWriteToWithDefault:[@"font_" stringByAppendingString:self.fontNameTextField.stringValue]  andExtension:@"lrgf"];
    if (outputfile) {
      [P44FontGenerator generateFontFileNamed:self.fontNameTextField.stringValue withCopyright:self.copyrightTextField.stringValue fromData:fontDict intoFILE:outputfile];
      fclose(outputfile);
    }
  }
}


- (IBAction)showSampleChars:(id)sender
{
  [self.outputLabel setStringValue:self.sampleCharsTextField.stringValue];
}

// MARK: sample

- (NSArray*)sampleColorsInGridCells
{
  NSMutableArray* cols = [NSMutableArray array];

  // Get the bounds of the view
  NSRect bounds = [self.samplingGrid bounds];

  NSInteger numRows = (bounds.size.height-self.samplingGrid.originY)/self.samplingGrid.cellSize+0.5;
  NSInteger numCols = (bounds.size.width-self.samplingGrid.originX)/self.samplingGrid.cellSize+0.5;
  BOOL allCols = [self.eliminateTrailingColCheckbox state] == NSControlStateValueOff;

  // Get the content of the label's layer as an image
  NSImage *image = [[NSImage alloc] initWithSize:self.outputLabel.bounds.size];
  [image lockFocus];
  [self.outputLabel.layer renderInContext:[NSGraphicsContext currentContext].CGContext];
  [image unlockFocus];

  NSBitmapImageRep *bitmapRep = [[NSBitmapImageRep alloc] initWithData:[image TIFFRepresentation]];

  // Log the contents of the image (debugging purposes)
  NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
  NSString *documentsDirectory = [paths firstObject];
  NSString *filePath = [documentsDirectory stringByAppendingPathComponent:@"debug_image.png"];
  NSData *pngData = [bitmapRep representationUsingType:NSBitmapImageFileTypePNG properties:@{}];
  [pngData writeToFile:filePath atomically:YES];

  // get the scaling, might be retina as we are rendering in the window context, apparently
  NSWindow *mainWindow = [[NSApplication sharedApplication] mainWindow];
  CGFloat scale = [mainWindow backingScaleFactor];

  // Iterate through each cell and sample the color at the center
  NSMutableString* chartext = [NSMutableString string];
  NSInteger glyphWidth = 0;
  NSInteger glyphHeight = 0;
  BOOL started = NO;
  NSInteger firstUsedCol = 0;
  for (NSInteger col = 0; col < numCols; col++) {
    [chartext appendFormat:@"%02ld: ", (long)col];
    NSMutableArray* colpixels = [NSMutableArray array];
    for (NSInteger row = 0; row < numRows; row++) {
      CGFloat x = bounds.origin.x + (((CGFloat)col + 0.5) * self.samplingGrid.cellSize + self.samplingGrid.originX) * scale;
      CGFloat y = bounds.origin.y + (((CGFloat)row + 0.5) * self.samplingGrid.cellSize + self.samplingGrid.originY) * scale;

      CGPoint pt = NSMakePoint(x, y);
      // Note: NO NEED to Adjust the y-coordinate, apparently bitmapRep is also in Core Graphics orientation
      //pt.y = bitmapRep.size.height*scale - pt.y;

      // Sample the color from the image
      BOOL isDark = [self isColorAtPointDark:pt inBitmap:bitmapRep];
      if (!started && (isDark || allCols)) {
        firstUsedCol = col;
        started = YES;
      }
      if (isDark) glyphWidth = col+1-firstUsedCol;
      if (isDark && row+1>glyphHeight) glyphHeight = row+1;
      [chartext appendString:isDark ? @"X" : @"."];
      [colpixels addObject:@(isDark)];

      //NSLog(@"Dark at cell (%ld, %ld) coord (%ld, %ld): %d", (long)row, (long)col, (long)x, (long)y, isDark);

    }
    // end of row
    [chartext appendString:@"\n"];
    if (started) {
      [colpixels removeObjectsInRange:NSMakeRange(glyphHeight, colpixels.count-glyphHeight)];
      [cols addObject:colpixels];
    }
  }
  NSLog(@"Glyph (width:%ld, empty cols skipped: %ld, maxheight:%ld)\n%@\n", (long)glyphWidth, (long)firstUsedCol, (long)glyphHeight, chartext);
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
