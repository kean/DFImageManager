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

/*! The DFImageManager and the related classes provide an implementation of the DFImageManaging protocol. The role of the DFImageManager is to manage the execution of image tasks by delegating the actual job to the objects, implementing DFImageFetching, DFImageCaching, and DFImageProcessing protocols.
 
 @note Reusing Operations
 
 Image manager automatically reuses fetch operations. It order to enable this functionality you should implement the -isRequestFetchEquivalent:toRequest: method in your DFImageFetching implementation.
 
 @note Cancellation
 
 Image manager cancels fetch operations only when there are no remaining image tasks registered with a given operation.
 
 @note  Memory Caching
 
 Image manager uses cache (object conforming to DFImageCaching protocol) for memory caching. It should be able to lookup cached images based on the image request, but it doesn't know anything about the resources, specific request options, and the way the requests are interpreted and handled. There are three simple rules how image manager stores and retrieves cached images. First, image manager can't use cached images stored by other managers. Second, all resources must implement -hash method. Third, image manager has an intelligent way of creating cache keys that delegate the comparison of image requests to the image fetcher (DFImageFetching) and the image processor (DFImageProcessing). Make sure to implement -isRequestCacheEquivalent:toRequest: method in your DFImageFetching implementation and -isProcessingForRequestEquivalent:toRequest: method in DFImageProcessing implementation.
 
 @note Preheating
 
 The DFImageManager does its best to guarantee that preheating tasks never interfere with regular (non-preheating) tasks. There is a limit of concurrent preheating tasks enforced by DFImageManager. There is also certain (very small) delay when manager starts executing preheating requests. Given that fact, clients don't need to worry about the order in which they start their requests (preheating or not), which comes really handy when you, for example, reload collection view's data and start preheating images at the same time.
 
 The DFImageManager stops multiple similar preheating requests with a single -stopPreheatingImagesForRequests: call.
 */
@interface DFImageManager : NSObject <DFImageManaging>

/*! A copy of the configuration object for this manager (read only). Changing mutable values within the configuration object has no effect on the current manager.
 */
@property (nonnull, nonatomic, copy, readonly) DFImageManagerConfiguration *configuration;

/*! The receivers name.
 */
@property (nullable, nonatomic, copy) NSString *name;

/*! Creates image manager with a specified configuration.
 @param configuration A configuration object that specifies certain behaviours, such as fetching, processing, caching and more. Manager copies the configuration object.
 */
- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end


/*! Dependency injectors for the image manager shared by the application.
 */
@interface DFImageManager (SharedManager)

/*! Returns the shared image manager instance. By default returns the image manager instance created using DFImageManager -createDefaultManager method. An application with more specific needs can create a custom image manager and set it as a shared instance.
 */
+ (nonnull id<DFImageManaging>)sharedManager;

/*! Sets the image manager instance shared by all clients of the current application.
 */
+ (void)setSharedManager:(nonnull id<DFImageManaging>)manager;

/*! Adds the image manager to the current shared manager by composing them together. The added image manager will be the first one to respond to the image requests.
 */
+ (void)addSharedManager:(nonnull id<DFImageManaging>)manager;

@end


@interface DFImageManager (DefaultManager)

/*! Creates default image manager that contains all built-in fetchers.
 @note Supported resources:
 - NSURL with schemes http, https, ftp, file and data (AFNetworking or NSURLSession subspec, AFNetworking is used by default when available)
 - PHAsset and NSURL with scheme com.github.kean.photos-kit (PhotosKit subspec)
 */
+ (nonnull id<DFImageManaging>)createDefaultManager;

@end
