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

@class DFImageRequest;
@class DFImageRequestID;
@protocol DFImageManaging;


/*! The execution context of the image request.
 */
@interface DFImageFetchContext : NSObject

/*! Returns requestID created for the request.
 */
@property (nonatomic, readonly) DFImageRequestID *requestID;

/*! Returns YES if the request was completed.
 */
@property (nonatomic, readonly) BOOL isCompleted;

/*! Returns image fetched for the requests.
 */
@property (nonatomic, readonly) UIImage *image;

/*! Returns the information about the status of the request.
 */
@property (nonatomic, readonly) NSDictionary *info;

@end

/*! The DFImageFetchTask manages execution of one or many image requests and provides a single completion block that gets called multiple times. It also stores execution state for each request (see DFImageFetchContext). All requests are executed concurrently.
 @note By default, DFImageFetchTask does not call its completion handler for each of the completed requests. It treats the array of the requests as if the last request was the final image that you would want to display, while the others were the placeholders. The completion handler is guaranteed to be called at least once, even if all of the requests have failed. It also automatically cancels obsolete requests. This entire behavior can be disabled by setting allowsObsoleteRequests property to NO.
 @warning This class is not thread safe and is designed to be used on the main thread.
 */
@interface DFImageFetchTask : NSObject

/*! Initializes composite task with an array of image requests and a completion handler. After you create the task, you must start it by calling start method.
 @param requests Array of requests. Must contain at least one request.
 @param handler Completion block that gets called multiple times, for more info see class description. The completion
 */
- (instancetype)initWithRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler NS_DESIGNATED_INITIALIZER;

/*! Initializes task with an image request and a completion handler. After you create the task, you must start it by calling start method. 
  @param request request. Must not be nil.
 */
- (instancetype)initWithRequest:(DFImageRequest *)request handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler;

/*! Creates and starts task with an array of image requests.
 @param requests Array of requests. Must contain at least one request.
 @param handler Completion block that gets called multiple times, for more info see class description.
 */
+ (DFImageFetchTask *)requestImageForRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler;

/*! Image manager used by the receiver. Set to the shared manager during initialization.
 */
@property (nonatomic) id<DFImageManaging> imageManager;

/*! Set to YES to enable special handling of obsolete requests. Default value is YES. For more info see class notes.
 */
@property (nonatomic) BOOL allowsObsoleteRequests;

/*! Array of requests that the receiver was initialized with.
 */
@property (nonatomic, copy, readonly) NSArray /* DFImageRequest */ *requests;

/*! The time when the request was started (in seconds).
 */
@property (nonatomic, readonly) NSTimeInterval startTime;

/*! The elapsed time from the start of the request (in seconds).
 */
@property (nonatomic, readonly) NSTimeInterval elapsedTime;

/*! Returns YES if all the requests have completed.
 */
@property (nonatomic, readonly) BOOL isFinished;

/*! Starts the task.
 */
- (void)start;

/*! Cancels all the requests registered with the receiver.
 */
- (void)cancel;

/*! Returns context for the given request.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (DFImageFetchContext *)contextForRequest:(DFImageRequest *)request;

/*! Sets the priority for all the requests registered with a receiver.
 */
- (void)setPriority:(DFImageRequestPriority)priority;

@end
