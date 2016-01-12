// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCachedImageResponse.h"
#import "DFImageCaching.h"
#import "DFImageDecoder.h"
#import "DFImageDecoding.h"
#import "DFImageFetching.h"
#import "DFImageFetchingOperation.h"
#import "DFImageManagerConfiguration.h"
#import "DFImageManagerDefines.h"
#import "DFImageManagerLoader.h"
#import "DFImageProcessing.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageTask.h"
#import "DFProgressiveImageDecoder.h"

#pragma mark - _DFImageLoaderTask

@class _DFImageLoadOperation;

@interface _DFImageLoaderTask : NSObject

@property (nonnull, nonatomic, readonly) DFImageTask *imageTask;
@property (nonnull, nonatomic, readonly) DFImageRequest *request; // dynamic
@property (nullable, nonatomic, weak) _DFImageLoadOperation *loadOperation;
@property (nullable, nonatomic, weak) NSOperation *processOperation;

@end

@implementation _DFImageLoaderTask

- (nonnull instancetype)initWithImageTask:(nonnull DFImageTask *)imageTask {
    if (self = [super init]) {
        _imageTask = imageTask;
    }
    return self;
}

- (DFImageRequest * __nonnull)request {
    return self.imageTask.request;
}

@end


#pragma mark - _DFImageRequestKey

@class _DFImageRequestKey;

@protocol _DFImageRequestKeyOwner <NSObject>

- (BOOL)isImageRequestKey:(nonnull _DFImageRequestKey *)lhs equalToKey:(nonnull _DFImageRequestKey *)rhs;

@end

/*! Make it possible to use DFImageRequest as a key in dictionaries, tables, etc. Requests are compared using -[DFImageFetching isRequestFetchEquivalent:toRequest:] and -[DFImageProcessing isProcessingForRequestEquivalent:toRequest:] methods.
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

/*! Wrapper for <DFImageFetchingOperation> operation.
 */
@interface _DFImageLoadOperation : NSObject

@property (nonnull, nonatomic, readonly) _DFImageRequestKey *key;
@property (nullable, nonatomic) id<DFImageFetchingOperation> fetchOperation;
@property (nonnull, nonatomic, readonly) NSMutableArray *tasks;
@property (nonatomic) int64_t totalUnitCount;
@property (nonatomic) int64_t completedUnitCount;
@property (nonatomic) DFProgressiveImageDecoder *progressiveImageDecoder;

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
    if (_fetchOperation && _tasks.count) {
        DFImageRequestPriority priority = DFImageRequestPriorityLow;
        for (_DFImageLoaderTask *task in _tasks) {
            priority = MAX(task.imageTask.priority, priority);
        }
        [_fetchOperation setImageFetchingPriority:priority];
    }
}

@end


#pragma mark - DFImageManagerLoader

#define DFImageCacheKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:YES owner:self]
#define DFImageLoadKeyCreate(request) [[_DFImageRequestKey alloc] initWithRequest:request isCacheKey:NO owner:self]

@interface DFImageManagerLoader () <_DFImageRequestKeyOwner>

@property (nonnull, nonatomic, readonly) DFImageManagerConfiguration *conf;
@property (nonnull, nonatomic, readonly) NSMutableDictionary /* DFImageTask : _DFImageLoaderTask */ *executingTasks;
@property (nonnull, nonatomic, readonly) NSMutableDictionary /* _DFImageRequestKey : _DFImageLoadOperation */ *loadOperations;
@property (nonnull, nonatomic, readonly) dispatch_queue_t queue;
@property (nonnull, nonatomic, readonly) NSOperationQueue *decodingQueue;

@end

@implementation DFImageManagerLoader

- (nonnull instancetype)initWithConfiguration:(nonnull DFImageManagerConfiguration *)configuration {
    NSParameterAssert(configuration);
    if (self = [super init]) {
        _conf = [configuration copy];
        _executingTasks = [NSMutableDictionary new];
        _loadOperations = [NSMutableDictionary new];
        _queue = dispatch_queue_create([[NSString stringWithFormat:@"%@-queue-%p", [self class], self] UTF8String], DISPATCH_QUEUE_SERIAL);
        _decodingQueue = [NSOperationQueue new];
        _decodingQueue.maxConcurrentOperationCount = 1; // Serial queue
    }
    return self;
}

- (void)startLoadingForImageTask:(nonnull DFImageTask *)imageTask {
    dispatch_async(_queue, ^{
        _DFImageLoaderTask *loaderTask = [[_DFImageLoaderTask alloc] initWithImageTask:imageTask];
        _executingTasks[imageTask] = loaderTask;
        [self _startLoadOperationForTask:loaderTask];
    });
}

