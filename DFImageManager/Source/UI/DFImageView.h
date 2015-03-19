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

#if __has_include("DFImageManagerKit+GIF.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
#import <FLAnimatedImage/FLAnimatedImage.h>
#endif

@class DFImageFetchTask;
@class DFImageRequest;
@class DFImageRequestOptions;
@class DFImageView;

/*! A class conforming to the DFImageViewDelegate protocol provides method for displaying fetched images and reacting to failures.
 */
@protocol DFImageViewDelegate <NSObject>

/*! Method gets called every time the completion block is called for the current image fetch task.
 @note Might be called multiple times depending on the number of image requests.
 */
- (void)imageView:(DFImageView *)imageView didCompleteRequest:(DFImageRequest *)request withImage:(UIImage *)image info:(NSDictionary *)info;

@optional
/*! Method gets called right after the image view receives image requests. The requests array might be either nil or empty.
 @note This method call is always paired with a least one -imageView:didCompleteRequest:withImage:info call.
 */
- (void)imageView:(DFImageView *)imageView willStartFetchingImagesForRequests:(NSArray /*! DFImageRequest */ *)requests;

@end


#if __has_include("DFImageManagerKit+GIF.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
/*! An image view extends UIImageView class with image fetching functionality. It also adds other features like managing request priorities, retrying failed requests and more.
 @note The DFImageView is a FLAnimatedImageView subclass that support animated GIF playback. The playback is enabled by default and can be disabled using allowsGIFPlayback property. The DFImageView doesn't override any of the FLAnimatedImageView methods so should get the same experience as when using the FLAnimatedImageView class directly. The only addition is a new - (void)displayImage:(UIImage *)image method that supports DFAnimatedImage objects and will automatically start GIF playback when passed an object of that class.
 */
@interface DFImageView : FLAnimatedImageView <DFImageViewDelegate>
#else
/*! An image view extends UIImageView class with image fetching functionality. It also adds other features like managing request priorities, retrying failed requests and more.
 */
@interface DFImageView : UIImageView <DFImageViewDelegate>
#endif

/*! Image manager used by the image view. Set to the shared manager during initialization.
 */
@property (nonatomic) id<DFImageManaging> imageManager;

/*! Image view delegate. By default delegate is set to the image view itself. The implementation displays fetched images with animation when necessary.
 */
@property (nonatomic, weak) id<DFImageViewDelegate> delegate;

/*! Image target size  used for image requests when target size is not present in -setImageWith... method that was called.. Returns current view pixel size when the value is CGSizeZero.
 */
@property (nonatomic) CGSize imageTargetSize;

/*! Image content mode used for image requests when content mode is not present in -setImageWith... method that was called. Default value is DFImageContentModeAspectFill.
 */
@property (nonatomic) DFImageContentMode imageContentMode;

/*! Image request options used for image requests when options are no present in -setImageWith... method that was called.
 */
@property (nonatomic) DFImageRequestOptions *imageRequestOptions;

/*! Automatically changes current request priority when image view gets added/removed from the window. Default value is NO.
 */
@property (nonatomic) BOOL managesRequestPriorities;

/*! If the value is YES image view will animate image changes when necessary. Default value is YES.
 */
@property (nonatomic) BOOL allowsAnimations;

/*! If the value YES image view will automatically retry image requests when necessary. Default value is YES.
 @note Image view is very careful with auto-retries. It will attempt automatic retry only when network reachability changes (and becomes reachable), image view is visible, current image request is completed and was failed with a network connection error. It also won't auto retry too frequently.
 */
@property (nonatomic) BOOL allowsAutoRetries;

#if __has_include("DFImageManagerKit+GIF.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
/*! If the value is YES the receiver will start a GIF playback as soon as the image is displayed. Default value is YES.
 */
@property (nonatomic) BOOL allowsGIFPlayback;

#endif

/*! Displays a given image. Automatically starts GIF playback when given a DFAnimatedImage object and when the GIF playback is enabled. The 'GIF' subspec should be installed to enable this feature.
 @note This method is always included in compilation even if the The 'GIF' subspec is not installed.
 */
- (void)displayImage:(UIImage *)image;

/*! Performs any clean up necessary to prepare the view for use again. Removes currently displayed image and cancels all requests registered with a receiver.
 */
- (void)prepareForReuse;

#pragma mark - Fetching

/*! Returns current image fetch task.
 */
@property (nonatomic, readonly) DFImageFetchTask *task;

/*! Requests an image representation with a target size, image content mode and request options of the receiver. For more info see setImageWithRequests: method.
 */
- (void)setImageWithResource:(id)resource;

/*! Requests an image representation for the specified resource. For more info see setImageWithRequests: method.
 */
- (void)setImageWithResource:(id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options;

/*! Requests an image representation for the specified request. For more info see setImageWithRequests: method.
 */
- (void)setImageWithRequest:(DFImageRequest *)request;

/*! Requests an image representation for each of the specified requests.
 @note When the method is called image view cancels current image fetch task and starts a new one with a given requests. For more info see DFImageFetchTask.
 @note This method doesn't call -prepareForReuse in case you need to refresh image without invalidating previously displayed image.
 */
- (void)setImageWithRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Creates task for a given requests. Subclasses may override this method to return custom DFImageFetchTask instance.
 */
- (DFImageFetchTask *)createImageFetchTaskForRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler;

@end
