// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageProcessing.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*! NSNumber with float value that specifies a normalized image corner radius, where 0.5 is a corner radius that is half of the minimum image side. Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *__nonnull DFImageProcessingCornerRadiusKey;

/*! The DFImageProcessor implements image decompression, scaling, cropping and more.
 */
@interface DFImageProcessor : NSObject <DFImageProcessing>

/*! If YES decoder would force image decompression, otherwise UIImage might delay decompression until the image is displayed. Default value is YES.
 */
@property (nonatomic) BOOL shouldDecompressImages;

@end
