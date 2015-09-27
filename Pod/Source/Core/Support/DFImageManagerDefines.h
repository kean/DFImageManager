// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/* Size to pass when requesting the largest image for resource available (contentMode will be ignored).
 */
extern CGSize const DFImageMaximumSize;

/*! Options for fitting an image’s aspect ratio to a target size.
 */
typedef NS_ENUM(NSInteger, DFImageContentMode) {
    /*! Fill the target size. Some portion of the content may be clipped if the clipping is allowed (see DFImageRequestOptions for more info).
    */
    DFImageContentModeAspectFill,
    
    /*! Fit the target size by maintaining the aspect ratio.
     */
    DFImageContentModeAspectFit
};

/*! The DFImageRequestCachePolicy defines the request cache policy used for memory caching. For more info on memory caching in DFImageManager docs.
 */
typedef NS_ENUM(NSInteger, DFImageRequestCachePolicy) {
    /*! The default policy allows memory cache lookup.
     */
    DFImageRequestCachePolicyDefault,
    
    /* Specifies that the image should loaded from the originating source. No existing cache data should be used to satisfy the request.
     */
    DFImageRequestCachePolicyReloadIgnoringCache
};

/*! Image request priority.
 */
typedef NS_ENUM(NSInteger, DFImageRequestPriority) {
    DFImageRequestPriorityLow,
    DFImageRequestPriorityNormal,
    DFImageRequestPriorityHigh
};

/*! The error domain for DFImageManager.
 */
extern NSString *__nonnull const DFImageManagerErrorDomain;

/*! Returned when an image request is cancelled.
 */
static const NSInteger DFImageManagerErrorCancelled = -1;

/*! Returned when an image request fails without a specific reason.
 */
static const NSInteger DFImageManagerErrorUnknown = -2;

#define DF_INIT_UNAVAILABLE_IMPL \
- (nullable instancetype)init { \
    [NSException raise:NSInternalInconsistencyException format:@"Please use designated initialzier"]; \
    return nil; \
} \
