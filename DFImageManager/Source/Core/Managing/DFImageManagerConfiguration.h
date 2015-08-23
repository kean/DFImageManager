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
@protocol DFImageDecoding;
@protocol DFImageProcessing;

/*! An DFImageManagerConfiguration object defines the behaviour and policies to use when retrieving images using DFImageManager object.
 */
@interface DFImageManagerConfiguration : NSObject <NSCopying>

/*! The image fetcher the receiver was initialized with.
 */
@property (nonnull, nonatomic) id<DFImageFetching> fetcher;

/*! The image decoder.
 */
@property (nullable, nonatomic) id<DFImageDecoding> decoder;

/*! The image processor.
 */
@property (nullable, nonatomic) id<DFImageProcessing> processor;

/*! Operation queue used for executing image processing operations (see DFImageProcessing protocol).
 */
@property (nullable, nonatomic) NSOperationQueue *processingQueue;

/*! Memory cache that stores processed images.
  @note It's a good idea to implement DFImageProcessing and DFImageCaching in that same object.
 */
@property (nullable, nonatomic) id<DFImageCaching> cache;

/*! Maximum number of preheating requests that are allowed to execute concurrently.
 */
@property (nonatomic) NSUInteger maximumConcurrentPreheatingRequests;

/*! If YES allows progressive image decoding. Default value is NO.
 */
@property (nonatomic) BOOL allowsProgressiveImage;

/*! The load progress threshold at which received data is decoded. Default value is 0.15, which means that the received data will be decoded each time next 15% of total bytes is received.
 */
@property (nonatomic) float progressiveImageDecodingThreshold;

/*! Returns a DFImageManagerConfiguration initialized with a given image fetcher.
 */
- (nonnull instancetype)initWithFetcher:(nonnull id<DFImageFetching>)fetcher NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

/*! Returns configuration created with a given image fetcher.
 */
+ (nonnull instancetype)configurationWithFetcher:(nonnull id<DFImageFetching>)fetcher;

/*! Returns configuration created with a given fetcher, processor and cache.
 */
+ (nonnull instancetype)configurationWithFetcher:(nonnull id<DFImageFetching>)fetcher processor:(nullable id<DFImageProcessing>)processor cache:(nullable id<DFImageCaching>)cache;

@end
