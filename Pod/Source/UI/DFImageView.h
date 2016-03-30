// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManaging.h"
#import <UIKit/UIKit.h>

@class DFImageRequest;
@class DFImageRequestOptions;

/*! The DFImageView extends UIImageView class with image fetching functionality. It also adds other features like managing request priorities and more.
 */
@interface DFImageView : UIImageView

/*! Image manager used by the image view. Set to the shared manager during initialization.
 */
@property (nonnull, nonatomic) id<DFImageManaging> imageManager;

/*! Automatically changes current request priority when image view gets added/removed from the window. Default value is NO.
 */
@property (nonatomic) BOOL managesRequestPriorities;

/*! If the value is YES image view will animate image changes when necessary. Default value is YES.
 */
@property (nonatomic) BOOL allowsAnimations;

/*! Duration it will take to animate image in if image view allows animations.
 */
@property (nonatomic) CGFloat fadeDuration;

/*! Performs any clean up necessary to prepare the view for use again. Removes currently displayed image and cancels all requests registered with a receiver.
 */
- (void)prepareForReuse;

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

/*! Subclassing hook that gets called when the completion block is called for the current image fetch task.
 */
- (void)didCompleteImageTask:(nonnull DFImageTask *)task withImage:(nullable UIImage *)image;

@end
