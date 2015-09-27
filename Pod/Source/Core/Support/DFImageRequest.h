// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageRequestOptions;

/*! The DFImageRequest class represents an image request for a specified resource.
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
+ (nonnull instancetype)requestWithResource:(nonnull id)resource;

/*! Returns a DFImageRequest initialized with a given parameters.
 */
+ (nonnull instancetype)requestWithResource:(nonnull id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end
