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

NS_ASSUME_NONNULL_BEGIN

/* Size to pass when requesting the largest image for resource available (contentMode will be ignored).
 */
extern CGSize const DFImageMaximumSize;


// Requests results info keys:

/*! An image task (DFImageTask).
 */
extern NSString *const DFImageInfoTaskKey;

/*! An error that occurred when Photos attempted to load the image (NSError). 
 */
extern NSString *const DFImageInfoErrorKey;

/*! A boolean value indicating whether the image was returned from the memory cache.
 */
extern NSString *const DFImageInfoIsFromMemoryCacheKey;


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
    DFImageRequestPriorityVeryLow = NSOperationQueuePriorityVeryLow,
    DFImageRequestPriorityLow = NSOperationQueuePriorityLow,
    DFImageRequestPriorityNormal = NSOperationQueuePriorityNormal,
    DFImageRequestPriorityHigh = NSOperationQueuePriorityHigh,
    DFImageRequestPriorityVeryHigh = NSOperationQueuePriorityVeryHigh
};

/*! Progress handler, called on a main thread.
 */
typedef void (^DFImageRequestProgressHandler)(double progress);

/*! The error domain for DFImageManager.
 */
extern NSString *const DFImageManagerErrorDomain;

/*! Returned when an image request is cancelled.
 */
static const NSInteger DFImageManagerErrorCancelled = -1;

/*! Returned when an image request fails without a specific reason.
 */
static const NSInteger DFImageManagerErrorUnknown = -2;

NS_ASSUME_NONNULL_END

#define DF_IMAGE_MANAGER_GIF_AVAILABLE __has_include("DFImageManagerKit+GIF.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
#define DF_IMAGE_MANAGER_WEBP_AVAILABLE __has_include("DFImageManagerKit+WebP.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
#define DF_IMAGE_MANAGER_AFNETWORKING_AVAILABLE __has_include("DFImageManagerKit+AFNetworking.h") && !(DF_IMAGE_MANAGER_FRAMEWORK_TARGET)
