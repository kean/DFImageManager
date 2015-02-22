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
@protocol DFImageManagingCore;


/*! The execution context of the image request inside the composite request.
 @note The DFImageFetchOperation is not used here for performance reasons.
 */
@interface DFCompositeImageRequestContext : NSObject

@property (nonatomic, readonly) DFImageRequestID *requestID;
@property (nonatomic, readonly) BOOL isCompleted;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSDictionary *info;

/*! Initializes context with a given request ID, which might be nil.
 */
- (instancetype)initWithRequestID:(DFImageRequestID *)requestID NS_DESIGNATED_INITIALIZER;

@end

/*! The DFCompositeImageFetchOperation manages execution of multiple image requests. Provides a single completion block that gets called multiple times (similar to PHImageManager completion handler for opportunistic requests). All requests are executed concurrently.
 @note By default, DFCompositeImageFetchOperation does not call its completion handler for each of the completed requests. Instead, it does just what you would expect - it treats the array of the requests as if the last request was the final image that you would want to display, while the others were the placeholders. The completion handler is guaranteed to be called at least once, even if all of the requests have failed. It also automatically cancels obsolete requests. The entire behavior can be disabled by setting allowsObsoleteRequests property to NO before starting the composite operation.
  @note The DFCompositeImageFetchOperation doesn't use DFImageFetchOperation for performance reasons, the overhead of the composite operation should be as low as possible.
 */
@interface DFCompositeImageFetchOperation : NSObject

/*! Initializes composite operation with an array of image requests and a completion handler. After you create the request, you must start it by calling -start method.
 @param requests Array of requests. Must contain at least one request.
 @param handler Completion block that gets called multiple times, for more info see class description.
 */
- (instancetype)initWithRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler NS_DESIGNATED_INITIALIZER;

/*! Creates and starts composite operation with an array of image requests.
 @param requests Array of requests. Must contain at least one request.
 @param handler Completion block that gets called multiple times, for more info see class description.
 */
+ (DFCompositeImageFetchOperation *)requestImageForRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler;

/*! Image manager used by the composite operation. Set to the shared manager during initialization.
 */
@property (nonatomic) id<DFImageManagingCore> imageManager;

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

/*! Returns YES if all the operations have finished.
 */
@property (nonatomic, readonly) BOOL isFinished;

/*! Start all the requests. The requests are wrapped into DFImageFetchOperation objects and executed on the receiver's operation queue.
 */
- (void)start;

/*! Cancels all the requests registered with a receiver.
 */
- (void)cancel;

/*! Returns operation for the given request.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (DFCompositeImageRequestContext *)contextForRequest:(DFImageRequest *)request;

/*! Sets the priority for all the requests registered with a receiver.
 */
- (void)setPriority:(DFImageRequestPriority)priority;

@end


/*! Methods used during obsolete requests handling.
 */
@interface DFCompositeImageFetchOperation (ObsoleteRequests)

/*! Returns YES if the request is completed successfully. The request is considered successful if the image was fetched.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)isRequestSuccessful:(DFImageRequest *)request;

/*! Returns YES if the request is obsolete. The request is considered obsolete if there is at least one successfully completed request in the 'right' subarray of the requests.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)isRequestObsolete:(DFImageRequest *)request;

/*! Returns YES if all the requests are completed.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)isRequestFinal:(DFImageRequest *)request;

/*! Return YES in case the obsolete request should be canceled. Default implementation always returns YES.
 @param request Request should be contained by the receiver's array of the requests.
 */
- (BOOL)shouldCancelObsoleteRequest:(DFImageRequest *)request;

@end
