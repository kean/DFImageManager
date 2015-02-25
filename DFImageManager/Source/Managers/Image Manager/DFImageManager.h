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


/*! The DFImageManager and the related classes provides an implementation of the DFImageManaging protocol.
 @note Image manager uses cache (<DFImageCaching>) specified in the  configuration for memory caching. It should be able to lookup cached images based on the image request, but it doesn't know anything about the resources, specific request options, the way the requests are interpreted and handled and other factors. There are three simple rules how image manager stores and retrieves cached images. First, image manager can't use cached images stored by other managers if they share the same cache instance (which makes all the sense). Second, all resources must implement -hash method. Third, image manager has an intelligent way of creating cache keys that delegate the comparison of image requests to the image fetcher (<DFImageFetching>) and the image processor (<DFImageProcessing>). Make sure to implement al least -isRequestCacheEquivalent:toRequest: method in your <DFImageFetching> implementation and -isProcessingForRequestEquivalent:toRequest: method in <DFImageProcessing> implementation.
 @note Image manager automatically reuses fetch operations and processing operations. It order to enable this functionality you should implement the -isRequestFetchEquivalent:toRequest: method in your <DFImageFetching> implementation and -isProcessingForRequestEquivalent:toRequest: method in <DFImageProcessing> implementation.
 */
@interface DFImageManager : NSObject <DFImageManagingCore>

/*! A copy of the configuration object for this manager (read only). Changing mutable values within the configuration object has no effect on the current manager.
 */
@property (nonatomic, copy, readonly) DFImageManagerConfiguration *configuration;

/*! Creates image manager with a specified configuration.
 @param configuration A configuration object that specifies certain behaviors, such as fetching, processing, caching and more. Manager copies the configuration object.
 */
- (instancetype)initWithConfiguration:(DFImageManagerConfiguration *)configuration NS_DESIGNATED_INITIALIZER;

#pragma mark Dependency Injectors

/*! Returns the shared image manager instance. By default returns the image manager instance created using DFImageManager -createDefaultManager method. An application with more specific needs can create a custom image manager and set it as a shared instance.
 */
+ (id<DFImageManaging>)sharedManager;

/*! Sets the image manager instance shared by all clients of the current process.
 */
+ (void)setSharedManager:(id<DFImageManaging>)manager;

@end


/*! The DFImageManager category that implements convenience methods declared in DFImageManaging protocol.
 */
@interface DFImageManager (Convenience) <DFImageManaging>

@end


@interface DFImageManager (DefaultManager)

/*! Creates default image manager that contains all built-in fetchers.
 @note Supported assets:

 - NSURL with schemes http, https, ftp, file and data
 
 - PHAsset and NSURL with scheme com.github.kean.photos-kit
 
 - ALAsset, DFALAsset and NSURL with scheme assets-library
 */
+ (id<DFImageManaging>)createDefaultManager;

@end
