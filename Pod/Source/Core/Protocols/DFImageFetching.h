// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@protocol DFImageFetchingOperation;
@class DFImageRequest;

typedef void (^DFImageFetchingProgressHandler)(NSData *__nullable data, int64_t completedUnitCount, int64_t totalUnitCount);
typedef void (^DFImageFetchingCompletionHandler)(NSData *__nullable data, NSDictionary *__nullable info, NSError *__nullable error);

/*! The DFImageFetching protocol provides the basic structure for performing fetching of image data for specific DFImageRequest objects. Classes adopting DFImageFetching protocol handle the specifics associated with one of more types of the image requests.
 @note The role and the structure of the DFImageFetching protocol is largely inspired by the NSURLProtocol abstract class.
 */
@protocol DFImageFetching <NSObject>

/*! Inspects the given request and determines whether the receiver can handle the given request.
 */
- (BOOL)canHandleRequest:(nonnull DFImageRequest *)request;

/*! Compares two requests for equivalence with regard to fetching the image data. Requests should be considered equivalent if the image fetcher can handle both requests with a single operation.
 */
- (BOOL)isRequestFetchEquivalent:(nonnull DFImageRequest *)request1 toRequest:(nonnull DFImageRequest *)request2;

/*! Compares two requests for equivalence with regard to caching the image data.
 @note The DFImageManager uses this method for memory caching only, which means that there is no need for filtering out the dynamic part of the request (is there is any). For example, the dynamic part might be a username and password in a URL.
 */
- (BOOL)isRequestCacheEquivalent:(nonnull DFImageRequest *)request1 toRequest:(nonnull DFImageRequest *)request2;

/*! Starts fetching an image data for the request.
 @param progressHandler Progress handler that can be called on any thread. Image fetcher that don't report progress should ignore this the handler.
 @param completion Completion handler, can be called on arbitrary thread.
 */
- (nonnull id<DFImageFetchingOperation>)startOperationWithRequest:(nonnull DFImageRequest *)request progressHandler:(nullable DFImageFetchingProgressHandler)progressHandler completion:(nullable DFImageFetchingCompletionHandler)completion;

@optional

/*! Remove all cached images.
 */
- (void)removeAllCachedImages;

/*! Invalidates the reciever.
 */
- (void)invalidate;

@end
