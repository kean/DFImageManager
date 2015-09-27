// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManagerDefines.h"
#import <UIKit/UIKit.h>

@class DFImageTask;
@class DFImageRequest;
@class DFImageRequestOptions;

/*! Adds some basic image fetching capabilities to the UIImageView. For more features see DFImageView.
 */
@interface UIImageView (DFImageManager)

/*! Performs any clean up necessary to prepare the view for use again. Removes currently displayed image and cancels all requests registered with a receiver.
 */
- (void)df_prepareForReuse;

/*! Requests an image representation with a target size computed based on the image view size, default content mode (aspect fill) and default options. Uses shared image manager for fetching.
 */
- (nullable DFImageTask *)df_setImageWithResource:(nullable id)resource;

/*! Requests an image representation for the specified resource.
 */
- (nullable DFImageTask *)df_setImageWithResource:(nullable id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options;

/*! Requests an image representation for the specified requests.
 */
- (nullable DFImageTask *)df_setImageWithRequest:(nullable DFImageRequest *)request;

@end
