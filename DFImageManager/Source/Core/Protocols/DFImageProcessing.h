// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DFImageRequest;

NS_ASSUME_NONNULL_BEGIN

/*! Processes fetched images. Might include image decompression, resizing and anything else.
 @note Implementations should not cache processed images and leave it to classes conforming DFImageCaching protocol.
 */
@protocol DFImageProcessing <NSObject>

/*! Compares two requests for equivalence with regard to processing the image. Requests should be considered equivalent if image processor will produce the same result for both requests when given the same input image. 
 @warning Implementation should not inspect a resource object of the request!
 */
- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2;

/*! Returns processed image for a given request.
 */
- (nullable UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request;

@end

NS_ASSUME_NONNULL_END
