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

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageRequestOptions;

/*! The DFImageRequest class represents an image request for a specified resource. The request also contains options on how to retrieve and (optionally) process the image.
 */
@interface DFImageRequest : NSObject

/*! The resource whose image data is to be loaded.
 */
@property (nonnull, nonatomic, readonly) id resource;

/*! The size in pixels of image to be returned.
 */
@property (nonatomic, readonly) CGSize targetSize;

/*! An option for how to fit the image to the aspect ratio of the requested size. For details, see DFImageContentMode.
 */
@property (nonatomic, readonly) DFImageContentMode contentMode;

/*! Options specifying how image manager should handle the request and process the received image. More options that are provided in a base class may be available, so make sure to check the documentation on that.
 */
@property (nonnull, nonatomic, readonly) DFImageRequestOptions *options;

/*! Initializes request with a given parameters.
 @param resource The resource whose image data is to be loaded.
 @param targetSize The size in pixels of image to be returned.
 @param contentMode An option for how to fit the image to the aspect ratio of the requested size. For details, see DFImageContentMode.
 @param options Options specifying how image manager should handle the request and process the received image. Default options are created when parameter is nil.
 */
- (nonnull instancetype)initWithResource:(nonnull id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options NS_DESIGNATED_INITIALIZER;

/*! Returns a DFImageRequest initialized with a given resource. Uses DFImageMaximumSize and DFImageContentModeAspectFill as other parameters.
 */
- (nonnull instancetype)initWithResource:(nonnull id)resource;

/*! Returns a DFImageRequest initialized with a given resource. Uses DFImageMaximumSize and DFImageContentModeAspectFill as other parameters.
 */
+ (nonnull instancetype)requestWithResource:(nonnull id)resource;

/*! Returns a DFImageRequest initialized with a given parameters.
 */
+ (nonnull instancetype)requestWithResource:(nonnull id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end


@interface DFImageRequest (UIKitAdditions)

/*! Returns image target size (in pixels) for a given view.
 */
+ (CGSize)targetSizeForView:(nonnull UIView *)view;

@end
