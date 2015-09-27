// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

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
@property (nullable, nonatomic) id<DFImageFetching> fetcher;

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

/*! The load progress threshold at which received data is decoded. Default value is 0.15, which means that the received data will be decoded each time next 15% of total bytes is received.
 */
@property (nonatomic) float progressiveImageDecodingThreshold;

/*! Initializes DFImageManagerConfiguration instance with default parameters.
 */
- (nullable instancetype)init;

/*! Returns configuration created with a given fetcher, processor and cache.
 */
+ (nonnull instancetype)configurationWithFetcher:(nonnull id<DFImageFetching>)fetcher processor:(nullable id<DFImageProcessing>)processor cache:(nullable id<DFImageCaching>)cache;

@end


@interface DFImageManagerConfiguration (DFGlobalConfiguration)

/*! If YES allows progressive image decoding. Default value is NO.
 */
+ (void)setAllowsProgressiveImage:(BOOL)allowsProgressiveImage;

/*! If YES allows progressive image decoding. Default value is NO.
 */
+ (BOOL)allowsProgressiveImage;

@end
