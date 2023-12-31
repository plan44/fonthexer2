//
//  GridOverlayView.h
//  FontHexer2
//
//  Created by Lukas Zeller on 20.12.2023.
//

#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface GridOverlayView : NSView

@property (nonatomic) NSPoint initialMouseLocation;

@property (nonatomic) CGFloat originX;
@property (nonatomic) CGFloat originY;

@property (nonatomic) CGFloat cellSize;

@end

NS_ASSUME_NONNULL_END
