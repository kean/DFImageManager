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

#import "DFOperation.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DFImageRequest;
@class DFImageRequestID;
@protocol DFImageManagingCore;


/*! The DFImageFetchOperation wraps DFImageManager API into an NSOperation providing users with a power of NSOperation.
 @warning The DFImageFetchOperation adds additional overhead so be cautions when using it for performance-critical tasks. In most situations you'd be better of with DFImageManaging API itself.
 @warning Using NSOperationQueue and limiting the number of concurrent image fetch operations might not be a good idea, especially if you want NSURLSession cache lookups to execute independent of network connections.
 */
@interface DFImageFetchOperation : DFOperation

/*! Image manager used by the composite operation. Set to the shared manager during initialization.
 */
@property (nonatomic) id<DFImageManagingCore> imageManager;

/*! The request that the receiver was initialized with.
 */
@property (nonatomic, readonly) DFImageRequest *request;

/*! The requestID identifying request.
 */
@property (nonatomic, readonly) DFImageRequestID *requestID;

/*! The loaded image.
 */
@property (nonatomic, readonly) UIImage *image;

/*! The info dictionary provides information about the status of the request. See the definitions of DFImageInfo*Key strings for possible keys and values.
 */
@property (nonatomic, readonly) NSDictionary *info;

/*! Initialized operation with a request and a completion block.
 */
- (instancetype)initWithRequest:(DFImageRequest *)request completion:(void (^)(UIImage *image, NSDictionary *info))completion NS_DESIGNATED_INITIALIZER;

@end
