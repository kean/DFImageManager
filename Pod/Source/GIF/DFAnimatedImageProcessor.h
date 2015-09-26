// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import "DFImageProcessing.h"

/*! Prevents processing of animated images.
 */
@interface DFAnimatedImageProcessor : NSObject <DFImageProcessing>

- (nonnull instancetype)initWithProcessor:(nonnull id<DFImageProcessing>)processor;

@end
