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

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

#pragma mark - DFImageManagerImageLoaderTask

@class _DFImageLoadOperation;

@interface DFImageManagerImageLoaderTask ()

@property (nonnull, nonatomic, readonly) DFImageRequest *request;
@property (nonatomic) DFImageRequestPriority priority;
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
        _priority = request.options.priority;
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
    if (other.owner != _owner) {
        return NO;
    }
    return [_owner isImageRequestKey:self equalToKey:other];
}

@end


#pragma mark - _DFImageLoadOperation

@interface _DFImageLoadOperation : NSObject

@property (nonnull, nonatomic, readonly) _DFImageRequestKey *key;
@property (nullable, nonatomic) NSOperation *operation;
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
            priority = MAX(task.priority, priority);
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
        } completion:^(UIImage *__nullable image, NSDictionary *__nullable info, NSError *__nullable error) {
            [weakSelf _loadOperation:operation didCompleteWithImage:image info:info error:error];
        }];
        _loadOperations[key] = operation;
    } else {
        task.totalUnitCount = operation.totalUnitCount;
        task.completedUnitCount = operation.completedUnitCount;
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
            task.totalUnitCount = operation.totalUnitCount;
            task.completedUnitCount = operation.completedUnitCount;
            task.progressHandler(task.completedUnitCount, task.totalUnitCount);
        }
    });
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didCompleteWithImage:(nullable UIImage *)image info:(nullable NSDictionary *)info error:(nullable NSError *)error {
    dispatch_async(_queue, ^{
        for (DFImageManagerImageLoaderTask *task in operation.tasks) {
            [self _loadTask:task didCompleteWithImage:image info:info error:error];
        }
        [operation.tasks removeAllObjects];
        [_loadOperations removeObjectForKey:operation.key];
    });
}

- (void)_loadTask:(nonnull DFImageManagerImageLoaderTask *)task didCompleteWithImage:(nullable UIImage *)image info:(nullable NSDictionary *)info error:(nullable NSError *)error {
    DFImageManagerImageLoader *__weak weakSelf = self;
    if (image && [self _shouldProcessImage:image]) {
        id<DFImageProcessing> processor = _processor;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            UIImage *processedImage = [weakSelf cachedResponseForRequest:task.request].image;
            if (!processedImage) {
                processedImage = [processor processedImage:image forRequest:task.request];
                [weakSelf _storeImage:processedImage info:info forRequest:task.request];
            }
            dispatch_async(_queue, ^{
                task.completionHandler(processedImage, info, error);
            });
        }];
        [_processingQueue addOperation:operation];
        task.processOperation = operation;
    } else {
        [weakSelf _storeImage:image info:info forRequest:task.request];
        task.completionHandler(image, info, error);
    }
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

- (void)setPriority:(DFImageRequestPriority)priority forTask:(nullable DFImageManagerImageLoaderTask *)task {
    dispatch_async(_queue, ^{
        task.priority = priority;
        [task.loadOperation updateOperationPriority];
    });
}

#pragma mark Processing

- (BOOL)_shouldProcessImage:(nonnull UIImage *)image {
    if (!_processor || !_processingQueue) {
        return NO;
    }
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    if ([image isKindOfClass:[DFAnimatedImage class]]) {
        return NO;
    }
#endif
    return YES;
}

#pragma mark Caching

- (nullable DFCachedImageResponse *)cachedResponseForRequest:(nonnull DFImageRequest *)request {
    return request.options.memoryCachePolicy != DFImageRequestCachePolicyReloadIgnoringCache ? [_cache cachedImageResponseForKey:DFImageCacheKeyCreate(request)] : nil;
}

- (void)_storeImage:(nullable UIImage *)image info:(nullable NSDictionary *)info forRequest:(nonnull DFImageRequest *)request {
    if (image) {
        DFCachedImageResponse *cachedResponse = [[DFCachedImageResponse alloc] initWithImage:image info:info expirationDate:(CACurrentMediaTime() + request.options.expirationAge)];
        [_cache storeImageResponse:cachedResponse forKey:DFImageCacheKeyCreate(request)];
    }
}

#pragma mark Misc

- (nonnull DFImageRequest *)canonicalRequestForRequest:(nonnull DFImageRequest *)request {
    return _fetcherRespondsToCanonicalRequest ? [_fetcher canonicalRequestForRequest:request] : request;
}

- (nonnull NSArray *)canonicalRequestsForRequests:(nonnull NSArray *)requests {
    if (!_fetcherRespondsToCanonicalRequest) {
        return requests;
    }
    NSMutableArray *canonicalRequests = [[NSMutableArray alloc] initWithCapacity:requests.count];
    for (DFImageRequest *request in requests) {
        [canonicalRequests addObject:[self canonicalRequestForRequest:request]];
    }
    return canonicalRequests;
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
