//
//  ViewController.h
//  FontHexer2
//
//  Created by Lukas Zeller on 15.12.2023.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController <NSFontChanging, NSWindowDelegate>

@property (weak) IBOutlet NSPopUpButton *fontPopup;
@property (weak) IBOutlet NSButton *boldCheckbox;
@property (weak) IBOutlet NSButton *italicCheckbox;
@property (weak) IBOutlet NSTextField *outputLabel;
@property (weak) IBOutlet NSButton *showFontsButton;
@property (weak) IBOutlet NSSlider *fontSizeSlider;

@end
