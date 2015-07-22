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

#import "DFCachedImageResponse.h"
#import "DFImageCaching.h"
#import "DFImageFetching.h"
#import "DFImageManagerDefines.h"
#import "DFImageManagerImageLoader.h"
#import "DFImageProcessing.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

#pragma mark - DFImageManagerImageLoaderTask

@class _DFImageLoadOperation;

@interface DFImageManagerImageLoaderTask ()

@property (nonnull, nonatomic, readonly) DFImageRequest *request;
@property (nonnull, nonatomic, copy, readonly) DFImageLoaderProgressHandler progressHandler;
@property (nonnull, nonatomic, copy, readonly) DFImageLoaderCompletionHandler completionHandler;
@property (nullable, nonatomic, weak) _DFImageLoadOperation *loadOperation;
@property (nullable, nonatomic, weak) NSOperation *processOperation;
@property (nonatomic) int64_t totalUnitCount;
@property (nonatomic) int64_t completedUnitCount;

@end

@implementation DFImageManagerImageLoaderTask

- (nonnull instancetype)initWithRequest:(nonnull DFImageRequest *)request progressHandler:(nonnull DFImageLoaderProgressHandler)progressHandler completionHandler:(nonnull DFImageLoaderCompletionHandler)completionHandler {
    if (self = [super init]) {
        _request = request;
        _progressHandler = progressHandler;
        _completionHandler = completionHandler;
    }
    return self;
}

@end


#pragma mark - _DFImageRequestKey

@class _DFImageRequestKey;

@protocol _DFImageRequestKeyOwner <NSObject>

- (BOOL)isImageRequestKey:(nonnull _DFImageRequestKey *)lhs equalToKey:(nonnull _DFImageRequestKey *)rhs;

@end

/*! Make it possible to use DFImageRequest as a key in dictionaries (and dictionary-like structures). Requests may be interpreted differently so we compare them using <DFImageFetching> -isRequestFetchEquivalent:toRequest: method and (optionally) similar <DFImageProcessing> method.
 */
@interface _DFImageRequestKey : NSObject <NSCopying>

@property (nonnull, nonatomic, readonly) DFImageRequest *request;
@property (nonatomic, readonly) BOOL isCacheKey;
@property (nullable, nonatomic, weak, readonly) id<_DFImageRequestKeyOwner> owner;

@end

@implementation _DFImageRequestKey {
    NSUInteger _hash;
}

