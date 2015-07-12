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

NS_ASSUME_NONNULL_BEGIN

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
@property (nonatomic, readonly) DFImageRequest *request;

/*! The current state of the task within the image manager.
 */
@property (nonatomic, readonly) DFImageTaskState state;

/*! An error object that indicates why the task failed.
 */
@property (nonatomic, readonly) NSError *error;

/*! Completion block to execute when image task is either cancelled or completed.
 */
@property (nullable, atomic, copy) void (^completionHandler)(UIImage *__nullable image, NSDictionary *info);

/*! Resumes the task.
 */
- (void)resume;

/*! Advices the image manager that the task should be cancelled. The completion block will be called with error value of { DFImageManagerErrorDomain, DFImageManagerErrorCancelled }
 */
- (void)cancel;

/*! Changes the priority of the task.
 */
- (void)setPriority:(DFImageRequestPriority)priority;

@end

NS_ASSUME_NONNULL_END
