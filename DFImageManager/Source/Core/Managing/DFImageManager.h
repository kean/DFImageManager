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

#import "DFImageManaging.h"
#import <Foundation/Foundation.h>

@class DFImageManagerConfiguration;

/*! The DFImageManager and the related classes provides an implementation of the DFImageManaging protocol. The role of the DFImageManager is to manage the execution of image requests by delegating the actual job to a classes, implementing DFImageFetching, DFImageCaching, and DFImageProcessing protocols.
 
 @note Completion Block
 
 Completion block is guaranteed to be called on the main thread. Image manager can call a completion block synchronously if the requested image can be retrieved from the memory cache and the request was made on the main thread. This behavior can be disabled using DFImageManagerConfiguration.
 
 @note Reusing Operations
 
 Image manager automatically reuses fetch operations. It order to enable this functionality you should implement the -isRequestFetchEquivalent:toRequest: method in your <DFImageFetching> implementation.
 
 @note Cancellation
 
 Image manager cancels managed operations only when there are no remaining handlers. This rule applies for both fetch and processing operations.
 
 @note  Memory Caching
 
 Image manager uses cache (<DFImageCaching>) specified in the  configuration for memory caching. It should be able to lookup cached images based on the image request, but it doesn't know anything about the resources, specific request options, and the way the requests are interpreted and handled. There are three simple rules how image manager stores and retrieves cached images. First, image manager can't use cached images stored by other managers if they share the same cache instance. Second, all resources must implement -hash method. Third, image manager has an intelligent way of creating cache keys that delegate the comparison of image requests to the image fetcher (<DFImageFetching>) and the image processor (<DFImageProcessing>). Make sure to implement al least -isRequestCacheEquivalent:toRequest: method in your <DFImageFetching> implementation and -isProcessingForRequestEquivalent:toRequest: method in <DFImageProcessing> implementation.
 
 @note Preheating
 
 The DFImageManager does its best to guarantee that preheating requests never interfere with regular (non-preheating) requests. There is a limit of concurrent preheating requests enforced by DFImageManager. There is also certain (very small) delay when manager starts executing preheating requests. Given that fact, clients don't need to worry about the order in which they start their requests (preheating or not), which comes really handy when you, for example, reload collection view's data and start preheating and requesting multiple images at the same time.
 
 The DFImageManager stops multiple similar preheating requests with a single -stopPreheatingImagesForRequests: call.
 */
@interface DFImageManager : NSObject <DFImageManaging>

/*! A copy of the configuration object for this manager (read only). Changing mutable values within the configuration object has no effect on the current manager.
 */
@property (nonatomic, copy, readonly) DFImageManagerConfiguration *configuration;

/*! The receivers name.
 */
@property (nonatomic) NSString *name;

/*! Creates image manager with a specified configuration.
 @param configuration A configuration object that specifies certain behaviors, such as fetching, processing, caching and more. Manager copies the configuration object.
 */
- (instancetype)initWithConfiguration:(DFImageManagerConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

@end


/*! Dependency injectors that set the image manager shared by the application.
 */
@interface DFImageManager (SharedManager)

/*! Returns the shared image manager instance. By default returns the image manager instance created using DFImageManager -createDefaultManager method. An application with more specific needs can create a custom image manager and set it as a shared instance.
 */
+ (id<DFImageManaging>)sharedManager;

/*! Sets the image manager instance shared by all clients of the current process.
 */
+ (void)setSharedManager:(id<DFImageManaging>)manager;

/*! Adds the image manager to the current shared manager by composing them together. The added image manager will be the first one to respond to the image requests.
 */
+ (void)addSharedManager:(id<DFImageManaging>)manager;

@end


@interface DFImageManager (DefaultManager)

/*! Creates default image manager that contains all built-in fetchers.
 @note Supported assets:

 - NSURL with schemes http, https, ftp, file and data (AFNetworking or NSURLSession subspec, AFNetworking is used by default when available)
 
 - PHAsset and NSURL with scheme com.github.kean.photos-kit (PhotosKit subspec)
 
 - ALAsset, DFALAsset and NSURL with scheme assets-library (AssetsLibrary subspec)
 */
+ (id<DFImageManaging>)createDefaultManager;

@end
