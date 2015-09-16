// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import "DFImageDecoding.h"

/*! Image decoder that supports multiple image formats not supported by UIImage.
 */
@interface DFImageDecoder : NSObject <DFImageDecoding>

/*! The image decoder instance shared by the application.
 */
+ (nullable id<DFImageDecoding>)sharedDecoder;

/*! The image decoder instance shared by the application.
 */
+ (void)setSharedDecoder:(nullable id<DFImageDecoding>)sharedDecoder;

@end