- (void)_startLoadOperationForTask:(nonnull _DFImageLoaderTask *)task {
    _DFImageRequestKey *key = DFImageLoadKeyCreate(task.request);
    _DFImageLoadOperation *operation = _loadOperations[key];
    if (!operation) { // Couldn't find existing operation with equivalent image request
        operation = [[_DFImageLoadOperation alloc] initWithKey:key];
        typeof(self) __weak weakSelf = self;
        operation.fetchOperation = [_conf.fetcher startOperationWithRequest:task.request progressHandler:^(NSData *__nullable data, int64_t completedUnitCount, int64_t totalUnitCount) {
            [weakSelf _loadOperation:operation didUpdateProgressWithData:data completedUnitCount:completedUnitCount totalUnitCount:totalUnitCount];
        } completion:^(NSData *__nullable data, NSDictionary *__nullable info, NSError *__nullable error) {
            [weakSelf _loadOperation:operation didCompleteWithData:data info:info error:error];
        }];
        _loadOperations[key] = operation;
    } else {
        [self.delegate imageLoader:self imageTask:task.imageTask didUpdateProgressWithCompletedUnitCount:operation.completedUnitCount totalUnitCount:operation.totalUnitCount];
    }
    task.loadOperation = operation;
    [operation.tasks addObject:task];
    [operation updateOperationPriority];
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didUpdateProgressWithData:(NSData *__nullable)data completedUnitCount:(int64_t)completedUnitCount totalUnitCount:(int64_t)totalUnitCount {
    dispatch_async(_queue, ^{
        // update progress
        operation.totalUnitCount = totalUnitCount;
        operation.completedUnitCount = completedUnitCount;
        for (_DFImageLoaderTask *task in operation.tasks) {
            [self.delegate imageLoader:self imageTask:task.imageTask didUpdateProgressWithCompletedUnitCount:operation.completedUnitCount totalUnitCount:operation.totalUnitCount];
        }
        // progressive image decoding
        if (![DFImageManagerConfiguration allowsProgressiveImage]) {
            return;
        }
        if (completedUnitCount >= totalUnitCount) {
            [operation.progressiveImageDecoder invalidate];
            return;
        }
        DFProgressiveImageDecoder *decoder = operation.progressiveImageDecoder;
        if (!decoder) {
            decoder = [[DFProgressiveImageDecoder alloc] initWithQueue:_decodingQueue decoder:_conf.decoder];
            decoder.threshold = _conf.progressiveImageDecodingThreshold;
            decoder.totalByteCount = totalUnitCount;
            typeof(self) __weak weakSelf = self;
            _DFImageLoadOperation *__weak weakOp = operation;
            decoder.handler = ^(UIImage *__nonnull image) {
                [weakSelf _loadOperation:weakOp didDecodePartialImage:image];
            };
            operation.progressiveImageDecoder = decoder;
        }
        [decoder appendData:data];
        for (_DFImageLoaderTask *task in operation.tasks) {
            if (task.imageTask.progressiveImageHandler && task.request.options.allowsProgressiveImage) {
                [decoder resume];
                break;
            }
        }
    });
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didDecodePartialImage:(nonnull UIImage *)image {
    dispatch_async(_queue, ^{
        for (_DFImageLoaderTask *task in operation.tasks) {
            if ([self _shouldProcessImage:image forRequest:task.request partial:YES]) {
                typeof(self) __weak weakSelf = self;
                id<DFImageProcessing> processor = _conf.processor;
                [_conf.processingQueue addOperationWithBlock:^{
                    UIImage *processedImage = [processor processedImage:image forRequest:task.request partial:YES];
                    if (processedImage) {
                        [weakSelf.delegate imageLoader:weakSelf imageTask:task.imageTask didReceiveProgressiveImage:processedImage];
                    }
                }];
            } else {
                [self.delegate imageLoader:self imageTask:task.imageTask didReceiveProgressiveImage:image];
            }
        }
    });
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didCompleteWithData:(nullable NSData *)data info:(nullable NSDictionary *)info error:(nullable NSError *)error {
    if (error || !data.length) {
        [self _loadOperation:operation didCompleteWithImage:nil info:info error:error];
    }
    else {
        typeof(self) __weak weakSelf = self;
        [_decodingQueue addOperationWithBlock:^{
            UIImage *image = [weakSelf.conf.decoder imageWithData:data partial:NO];
            [weakSelf _loadOperation:operation didCompleteWithImage:image info:info error:error];
        }];
    }
}

- (void)_loadOperation:(nonnull _DFImageLoadOperation *)operation didCompleteWithImage:(nullable UIImage *)image info:(nullable NSDictionary *)info error:(nullable NSError *)error {
    dispatch_async(_queue, ^{
        for (_DFImageLoaderTask *task in operation.tasks) {
            [self _loadTask:task processImage:image info:info error:error];
        }
        [operation.tasks removeAllObjects];
        operation.fetchOperation = nil;
        [self _removeImageLoadOperation:operation];
    });
}

- (void)_loadTask:(nonnull _DFImageLoaderTask *)task processImage:(nullable UIImage *)image info:(nullable NSDictionary *)info error:(nullable NSError *)error {
    if (image && [self _shouldProcessImage:image forRequest:task.request partial:NO]) {
        typeof(self) __weak weakSelf = self;
        id<DFImageProcessing> processor = _conf.processor;
        NSOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
            UIImage *processedImage = [weakSelf cachedResponseForRequest:task.request].image;
            if (!processedImage) {
                processedImage = [processor processedImage:image forRequest:task.request partial:NO];
                [weakSelf _storeImage:processedImage info:info forRequest:task.request];
            }
            [weakSelf _loadTask:task didCompleteWithImage:processedImage info:info error:error];
        }];
        [_conf.processingQueue addOperation:operation];
        task.processOperation = operation;
    } else {
        [self _storeImage:image info:info forRequest:task.request];
        [self _loadTask:task didCompleteWithImage:image info:info error:error];
    }
}

- (void)_loadTask:(nonnull _DFImageLoaderTask *)task didCompleteWithImage:(nullable UIImage *)image info:(nullable NSDictionary *)info error:(nullable NSError *)error {
    dispatch_async(_queue, ^{
        [self.delegate imageLoader:self imageTask:task.imageTask didCompleteWithImage:image info:info error:error];
        [_executingTasks removeObjectForKey:task.imageTask];
    });
}

- (void)cancelLoadingForImageTask:(nonnull DFImageTask *)imageTask {
    dispatch_async(_queue, ^{
        _DFImageLoaderTask *loaderTask = _executingTasks[imageTask];
        _DFImageLoadOperation *operation = loaderTask.loadOperation;
        if (operation) {
            [operation.tasks removeObject:loaderTask];
            if (operation.tasks.count == 0) {
                [operation.fetchOperation cancelImageFetching];
                operation.fetchOperation = nil;
                [self _removeImageLoadOperation:operation];
            } else {
                [operation updateOperationPriority];
            }
        }
        [loaderTask.processOperation cancel];
        [_executingTasks removeObjectForKey:imageTask];
    });
}

- (void)updateLoadingPriorityForImageTask:(nonnull DFImageTask *)imageTask {
    dispatch_async(_queue, ^{
        _DFImageLoaderTask *loaderTask = _executingTasks[imageTask];
        [loaderTask.loadOperation updateOperationPriority];
    });
}

- (void)_removeImageLoadOperation:(nonnull _DFImageLoadOperation *)operation {
    if (_loadOperations[operation.key] == operation) {
        [_loadOperations removeObjectForKey:operation.key];
    }
}

#pragma mark Misc

- (BOOL)_shouldProcessImage:(nonnull UIImage *)image forRequest:(nonnull DFImageRequest *)request partial:(BOOL)partial {
    if (!_conf.processor || !_conf.processingQueue) {
        return NO;
    }
    if ([_conf.processor respondsToSelector:@selector(shouldProcessImage:forRequest:partial:)]) {
        return [_conf.processor shouldProcessImage:image forRequest:request partial:partial];
    }
    return YES;
}

- (nullable DFCachedImageResponse *)cachedResponseForRequest:(nonnull DFImageRequest *)request {
    return request.options.memoryCachePolicy != DFImageRequestCachePolicyReloadIgnoringCache ? [_conf.cache cachedImageResponseForKey:DFImageCacheKeyCreate(request)] : nil;
}

- (void)_storeImage:(nullable UIImage *)image info:(nullable NSDictionary *)info forRequest:(nonnull DFImageRequest *)request {
    if (image) {
        DFCachedImageResponse *cachedResponse = [[DFCachedImageResponse alloc] initWithImage:image info:info expirationDate:(CFAbsoluteTimeGetCurrent() + request.options.expirationAge)];
        [_conf.cache storeImageResponse:cachedResponse forKey:DFImageCacheKeyCreate(request)];
    }
}

- (nonnull id<NSCopying>)preheatingKeyForRequest:(nonnull DFImageRequest *)request {
    return DFImageCacheKeyCreate(request);
}

#pragma mark <_DFImageRequestKeyOwner>

- (BOOL)isImageRequestKey:(nonnull _DFImageRequestKey *)lhs equalToKey:(nonnull _DFImageRequestKey *)rhs {
    if (lhs.isCacheKey) {
        if (![_conf.fetcher isRequestCacheEquivalent:lhs.request toRequest:rhs.request]) {
            return NO;
        }
        return _conf.processor ? [_conf.processor isProcessingForRequestEquivalent:lhs.request toRequest:rhs.request] : YES;
    } else {
        return [_conf.fetcher isRequestFetchEquivalent:lhs.request toRequest:rhs.request];
    }
}

@end
