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

@class DFCompositeImageFetchOperation;
@class DFImageRequest;
@class DFImageRequestOptions;
@class DFImageView;


/*! A class conforming to the DFImageViewDelegate protocol provides method for displaying fetched images and reacting to failures.
 */
@protocol DFImageViewDelegate <NSObject>

/*! Method gets called every time the completion block of the composite request used by DFImageView is called. 
 @note Might be called multiple times depending on the number of requests composite request options.
 */
- (void)imageView:(DFImageView *)imageView didCompleteRequest:(DFImageRequest *)request withImage:(UIImage *)image info:(NSDictionary *)info;

@optional
/*! Method gets called right after the image view receives image requests. The requests array might be either nil or empty.
 */
- (void)imageView:(DFImageView *)imageView willStartFetchingImagesForRequests:(NSArray /*! DFImageRequest */ *)requests;

@end


/*! An image view extends UIImageView class with image fetching functionality. It also adds other features like managing request priorities, retrying failed requests and more.
 */
@interface DFImageView : UIImageView <DFImageViewDelegate>

/*! Image manager used by the image view. Set to the shared manager during initialization.
 */
@property (nonatomic) id<DFImageManagingCore> imageManager;

/*! Image target size  used for image requests when target size is not present in -setImageWith... method that was called.. Returns current view pixel size when the value is CGSizeZero.
 */
@property (nonatomic) CGSize imageTargetSize;

/*! Image content mode used for image requests when content mode is not present in -setImageWith... method that was called. Default value is DFImageContentModeAspectFill.
 */
@property (nonatomic) DFImageContentMode imageContentMode;

/*! Image request options used for image requests when options are no present in -setImageWith... method that was called.
 */
@property (nonatomic) DFImageRequestOptions *imageRequestOptions;

/*! Automatically changes current request priority when image view gets added/removed from the window. Default value is YES.
 */
@property (nonatomic) BOOL managesRequestPriorities;

/*! If the value is YES image view will animate image changes when necessary. Default value is YES.
 */
@property (nonatomic) BOOL allowsAnimations;

/*! If the value YES image view will automatically retry image requests when necessary. Default value is YES.
 @note Image view is very careful with auto-retries. It will attempt automatic retry only when network reachability changes (and becomes reachable), image view is visible, current image request is completed and was failed with a network connection error. It also won't auto retry too frequently.
 */
@property (nonatomic) BOOL allowsAutoRetries;

/*! Image view delegate. By default delegate is set to the image view itself. The implementation displays fetched images with animation when necessary.
 */
@property (nonatomic, weak) id<DFImageViewDelegate> delegate;

/*! Performs any clean up necessary to prepare the view for use again. Removes currently displayed image and cancels all requests registered with a receiver.
 */
- (void)prepareForReuse;

/*! Returns current composite image fetch operation.
 */
@property (nonatomic, readonly) DFCompositeImageFetchOperation *operation;

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
 @note When the method is called image view cancels current composite request and starts a new composite request with a given image requests. For more info see DFCompositeImageFetchOperation.
 @note This method doesn't call -prepareForReuse in case you need to refresh image without invalidating previously displayed image.
 */
- (void)setImageWithRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Creates composite image fetch operation for given requests. Subclasses may override this method to customize composite request.
 */
- (DFCompositeImageFetchOperation *)createCompositeImageFetchOperationForRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler;

@end
