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
#import <UIKit/UIKit.h>

@class DFCompositeImageTask;
@class DFImageRequest;
@class DFImageTask;
@protocol DFImageManaging;

typedef void (^DFCompositeImageTaskImageHandler)(UIImage *__nullable image, DFImageTask *__nonnull completedTask, DFCompositeImageTask *__nonnull compositeTask);
typedef void (^DFCompositeImageTaskCompletionHandler)(DFCompositeImageTask *__nonnull compositeTask);

/*! The DFCompositeImageTask manages execution of one or more image tasks and provides a single image handler that gets called multiple times. All requests are executed concurrently.
 @note DFCompositeImageTask treats an array of image tasks as if the last one was the final image, while the others were the placeholders. The image handler gets called each time the image is successfully fetched, but it doesn't get called for obsolete tasks - when better image is already fetched. It also automatically cancels obsolete tasks.
 @warning This class is not thread safe and is designed to be used on the main thread. All handlers are called on the main thread too.
 */
@interface DFCompositeImageTask : NSObject

/*! Initializes composite task with an array of image tasks. After you create the task, you must resume it by calling resume method.
 @param tasks Array of image tasks. Must contain at least one task. All image tasks should be in suspended state.
 @param imageHandler The image handler gets called each time the image is successfully fetched, but it doesn't get called for obsolete tasks.
 @param completionHandler Completion handler that is executed after there are no remaining image tasks that are not either completed or cancelled.
 */
- (nonnull instancetype)initWithImageTasks:(nonnull NSArray /* DFImageTask */ *)tasks imageHandler:(nullable DFCompositeImageTaskImageHandler)imageHandler completionHandler:(nullable DFCompositeImageTaskCompletionHandler)completionHandler NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

/*! Creates image tasks with a given requests by using shared image manager. Then creates and returns composite image task. You must resume it by calling resume method.
 @param requests Array of requests. Must contain at least one request.
 @param imageHandler The image handler gets called each time the image is successfully fetched, but it doesn't get called for obsolete tasks.
 @param completionHandler Completion handler that is executed after there are no remaining image tasks that are not either completed or cancelled.
 */
+ (nullable instancetype)compositeImageTaskWithRequests:(nonnull NSArray *)requests imageHandler:(nullable DFCompositeImageTaskImageHandler)imageHandler completionHandler:(nullable DFCompositeImageTaskCompletionHandler)completionHandler;

/*! Image handler. The image handler gets called each time the image is successfully fetched, but it doesn't get called for obsolete tasks.
 */
@property (nullable, nonatomic, copy) void (^imageHandler)(UIImage *__nullable image, DFImageTask *__nonnull completedTask, DFCompositeImageTask *__nonnull compositeTask);

/*! Completion handler that is executed after there are no remaining image tasks that are not either completed or cancelled.
 */
@property (nullable, nonatomic, copy) void (^completionHandler)(DFCompositeImageTask *__nonnull compositeTask);

/*! Set to YES to enable special handling of obsolete requests. Default value is YES.
 */
@property (nonatomic) BOOL allowsObsoleteRequests;

/*! Array of image tasks that the receiver was initialized with.
 */
@property (nonnull, nonatomic, copy, readonly) NSArray /* DFImageTask */ *imageTasks;

/*! Returns all image requests from the image tasks that the receiver was initialized with.
 */
@property (nonnull, nonatomic, copy, readonly) NSArray /* DFImageRequest */ *imageRequests;

/*! Returns YES if all the requests have completed.
 */
@property (nonatomic, readonly) BOOL isFinished;

/*! Resumes the task.
 */
- (void)resume;

/*! Cancels all image tasks registered with the receiver. Removes image handler and completion handler.
 */
- (void)cancel;

/*! Sets the priority for all image tasks registered with a receiver.
 */
- (void)setPriority:(DFImageRequestPriority)priority;

@end
