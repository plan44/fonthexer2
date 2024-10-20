//
//  P44FontGenerator.h
//  FontHexer2
//
//  Created by Lukas Zeller on 20.12.2023.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface P44FontGenerator : NSObject

+ (void)generateFontSourceNamed:(NSString*)aFontName withCopyright:(NSString*)aCopyright fromData:(NSDictionary*)aFontDict intoFILE:(FILE*)aOutputFile;
+ (void)generateFontFileNamed:(NSString*)aFontName withCopyright:(NSString*)aCopyright fromData:(NSDictionary*)aFontDict intoFILE:(FILE*)aOutputFile;

@end

NS_ASSUME_NONNULL_END
