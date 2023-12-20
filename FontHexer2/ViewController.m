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
  [self.samplingGrid sampleColorsInGridCells];
}

@end
