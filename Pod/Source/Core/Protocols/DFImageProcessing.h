// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DFImageRequest;

/*! Processes images. Might include image scaling, cropping and more.
 */
@protocol DFImageProcessing <NSObject>

/*! Compares two requests for equivalence with regard to processing the image. Requests should be considered equivalent if image processor will produce the same result for both requests when given the same input image.
 @warning Implementation should not inspect a resource object of the request.
 */
- (BOOL)isProcessingForRequestEquivalent:(nonnull DFImageRequest *)request1 toRequest:(nonnull DFImageRequest *)request2;

/*! Returns processed image for a given request.
 @param partial If YES then image is a progressively decoded partial image data.
 */
- (nullable UIImage *)processedImage:(nonnull UIImage *)image forRequest:(nonnull DFImageRequest *)request partial:(BOOL)partial;

@optional
/*! Returns NO when no processing is required for image with a given request.
 @param partial If YES then image is a progressively decoded partial image data.
 */
- (BOOL)shouldProcessImage:(nonnull UIImage *)image forRequest:(nonnull DFImageRequest *)request partial:(BOOL)partial;

@end
