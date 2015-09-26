// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManaging.h"
#import <Foundation/Foundation.h>

@class DFImageManagerConfiguration;

/*! The role of DFImageManager is to manage the execution of image tasks by delegating the actual job to the objects implementing DFImageFetching, DFImageCaching, DFImageDecoding, and DFImageProcessing protocols.
 
 @note Reusing Operations 
 
 DFImageManager might use a single fetch operation for multiple image tasks with equivalent requests. Image manager cancels fetch operations only when there are no remaining image tasks registered with a given operation.
 
 @note Memory Caching
 
 DFImageManager uses DFImageCaching protocol for memory caching. It should be able to lookup cached images based on the image requests, but it doesn't know anything about the resources, specific request options, and the way the requests are interpreted and handled. There are three simple rules how image manager stores and retrieves cached images. First, image manager can't use cached images stored by other managers. Second, all resources must implement -hash method. Third, image manager uses special cache keys that delegate the test for equivalence of the image requests to the image fetcher (DFImageFetching) and the image processor (DFImageProcessing).
 
 @note Preheating
 
 DFImageManager does its best to guarantee that preheating tasks never interfere with regular (non-preheating) tasks. There is a limit of concurrent preheating tasks enforced by DFImageManager. There is also certain (very small) delay when manager starts executing preheating requests.
 */
@interface DFImageManager : NSObject <DFImageManaging>

/*! A copy of the configuration object for this manager (read only). Changing mutable values within the configuration object has no effect on the current manager.
 */
@property (nonnull, nonatomic, copy, readonly) DFImageManagerConfiguration *configuration;

/*! Creates image manager with a given configuration. Manager copies the configuration object.
 */
- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end


/*! Dependency injectors for the image manager shared by the application.
 */
@interface DFImageManager (SharedManager)

/*! Returns the shared image manager instance. By default returns the image manager instance created using DFImageManager -createDefaultManager method. An application with more specific needs can create a custom image manager and set it as a shared instance.
 */
+ (nonnull id<DFImageManaging>)sharedManager;

/*! Sets the image manager instance shared by all clients of the current application.
 */
+ (void)setSharedManager:(nonnull id<DFImageManaging>)manager;

@end


@interface DFImageManager (DefaultManager)

/*! Creates default image manager that contains all built-in fetchers.
 @note Supported resources:
 - NSURL with schemes http, https, ftp, file and data (AFNetworking or NSURLSession subspec, AFNetworking is used by default when available)
 - PHAsset and NSURL with scheme com.github.kean.photos-kit (PhotosKit subspec)
 */
+ (nonnull id<DFImageManaging>)createDefaultManager;

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
