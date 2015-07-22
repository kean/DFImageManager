//
//  DFImageManagerImageLoader.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 22/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageRequest;
@class DFImageResponse;
@protocol DFImageFetching;
@protocol DFImageCaching;
@protocol DFImageProcessing;

@interface DFImageManagerImageLoaderTask : NSObject

@end

/*! Private image loader.
 - transparent loading+processing+caching with a single completion block
 - transparent multiplexing
 - offloads work to the background queue
 */
@interface DFImageManagerImageLoader : NSObject

- (nonnull instancetype)initWithFetcher:(nonnull id<DFImageFetching>)fetcher cache:(nullable id<DFImageCaching>)cache processor:(nullable id<DFImageProcessing>)processor processingQueue:(nullable NSOperationQueue *)processingQueue;

- (nonnull DFImageManagerImageLoaderTask *)requestImageForRequest:(nonnull DFImageRequest *)request progressHandler:(void (^__nonnull)(int64_t completedUnitCount, int64_t totalUnitCount))progressHandler completion:(void (^__nonnull)(DFImageResponse *__nullable))completion;

- (void)cancelImageLoaderTask:(nullable DFImageManagerImageLoaderTask *)task;

- (void)updatePriorityForTask:(nullable DFImageManagerImageLoaderTask *)task;

- (nullable DFImageResponse *)cachedResponseForRequest:(nonnull DFImageRequest *)request;

- (nonnull DFImageRequest *)canonicalRequestForRequest:(nonnull DFImageRequest *)request;

- (nonnull id<NSCopying>)processingKeyForRequest:(nonnull DFImageRequest *)request;

@end
