// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageRequest;
@class DFImageResponse;

/*! Constants for determining the current state of a task.
 */
typedef NS_ENUM(NSUInteger, DFImageTaskState) {
    DFImageTaskStateSuspended = 0,
    DFImageTaskStateRunning,
    DFImageTaskStateCancelled,
    DFImageTaskStateCompleted
};

/*! Abstract class representing image task.
 */
@interface DFImageTask : NSObject <NSCopying>

/*! The image request that the task was created with.
 */
@property (nonnull, atomic, readonly) DFImageRequest *request;

/*! The current state of the task within the image manager.
 */
@property (nonatomic, readonly) DFImageTaskState state;

/*! An error object that indicates why the task failed.
 */
@property (nullable, atomic, readonly) NSError *error;

/*! Returns image response with metadata associated with a load.
 */
@property (nullable, atomic, readonly) DFImageResponse *response;

/*! A progress object monitoring the task progress. Progress is created lazily.
 @note Progress object can be used to cancel image task.
 */
@property (nullable, atomic, readonly) NSProgress *progress;

/*! A progress block monitoring the task progress. Always called on the main thread.
 */
@property (nullable, atomic, copy) void (^progressHandler)(int64_t completedUnitCount, int64_t totalUnitCount);

/*! Priority of the task. Can be changed during the execution of the task.
 */
@property (nonatomic) DFImageRequestPriority priority;

/*! Completion block to execute on the main thread when image task is either cancelled or completed.
 */
@property (nullable, atomic, copy) void (^completionHandler)(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull imageTask);

/*! Progressive image handler which gets called on the main thread when partial image data is decoded.
 */
@property (nullable, atomic, copy) void (^progressiveImageHandler)(UIImage *__nonnull image);

/*! Resumes the task.
 */
- (nonnull DFImageTask *)resume;

/*! Advices the image manager that the task should be cancelled. The completion block will be called with error value of { DFImageManagerErrorDomain, DFImageManagerErrorCancelled }
 */
- (void)cancel;

@end
