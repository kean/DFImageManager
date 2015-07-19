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

@class DFImageRequest;
@class DFImageResponse;

NS_ASSUME_NONNULL_BEGIN

/*! The DFImageFetching protocol provides the basic structure for performing fetching of images for specific DFImageRequest objects. Classes adopting DFImageFetching protocol handle the specifics associated with one of more types of the image requests.
 @note The role and the structure of the DFImageFetching protocol is largely inspired by the NSURLProtocol abstract class.
 */
@protocol DFImageFetching <NSObject>

/*! Inspects the given request and determines whether the receiver can handle the given request.
 @param request The initial request to be handled. The request is not canonical (see canonicalRequestForRequest: method for more info).
 */
- (BOOL)canHandleRequest:(DFImageRequest *)request;

/*! Compares two requests for equivalence with regard to fetching the image. Requests should be considered equivalent if the image fetcher can handle both requests with a single operation.
 @param request1 The first canonical request.
 @param request2 The second canonical request.
 */
- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2;

/*! Compares two requests for equivalence with regard to caching the image. 
 @note The DFImageManager uses this method for memory caching only, which means that there is no need for filtering out the dynamic part of the request (is there is any). For example, the dynamic part might be a username and password in a URL.
 @param request1 The first canonical request.
 @param request2 The second canonical request.
 */
- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2;

/*! Starts fetching an image for the request.
 @param request The canonical request.
 @param progressHandler Progress handler that can be called on any thread. Image fetcher that don't report progress should ignore this the handler.
 @param completion Completion handler, can be called on any thread.
 @return The operation that implements fetching.
 */
- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^__nullable)(double progress))progressHandler completion:(void (^)(DFImageResponse *response))completion;

@optional

/*! Returns a canonical form of the given request. All DFImageFetching methods receive requests in a canonical form expect for the -canHandleRequest: method.
 @param request The initial request. This method can modify the given request.
 */
- (DFImageRequest *)canonicalRequestForRequest:(DFImageRequest *)request;

@end

NS_ASSUME_NONNULL_END
