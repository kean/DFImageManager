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
@protocol DFImageManagingCore;


/*! Manages execution of multiple image requests. Provides a single completion block that gets called multiple times (similar to PHImageManager completion handler for opportunistic requests).
 @note By default doesn't call completion for completed requests that became obsolete. The request is treated as obsolete if there is at least one completed request in the 'right' subarray of the requests. This behavior can be disabled by settings allowsObsoleteRequests property to NO. The further customization is available via -shouldCallCompletionHandlerForRequest:image:info: and -shouldCancelObsoleteRequest: methods.
 */
@interface DFCompositeImageRequest : NSObject

/*! Image manager used by the composite request. Set to the shared manager during initialization.
 */
@property (nonatomic) id<DFImageManagingCore> imageManager;

/*! Array of requests that the receiver was initialized with.
 */
@property (nonatomic, copy, readonly) NSArray /* DFImageRequest */ *requests;

/*! Array of completed requests.
 */
@property (nonatomic, copy, readonly) NSArray /* DFImageRequest */ *completedRequests;

/*! The time the request was started (in seconds).
 */
@property (nonatomic, readonly) NSTimeInterval startTime;

/*! The elapsed time from the start of the request (in seconds).
 */
@property (nonatomic, readonly) NSTimeInterval elapsedTime;

/*! Set to YES to enable special handling of obsolete requests. Default value is YES. For more info see class notes.
 */
@property (nonatomic) BOOL allowsObsoleteRequests;

/*! Initializes composite request with an array of image requests and a completion handler. After you create the request, you must start it by calling -start method.
 @param requests Array of requests. Must contain at least one request. Requests are deeply copied.
 @param handler Completion block that gets called multiple times based on the number of the requests and the implementation of -shouldCallCompletionHandlerForRequest method.
 */
- (instancetype)initWithRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler NS_DESIGNATED_INITIALIZER;

/*! Creates and starts composite request with an array of image requests.
 @param requests Array of requests. Must contain at least one request. Requests are deeply copied.
 @param handler Completion block that gets called multiple times based on the number of the requests and the implementation of -shouldCallCompletionHandlerForRequest method.
 */
+ (DFCompositeImageRequest *)requestImageForRequests:(NSArray /* DFImageRequest */ *)requests handler:(void (^)(UIImage *image, NSDictionary *info, DFImageRequest *request))handler;

/*! Start all the requests. The requests are executed concurrently.
 */
- (void)start;

/*! Cancels all the requests registered with a receiver.
 */
- (void)cancel;

/*! Cancels given request. Request should be contained the receiver's array of the requests.
 */
- (void)cancelRequest:(DFImageRequest *)request;

/*! Cancels given requests. Requests should be contained the receiver's array of the requests.
 */
- (void)cancelRequests:(NSArray /* DFImageRequest */ *)requests;

/*! Sets the priority for all the requests registered with a receiver.
 */
- (void)setPriority:(DFImageRequestPriority)priority;

@end


@interface DFCompositeImageRequest (SubclassingHooks)

/*! Returns YES in case the composite image request completion handler should be called for the completed request. Default implementation returns YES in case there are no other completed requests in the 'right' requests subarray relative to the given request.
 */
- (BOOL)shouldCallCompletionHandlerForRequest:(DFImageRequest *)request image:(UIImage *)image info:(NSDictionary *)info;

/*! Return YES in case the obsolete request should be canceled. Requests become obsolete when there are any completed requests in the 'right' subarray of requests relative to the given request. Default implementation always returns YES.
 */
- (BOOL)shouldCancelObsoleteRequest:(DFImageRequest *)request;

@end
