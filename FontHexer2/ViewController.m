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

  [self.outputLabel setFont:[NSFont systemFontOfSize:self.fontSizeSlider.floatValue]];
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



- (IBAction)fontSizeChanged:(id)sender {
  // Get the slider value
  CGFloat fontSize = self.fontSizeSlider.floatValue;

  // Get the current font and update its size
  NSFont *currentFont = [self.outputLabel font];
  NSFont *updatedFont = [NSFont fontWithName:currentFont.fontName size:fontSize];

  // Apply the updated font to the label
  [self.outputLabel setFont:updatedFont];
}



- (IBAction)updateLabel:(id)sender
{
  // Get selected font name
  NSString *fontName = [self.fontPopup titleOfSelectedItem];

  // Create font with default size
  NSFont *font = [NSFont fontWithName:fontName size:[NSFont systemFontSize]];

  // Apply bold and italic styles if selected
  if (self.boldCheckbox.state == NSControlStateValueOn) {
    font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSBoldFontMask];
  }

  if (self.italicCheckbox.state == NSControlStateValueOn) {
    font = [[NSFontManager sharedFontManager] convertFont:font toHaveTrait:NSItalicFontMask];
  }

  // Update label font
  [self.outputLabel setFont:font];
}



@end
