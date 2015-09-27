// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import "DFImageDecoding.h"

/*! Image decoder that supports multiple image formats not supported by UIImage.
 */
@interface DFImageDecoder : NSObject <DFImageDecoding>

@end


/*! Composes image decoders.
*/
@interface DFCompositeImageDecoder : NSObject <DFImageDecoding>

/*! Initializes DFCompositeImageDecoder with an array of decoders.
 */
- (nonnull instancetype)initWithDecoders:(nonnull NSArray <id<DFImageDecoding>> *)decoders;

@end