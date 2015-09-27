// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManaging.h"
#import <Foundation/Foundation.h>

@class DFImageManagerConfiguration;

/*! The DFImageManager manages execution of image tasks by delegating the actual job to the objects conforming to DFImageFetching, DFImageCaching, DFImageDecoding, and DFImageProcessing protocols.
 
 @note Reusing Operations 
 
 DFImageManager might uses a single fetch operation for image tasks with equivalent requests. Image manager cancels fetch operations only when there are no remaining image tasks registered with a given operation.
 */
@interface DFImageManager : NSObject <DFImageManaging>

/*! Returns a copy of the configuration object for this manager.
 */
@property (nonnull, nonatomic, copy, readonly) DFImageManagerConfiguration *configuration;

/*! Creates image manager with a given configuration. Manager copies the configuration object.
 */
- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end


/*! Dependency injectors.
 */
@interface DFImageManager (SharedManager)

/*! Returns the shared image manager instance.
 */
+ (nonnull id<DFImageManaging>)sharedManager;

/*! Sets the shared image manager.
 */
+ (void)setSharedManager:(nonnull id<DFImageManaging>)manager;

@end


@interface DFImageManager (Convenience)

/* Creates an image task with a given resource. After you create the task, you must start it by calling its resume method.
 */
+ (nonnull DFImageTask *)imageTaskForResource:(nonnull id)resource completion:(nullable DFImageTaskCompletion)completion;

/*! Creates an image task with a given request. After you create the task, you must start it by calling its resume method.
 */
+ (nonnull DFImageTask *)imageTaskForRequest:(nonnull DFImageRequest *)request completion:(nullable DFImageTaskCompletion)completion;

/*! Asynchronously calls a completion block on the main thread with all resumed outstanding image tasks and separate array with all preheating tasks.
 */
+ (void)getImageTasksWithCompletion:(void (^__nullable)(NSArray<DFImageTask *> *__nonnull tasks, NSArray<DFImageTask *> *__nonnull preheatingTasks))completion;

/*! Cancels all outstanding requests, including preheating requests, and then invalidates the image manager. New image tasks may not be started.
 */
+ (void)invalidateAndCancel;

/*! Prepares images for the given requests for later use.
 */
+ (void)startPreheatingImagesForRequests:(nonnull NSArray<DFImageRequest *> *)requests;

/*! Cancels preheating for the given requests.
*/
+ (void)stopPreheatingImagesForRequests:(nonnull NSArray<DFImageRequest *> *)requests;

/*! Cancels all image preheating tasks registered with a manager.
 */
+ (void)stopPreheatingImagesForAllRequests;

/*! Removes all cached images from all cache layers.
 */
+ (void)removeAllCachedImages;

@end
