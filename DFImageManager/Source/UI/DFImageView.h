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

#import "DFImageManaging.h"
#import <UIKit/UIKit.h>

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

@class DFImageRequest;
@class DFImageRequestOptions;
@class DFImageView;

/*! A class conforming to the DFImageViewDelegate protocol provides method for displaying fetched images and reacting to failures.
 */
@protocol DFImageViewDelegate <NSObject>

/*! Method gets called when the completion block is called for the current image fetch task.
 */
- (void)imageView:(nonnull DFImageView *)imageView didCompleteImageTask:(nonnull DFImageTask *)imageTask withImage:(nullable UIImage *)image;

@optional
/*! Method gets called right after the image view starts image request.
 @note This method call is always paired with a -imageView:didCompleteImageTask:withImage: call.
 */
- (void)imageView:(nonnull DFImageView *)imageView willStartImageTaskForRequest:(nonnull DFImageRequest *)request;

@end


#if DF_IMAGE_MANAGER_GIF_AVAILABLE
/*! An image view extends UIImageView class with image fetching functionality. It also adds other features like managing request priorities, retrying failed requests and more.
 @note The DFImageView is a FLAnimatedImageView subclass that support animated GIF playback. The playback is enabled by default and can be disabled using allowsGIFPlayback property. The DFImageView doesn't override any of the FLAnimatedImageView methods so should get the same experience as when using the FLAnimatedImageView class directly. The only addition is a new - (void)displayImage:(UIImage *)image method that supports DFAnimatedImage objects and will automatically start GIF playback when passed an object of that class.
 */
@interface DFImageView : FLAnimatedImageView
#else
/*! An image view extends UIImageView class with image fetching functionality. It also adds other features like managing request priorities, retrying failed requests and more.
 */
@interface DFImageView : UIImageView
#endif

/*! Image manager used by the image view. Set to the shared manager during initialization.
 */
@property (nonnull, nonatomic) id<DFImageManaging> imageManager;

/*! Image view delegate. By default delegate is set to the image view itself. The implementation displays fetched images with animation when necessary.
 */
@property (nullable, nonatomic, weak) id<DFImageViewDelegate> delegate;

/*! Image target size  used for image requests when target size is not present in -setImageWith... method that was called.. Returns current view pixel size when the value is CGSizeZero.
 */
@property (nonatomic) CGSize imageTargetSize;

/*! Image content mode used for image requests when content mode is not present in -setImageWith... method that was called. Default value is DFImageContentModeAspectFill.
 */
@property (nonatomic) DFImageContentMode imageContentMode;

/*! Image request options used for image requests when options are no present in -setImageWith... method that was called.
 */
@property (nullable, nonatomic) DFImageRequestOptions *imageRequestOptions;

/*! Automatically changes current request priority when image view gets added/removed from the window. Default value is NO.
 */
@property (nonatomic) BOOL managesRequestPriorities;

/*! If the value is YES image view will animate image changes when necessary. Default value is YES.
 */
@property (nonatomic) BOOL allowsAnimations;

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
/*! If the value is YES the receiver will start a GIF playback as soon as the image is displayed. Default value is YES.
 */
@property (nonatomic) BOOL allowsGIFPlayback;

#endif

/*! Displays a given image. Automatically starts GIF playback when given a DFAnimatedImage object and when the GIF playback is enabled. The 'GIF' subspec should be installed to enable this feature.
 @note This method is always included in compilation even if the The 'GIF' subspec is not installed.
 */
- (void)displayImage:(nullable UIImage *)image;

/*! Performs any clean up necessary to prepare the view for use again. Removes currently displayed image and cancels all requests registered with a receiver.
 */
- (void)prepareForReuse;

#pragma mark - Fetching

/*! Returns current image task.
 */
@property (nullable, nonatomic, readonly) DFImageTask *imageTask;

/*! Requests an image representation with a target size, image content mode and request options of the receiver. For more info see setImageWithRequests: method.
 */
- (void)setImageWithResource:(nullable id)resource;

/*! Requests an image representation for the specified resource. For more info see setImageWithRequests: method.
 */
- (void)setImageWithResource:(nullable id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options;

/*! Requests an image representation for the specified request. For more info see setImageWithRequests: method.
 */
- (void)setImageWithRequest:(nullable DFImageRequest *)request;

/*! Method gets called when the completion block is called for the current image fetch task.
 */
- (void)didCompleteImageTask:(nonnull DFImageTask *)task withImage:(nullable UIImage *)image;

@end