- (nonnull instancetype)initWithRequest:(nonnull DFImageRequest *)request isCacheKey:(BOOL)isCacheKey owner:(nonnull id<_DFImageRequestKeyOwner>)owner {
    if (self = [super init]) {
        _request = request;
        _hash = [request.resource hash];
        _isCacheKey = isCacheKey;
        _owner = owner;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

- (NSUInteger)hash {
    return _hash;
}

- (BOOL)isEqual:(_DFImageRequestKey *)other {
    if (other == self) {
        return YES;
    }
    if (other.owner != self.owner) {
        return NO;
    }
    return [self.owner isImageRequestKey:self equalToKey:other];
}

@end


#pragma mark - _DFImageLoadOperation

@interface _DFImageLoadOperation : NSObject

@property (nonnull, nonatomic, readonly) _DFImageRequestKey *key;
@property (nullable, nonatomic, weak) NSOperation *operation;
@property (nonnull, nonatomic, readonly) NSMutableArray *tasks;
@property (nonatomic) int64_t totalUnitCount;
@property (nonatomic) int64_t completedUnitCount;

@end

@implementation _DFImageLoadOperation

- (nonnull instancetype)initWithKey:(nonnull _DFImageRequestKey *)key {
    if (self = [super init]) {
        _key = key;
        _tasks = [NSMutableArray new];
    }
    return self;
}

- (void)updateOperationPriority {
    if (_operation && _tasks.count) {
        DFImageRequestPriority priority = DFImageRequestPriorityVeryLow;
        for (DFImageManagerImageLoaderTask *task in _tasks) {
            priority = MAX(task.request.options.priority, priority);
        }
        if (_operation.queuePriority != (NSOperationQueuePriority)priority) {
            _operation.queuePriority = (NSOperationQueuePriority)priority;
        }
    }
}

@end


#pragma mark - DFImageManagerImageLoader

#define DFImageCacheKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:YES owner:self]
#define DFImageLoadKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:NO owner:self]

@interface DFImageManagerImageLoader () <_DFImageRequestKeyOwner>
@end

@implementation DFImageManagerImageLoader {
    dispatch_queue_t _queue;
    id<DFImageFetching> _fetcher;
    id<DFImageCaching> _cache;
    id<DFImageProcessing> _processor;
    NSOperationQueue *_processingQueue;
    NSMutableDictionary /* _DFImageLoadKey : _DFImageLoadOperation */ *_loadOperations;
    BOOL _fetcherRespondsToCanonicalRequest;
}

- (nonnull instancetype)initWithFetcher:(nonnull id<DFImageFetching>)fetcher cache:(nullable id<DFImageCaching>)cache processor:(nullable id<DFImageProcessing>)processor processingQueue:(nullable NSOperationQueue *)processingQueue {
    if (self = [super init]) {
        _fetcher = fetcher;
        _cache = cache;
        _processor = processor;
        _processingQueue = processingQueue;
        _loadOperations = [NSMutableDictionary new];
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _fetcherRespondsToCanonicalRequest = [_fetcher respondsToSelector:@selector(canonicalRequestForRequest:)];
    }
    return self;
}

- (nonnull DFImageManagerImageLoaderTask *)startTaskForRequest:(nonnull DFImageRequest *)request progressHandler:(nonnull DFImageLoaderProgressHandler)progressHandler completion:(nonnull DFImageLoaderCompletionHandler)completion {
    DFImageManagerImageLoaderTask *task = [[DFImageManagerImageLoaderTask alloc] initWithRequest:request progressHandler:progressHandler completionHandler:completion];
    dispatch_async(_queue, ^{
        [self _requestImageForTask:task];
    });
    return task;
}

- (void)_requestImageForTask:(DFImageManagerImageLoaderTask *)task {
    _DFImageRequestKey *key = DFImageLoadKeyCreate(task.request);
    _DFImageLoadOperation *operation = _loadOperations[key];
    if (!operation) {
        operation = [[_DFImageLoadOperation alloc] initWithKey:key];
        DFImageManagerImageLoader *__weak weakSelf = self;
        operation.operation = [_fetcher startOperationWithRequest:task.request progressHandler:^(int64_t completedUnitCount, int64_t totalUnitCount) {
            [weakSelf _loadOperation:operation didUpdateProgressWithCompletedUnitCount:completedUnitCount totalUnitCount:totalUnitCount];
        } completion:^(DFImageResponse * __nonnull response) {
            [weakSelf _loadOperation:operation didCompleteWithResponse:response];
        }];
        _loadOperations[key] = operation;
    } else {
        task.progressHandler(task.completedUnitCount, task.totalUnitCount);
    }
    task.loadOperation = operation;
    [operation.tasks addObject:task];
    [operation updateOperationPriority];
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didUpdateProgressWithCompletedUnitCount:(int64_t)completedUnitCount totalUnitCount:(int64_t)totalUnitCount {
    dispatch_async(_queue, ^{
        operation.totalUnitCount = totalUnitCount;
        operation.completedUnitCount = completedUnitCount;
        for (DFImageManagerImageLoaderTask *task in operation.tasks) {
            task.progressHandler(completedUnitCount, totalUnitCount);
        }
    });
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didCompleteWithResponse:(nullable DFImageResponse *)response {
    dispatch_async(_queue, ^{
        DFImageManagerImageLoader *__weak weakSelf = self;
        for (DFImageManagerImageLoaderTask *task in operation.tasks) {
            if ([self _shouldProcessResponse:response]) {
                task.processOperation = [self _processResponse:response forRequest:task.request completion:^(DFImageResponse *processedResponse) {
                    dispatch_async(_queue, ^{
                        task.completionHandler(response);
                    });
                }];
            } else {
                [weakSelf _storeResponse:response forRequest:task.request];
                task.completionHandler(response);
            }
        }
        [operation.tasks removeAllObjects];
        [_loadOperations removeObjectForKey:operation.key];
    });
}

- (void)cancelTask:(nullable DFImageManagerImageLoaderTask *)task {
    dispatch_async(_queue, ^{
        _DFImageLoadOperation *operation = task.loadOperation;
        if (operation) {
            [operation.tasks removeObject:task];
            if (operation.tasks.count == 0) {
                [operation.operation cancel];
                [_loadOperations removeObjectForKey:operation.key];
            } else {
                [operation updateOperationPriority];
            }
        }
        [task.processOperation cancel];
    });
}

- (void)updatePriorityForTask:(nullable DFImageManagerImageLoaderTask *)task {
    dispatch_async(_queue, ^{
        [task.loadOperation updateOperationPriority];
    });
}

#pragma mark Processing

- (NSOperation *)_processResponse:(DFImageResponse *)response forRequest:(nonnull DFImageRequest *)request completion:(void (^__nonnull)(DFImageResponse *processedResponse))completion {
    DFImageManagerImageLoader *__weak weakSelf = self;
    id<DFImageProcessing> processor = _processor;
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
        DFImageResponse *processedResponse = [weakSelf cachedResponseForRequest:request];
        if (!processedResponse) {
            UIImage *processedImage = [processor processedImage:response.image forRequest:request];
            processedResponse = [[DFImageResponse alloc] initWithImage:processedImage error:response.error userInfo:response.userInfo];
            [weakSelf _storeResponse:processedResponse forRequest:request];
        }
        completion(processedResponse);
    }];
    [_processingQueue addOperation:operation];
    return operation;
}

- (BOOL)_shouldProcessResponse:(DFImageResponse *)response {
    if (!response.image || !_processor || !_processingQueue) {
        return NO;
    }
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    if ([response.image isKindOfClass:[DFAnimatedImage class]]) {
        return NO;
    }
#endif
    return YES;
}

#pragma mark Caching

- (nullable DFImageResponse *)cachedResponseForRequest:(nonnull DFImageRequest *)request {
    return request.options.memoryCachePolicy != DFImageRequestCachePolicyReloadIgnoringCache ? [_cache cachedImageResponseForKey:DFImageCacheKeyCreate(request)].response : nil;
}

- (void)_storeResponse:(nullable DFImageResponse *)response forRequest:(nonnull DFImageRequest *)request {
    if (response.image) {
        DFCachedImageResponse *cachedResponse = [[DFCachedImageResponse alloc] initWithResponse:response expirationDate:(CACurrentMediaTime() + request.options.expirationAge)];
        [_cache storeImageResponse:cachedResponse forKey:DFImageCacheKeyCreate(request)];
    }
}

#pragma mark Misc

- (nonnull DFImageRequest *)canonicalRequestForRequest:(nonnull DFImageRequest *)request {
    if (_fetcherRespondsToCanonicalRequest) {
        return [[_fetcher canonicalRequestForRequest:[request copy]] copy];
    }
    return [request copy];
}

- (nonnull id<NSCopying>)processingKeyForRequest:(nonnull DFImageRequest *)request {
    return DFImageCacheKeyCreate(request);
}

#pragma mark <_DFImageRequestKeyOwner>

- (BOOL)isImageRequestKey:(nonnull _DFImageRequestKey *)lhs equalToKey:(nonnull _DFImageRequestKey *)rhs {
    if (lhs.isCacheKey) {
        if (![_fetcher isRequestCacheEquivalent:lhs.request toRequest:rhs.request]) {
            return NO;
        }
        return _processor ? [_processor isProcessingForRequestEquivalent:lhs.request toRequest:rhs.request] : YES;
    } else {
        return [_fetcher isRequestFetchEquivalent:lhs.request toRequest:rhs.request];
    }
}

@end
