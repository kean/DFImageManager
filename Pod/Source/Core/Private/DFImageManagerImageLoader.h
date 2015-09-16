// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageTask;
@class DFImageManagerConfiguration;
@class DFImageManagerImageLoader;

@protocol DFImageManagerImageLoaderDelegate <NSObject>

- (void)imageLoader:(nonnull DFImageManagerImageLoader *)imageLoader imageTask:(nonnull DFImageTask *)imageTask didUpdateProgressWithCompletedUnitCount:(int64_t)completedUnitCount totalUnitCount:(int64_t)totalUnitCount;

- (void)imageLoader:(nonnull DFImageManagerImageLoader *)imageLoader imageTask:(nonnull DFImageTask *)imageTask didCompleteWithImage:(nullable UIImage *)image info:(nullable NSDictionary *)info error:(nullable NSError *)error;

- (void)imageLoader:(nonnull DFImageManagerImageLoader *)imageLoader imageTask:(nonnull DFImageTask *)imageTask didReceiveProgressiveImage:(nonnull UIImage *)image;

@end

/*! Private image loader:
 - transparent loading+processing+caching with a single completion block
 - transparent multiplexing
 - offloads work to the background queue
 */
@interface DFImageManagerImageLoader : NSObject

@property (nullable, nonatomic, weak) id<DFImageManagerImageLoaderDelegate> delegate;

- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration;

- (void)startLoadingForImageTask:(nonnull DFImageTask *)imageTask;

- (void)cancelLoadingForImageTask:(nonnull DFImageTask *)imageTask;

- (void)updateLoadingPriorityForImageTask:(nonnull DFImageTask *)imageTask;

- (nullable DFCachedImageResponse *)cachedResponseForRequest:(nonnull DFImageRequest *)request;

- (nonnull id<NSCopying>)preheatingKeyForRequest:(nonnull DFImageRequest *)request;

@end
