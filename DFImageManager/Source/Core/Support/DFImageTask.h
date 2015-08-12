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

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageRequest;
@class DFImageResponse;

/*! Constants for determining the current state of a task.
 */
typedef NS_ENUM(NSUInteger, DFImageTaskState) {
    DFImageTaskStateSuspended,
    DFImageTaskStateRunning,
    DFImageTaskStateCancelled,
    DFImageTaskStateCompleted
};

/*! Abstract class representing image task.
 */
@interface DFImageTask : NSObject <NSCopying>

/*! The image request that the task was created with.
 @note Image request is in its canonical form.
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

/*! A progress object monitoring the current task progress. Progress is created lazily.
 @note Progress object can be used to cancel image task.
 */
@property (nonnull, atomic, readonly) NSProgress *progress;

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
- (void)resume;

/*! Advices the image manager that the task should be cancelled. The completion block will be called with error value of { DFImageManagerErrorDomain, DFImageManagerErrorCancelled }
 */
- (void)cancel;

@end
