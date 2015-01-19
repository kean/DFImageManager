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


/*! The DFImageFetcher protocol provides the basic structure for performing fetching of images for specific requests. Adopters handle the specifics associated with one of more types of the requests. The main difference between the requests might be a class of the asset.
 @discussion The role and the structure of the DFImageFetcher protocol is largely the same as of the NSURLProtocol abstract class.
 */
@protocol DFImageFetcher <NSObject>

/*! A concrete image fetcher implementation should inspect the given request and determine whether or not the implementation can handle the request.
 @param A request to inspect.
 */
- (BOOL)canHandleRequest:(DFImageRequest *)request;

/*! Compares two requests for equivalence with regard to fetching the image. Requests should be consitered equivalent if image fetcher can handle both requests by the same operation.
 */
- (BOOL)isRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2;

/*! Returns an operation that implements fetching of the image for the request. Should never return nil.
 */
- (NSOperation<DFImageManagerOperation> *)createOperationForRequest:(DFImageRequest *)request;

- (void)enqueueOperation:(NSOperation<DFImageManagerOperation> *)operation;

@end
