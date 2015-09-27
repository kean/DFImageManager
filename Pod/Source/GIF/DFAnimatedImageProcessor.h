// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import "DFImageProcessing.h"

/*! Prevents processing of animated images.
 */
@interface DFAnimatedImageProcessor : NSObject <DFImageProcessing>

/*! Initialized animated image processor with an actual processor.
 */
- (nonnull instancetype)initWithProcessor:(nonnull id<DFImageProcessing>)processor;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end
