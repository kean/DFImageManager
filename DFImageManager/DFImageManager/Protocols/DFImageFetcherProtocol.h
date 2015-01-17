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

#import <Foundation/Foundation.h>

@protocol DFImageManagerOperation;

@class DFImageRequestOptions;
@class DFImageRequest;


/*! Factory for multiple image provider components.
 */
@protocol DFImageFetcher <NSObject>

/*! A concrete image fetcher implementation should inspect the given request and determine whether or not the implementation can handle the request.
 */
- (BOOL)canHandleRequest:(DFImageRequest *)request;

/*! Compares two requests for equivalence with regard to fetching the image. Requests should be consitered equivalent if image fetcher can handle both requests by the same operation.
 */
- (BOOL)isRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2;

/*! Return nil if no work is required.
 */
- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request;

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation;

@end
