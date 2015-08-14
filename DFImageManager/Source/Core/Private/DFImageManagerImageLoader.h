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

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@class DFImageRequest;
@class DFImageManagerConfiguration;
@protocol DFImageFetching;
@protocol DFImageProcessing;
@protocol DFImageCaching;

typedef void (^DFImageLoaderProgressHandler)(int64_t completedUnitCount, int64_t totalUnitCount);
typedef void (^DFImageLoaderCompletionHandler)(UIImage *__nullable image, NSDictionary *__nullable info, NSError *__nullable error);

@interface DFImageManagerImageLoaderTask : NSObject

@property (atomic, copy) void (^__nullable progressiveImageHandler)(UIImage *__nonnull image);
@property (nonatomic, readonly) int64_t totalUnitCount;
@property (nonatomic, readonly) int64_t completedUnitCount;

@end

/*! Private image loader:
 - transparent loading+processing+caching with a single completion block
 - transparent multiplexing
 - offloads work to the background queue
 */
@interface DFImageManagerImageLoader : NSObject

- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration;

- (nonnull DFImageManagerImageLoaderTask *)startTaskForRequest:(nonnull DFImageRequest *)request progressHandler:(nonnull DFImageLoaderProgressHandler)progressHandler completion:(nonnull DFImageLoaderCompletionHandler)completion;

- (void)cancelTask:(nullable DFImageManagerImageLoaderTask *)task;

- (void)setPriority:(DFImageRequestPriority)priority forTask:(nullable DFImageManagerImageLoaderTask *)task;

- (nullable DFCachedImageResponse *)cachedResponseForRequest:(nonnull DFImageRequest *)request;

- (nonnull DFImageRequest *)canonicalRequestForRequest:(nonnull DFImageRequest *)request;

- (nonnull NSArray *)canonicalRequestsForRequests:(nonnull NSArray *)requests;

- (nonnull id<NSCopying>)processingKeyForRequest:(nonnull DFImageRequest *)request;

@end
