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

@protocol DFImageCaching;
@protocol DFImageFetching;
@protocol DFImageProcessing;

NS_ASSUME_NONNULL_BEGIN

/*! An DFImageManagerConfiguration object defines the behaviour and policies to use when retrieving images using DFImageManager object.
 */
@interface DFImageManagerConfiguration : NSObject <NSCopying>

/*! The image fetcher the receiver was initialized with.
 */
@property (nonatomic) id<DFImageFetching> fetcher;

/*! The image processor.
 */
@property (nullable, nonatomic) id<DFImageProcessing> processor;

/*! Operation queue used for executing image processing operations (see DFImageProcessing protocol).
 */
@property (nonatomic) NSOperationQueue *processingQueue;

/*! Memory cache that stores processed images.
  @note It's a good idea to implement DFImageProcessing and DFImageCaching in that same object.
 */
@property (nullable, nonatomic) id<DFImageCaching> cache;

/*! Maximum number of preheating requests that are allowed to execute concurrently.
 */
@property (nonatomic) NSUInteger maximumConcurrentPreheatingRequests;

/*! Returns a DFImageManagerConfiguration initialized with a given image fetcher.
 */
- (instancetype)initWithFetcher:(id<DFImageFetching>)fetcher NS_DESIGNATED_INITIALIZER;

/*! Returns configuration created with a given image fetcher.
 */
+ (instancetype)configurationWithFetcher:(id<DFImageFetching>)fetcher;

/*! Returns configuration created with a given fetcher, processor and cache.
 */
+ (instancetype)configurationWithFetcher:(id<DFImageFetching>)fetcher processor:(nullable id<DFImageProcessing>)processor cache:(nullable id<DFImageCaching>)cache;

@end

NS_ASSUME_NONNULL_END
