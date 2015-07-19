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

/*! For more info check the enumerations and other definitions provided in this header file:
 */
#import "DFImageManagerDefines.h"

@class DFImageRequest;
@class DFImageTask;

NS_ASSUME_NONNULL_BEGIN

typedef void (^DFImageRequestCompletion)(UIImage *__nullable image, NSDictionary *info);

/*! Provides an API for loading images associated with a given resources. The resources might by anything from a NSURL to a PHAsset objects or even your custom classes.
 */
@protocol DFImageManaging <NSObject>

/*! Inspects the given request and determines whether it can be handled.
 */
- (BOOL)canHandleRequest:(DFImageRequest *)request;

/*! Creates an image task with a given resource. After you create the task, you must start it by calling its resume method.
 @note Creates image request with a DFImageMaximumSize, DFImageContentModeAspectFill and no options.
 @param resource The resource whose image data is to be loaded.
 */
- (nullable DFImageTask *)imageTaskForResource:(id)resource completion:(nullable DFImageRequestCompletion)completion;

/*! Creates an image task with a given request. After you create the task, you must start it by calling its resume method.
 @param request The request that contains the resource whose image is to be loaded, and request options. Image manager creates a deep copy of the request.
 @param completion Completion block to be called on the main thread when loading is complete. Completion block is called synchronously when the requested image can be retrieved from the memory cache and the request was made on the main thread. The info dictionary provides information about the status of the request. See the definitions of DFImageInfo*Key strings for possible keys and values. For more info see DFImageManager class reference.
 @return An image task.
 */
- (nullable DFImageTask *)imageTaskForRequest:(DFImageRequest *)request completion:(nullable DFImageRequestCompletion)completion;

/*! Asynchronously calls a completion block on the main thread with all resumed outstanding image tasks and separate array with all preheating tasks.
 */
- (void)getImageTasksWithCompletion:(void (^)(NSArray *tasks, NSArray *preheatingTasks))completion;

/*! Cancels all outstanding requests, including preheating requests, and then invalidates the image manager. New requests may not be created.
 */
- (void)invalidateAndCancel;

/*! Prepares images for the given requests for later use.
 @note The application is responsible for providing the same requests when preheating the images and when actually requesting them later or else the preheating might not be effective.
 */
- (void)startPreheatingImagesForRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Cancels preheating for the given requests.
 */
- (void)stopPreheatingImagesForRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Cancels all image preheating tasks registered with a manager.
 */
- (void)stopPreheatingImagesForAllRequests;

#pragma mark - Deprecated

/*! Deprecated. Use -imageTaskForResource:completion: instead.
 */
- (nullable DFImageTask *)requestImageForResource:(id)resource completion:(nullable DFImageRequestCompletion)completion DEPRECATED_ATTRIBUTE;

/*! Deprecated. Use -imageTaskForRequest:completion: instead.
 */
- (nullable DFImageTask *)requestImageForRequest:(DFImageRequest *)request completion:(nullable DFImageRequestCompletion)completion DEPRECATED_ATTRIBUTE;

@end

NS_ASSUME_NONNULL_END
