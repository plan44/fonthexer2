//
//  ViewController.h
//  FontHexer2
//
//  Created by Lukas Zeller on 15.12.2023.
//

#import <Cocoa/Cocoa.h>
#import "GridOverlayView.h"

@interface ViewController : NSViewController <NSFontChanging, NSWindowDelegate>

@property (weak) IBOutlet NSPopUpButton *fontPopup;
@property (weak) IBOutlet NSButton *boldCheckbox;
@property (weak) IBOutlet NSButton *italicCheckbox;
@property (weak) IBOutlet NSTextField *outputLabel;
@property (weak) IBOutlet GridOverlayView *samplingGrid;
@property (weak) IBOutlet NSButton *showFontsButton;
@property (weak) IBOutlet NSSlider *fontSizeSlider;
@property (weak) IBOutlet NSTextField *charsetTextField;
@property (weak) IBOutlet NSTextField *copyrightTextField;
@property (weak) IBOutlet NSTextField *sampleCharsTextField;
@property (weak) IBOutlet NSTextField *fontNameTextField;
@property (weak) IBOutlet NSButton *eliminateTrailingColCheckbox;
@property (weak) IBOutlet NSButton *cppCheckbox;
@property (weak) IBOutlet NSButton *lrgfCheckbox;

@end
