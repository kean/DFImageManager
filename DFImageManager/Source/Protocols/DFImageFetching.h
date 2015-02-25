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


/*! The DFImageFetcher protocol provides the basic structure for performing fetching of images for specific requests. Adopters handle the specifics associated with one of more types of the requests. The main difference between the requests might be a class of the resource.
 @note The role and the structure of the DFImageFetcher protocol is largely inspired by the NSURLProtocol abstract class. The main difference is that NSURLProtocol is a one-shot task for a single request, while DFImageFetcher is a tasks factory.
 */
@protocol DFImageFetching <NSObject>

/*! Inspects the given request and determines whether or not it can be handled.
 */
- (BOOL)canHandleRequest:(DFImageRequest *)request;

/*! Compares two requests for equivalence with regard to fetching the image. Requests should be considered equivalent if image fetcher can handle both requests by the same operation.
 */
- (BOOL)isRequestFetchEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2;

/*! Compares two requests for equivalence with regard to caching the image. The DFImageManager uses this method for memory caching.
 */
- (BOOL)isRequestCacheEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2;

/*! Starts fetching an image for the request. The completion block should always be called, even for the cancelled request. The completion block may be called in any fashion (asynchronously or not) and on any thread.
 @param progressHandler Progress handler that can be called on any thread. Image fetcher that don't report progress should ignore this the handler.
 @param completion Completion handler that can be called on any thread.
 @return The operation that implements fetching. The operation might be nil.
 */
- (NSOperation *)startOperationWithRequest:(DFImageRequest *)request progressHandler:(void (^)(double progress))progressHandler completion:(void (^)(DFImageResponse *response))completion;

@optional

/*! Returns a canonical form of the given request. All DFImageFetcher methods receive requests in a canonical form expect for the -canHandleRequest: method. It is up to each concrete protocol implementation to define what "canonical" means.
 @discussion Some fetcher might support a particular subclass of either DFImageRequest or DFImageRequestOptions. In that case this method might modify the given request to return this subclass in case the base class was used.
 */
- (DFImageRequest *)canonicalRequestForRequest:(DFImageRequest *)request;

@end
