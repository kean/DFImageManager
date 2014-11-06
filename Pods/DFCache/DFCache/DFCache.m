// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

#import "DFCache.h"
#import "DFCachePrivate.h"
#import "DFCacheTimer.h"
#import "NSURL+DFExtendedFileAttributes.h"

NSString *const DFCacheAttributeMetadataKey = @"_df_cache_metadata_key";

@implementation DFCache {
    BOOL _cleanupTimerEnabled;
    NSTimeInterval _cleanupTimeInterval;
    DFCacheTimer *__weak _cleanupTimer;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_cleanupTimer invalidate];
}

- (id)initWithDiskCache:(DFDiskCache *)diskCache memoryCache:(NSCache *)memoryCache {
    if (self = [super init]) {
        if (!diskCache) {
            [NSException raise:NSInvalidArgumentException format:@"Attempting to initialize DFCache without disk cache"];
        }
        _diskCache = diskCache;
        _memoryCache = memoryCache;
        
        _ioQueue = dispatch_queue_create("DFCache::IOQueue", DISPATCH_QUEUE_SERIAL);
        _processingQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        
        _cleanupTimeInterval = 60.f;
        _cleanupTimerEnabled = YES;
        [self _scheduleCleanupTimer];
        
#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_didReceiveMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
#endif
    }
    return self;
}

- (id)initWithName:(NSString *)name memoryCache:(NSCache *)memoryCache {
    if (!name.length) {
        [NSException raise:NSInvalidArgumentException format:@"Attemting to initialize DFCache without a name"];
    }
    DFDiskCache *diskCache = [[DFDiskCache alloc] initWithName:name];
    diskCache.capacity = 1024 * 1024 * 100; // 100 Mb
    diskCache.cleanupRate = 0.5f;
    return [self initWithDiskCache:diskCache memoryCache:memoryCache];
}

- (id)initWithName:(NSString *)name {
    NSCache *memoryCache = [NSCache new];
    memoryCache.name = name;
    return [self initWithName:name memoryCache:memoryCache];
}

#pragma mark - Read (Asynchronous)

- (void)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id))completion {
    NSAssert(decode, @"DFCacheDecodeBlock must not be nil");
    if (!completion) {
        return;
    }
    if (!key.length) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    id object = [self.memoryCache objectForKey:key];
    if (object) {
        _dwarf_cache_callback(completion, object);
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSData *data = [self.diskCache dataForKey:key];
        if (!data) {
            _dwarf_cache_callback(completion, nil);
            return;
        }
        dispatch_async(self.processingQueue, ^{
            @autoreleasepool {
                id object = decode(data);
                [self storeObject:object forKey:key cost:cost];
                _dwarf_cache_callback(completion, object);
            }
        });
    });
}

- (void)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode completion:(void (^)(id))completion {
    [self cachedObjectForKey:key decode:decode cost:nil completion:completion];
}

#pragma mark - Read (Synchronous)

- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost {
    NSAssert(decode, @"DFCacheDecodeBlock must not be nil");
    if (!key.length || !decode) {
        return nil;
    }
    id __block object = [self.memoryCache objectForKey:key];
    if (object) {
        return object;
    }
    dispatch_sync(self.ioQueue, ^{
        @autoreleasepool {
            NSData *data = [self.diskCache dataForKey:key];
            if (data) {
                object = decode(data);
                [self storeObject:object forKey:key cost:cost];
            }
        }
    });
    return object;
}

- (id)cachedObjectForKey:(NSString *)key decode:(DFCacheDecodeBlock)decode {
    return [self cachedObjectForKey:key decode:decode cost:nil];
}

#pragma mark - Write

- (void)storeObject:(id)object
               data:(NSData *)data
             forKey:(NSString *)key
               cost:(NSUInteger)cost {
    [self _storeObject:object data:data encode:nil forKey:key cost:cost ];
}

- (void)storeObject:(id)object
               data:(NSData *)data
             forKey:(NSString *)key {
    [self storeObject:object data:data forKey:key cost:0];
}

- (void)storeObject:(id)object
             encode:(DFCacheEncodeBlock)encode
             forKey:(NSString *)key
               cost:(NSUInteger)cost {
    [self _storeObject:object data:nil encode:encode forKey:key cost:cost ];
}

- (void)storeObject:(id)object
             encode:(DFCacheEncodeBlock)encode
             forKey:(NSString *)key {
    [self storeObject:object encode:encode forKey:key cost:0];
}

- (void)_storeObject:(id)object
                data:(NSData *)data
              encode:(DFCacheEncodeBlock)encode
              forKey:(NSString *)key
                cost:(NSUInteger)cost {
    if (!key.length) {
        return;
    }
    if (object) {
        [self.memoryCache setObject:object forKey:key cost:cost];
    }
    if (!data && !encode) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        @autoreleasepool {
            NSData *__block encodedData = data;
            if (!encodedData) {
                @try {
                    encodedData = encode(object);
                }
                @catch (NSException *exception) {
                    // Do nothing
                }
            }
            if (encodedData) {
                [self.diskCache setData:encodedData forKey:key];
            }
        }
    });
}

- (void)storeObject:(id)object forKey:(NSString *)key cost:(DFCacheCostBlock)cost {
    if (!object || !key.length) {
        return;
    }
    NSUInteger objectCost = cost ? cost(object) : 0;
    [self.memoryCache setObject:object forKey:key cost:objectCost];
}

#pragma mark - Remove

- (void)removeObjectsForKeys:(NSArray *)keys {
    if (!keys.count) {
        return;
    }
    for (NSString *key in keys) {
        [self.memoryCache removeObjectForKey:key];
    }
    dispatch_async(self.ioQueue, ^{
        for (NSString *key in keys) {
            [self.diskCache removeDataForKey:key];
        }
    });
}

- (void)removeObjectForKey:(NSString *)key {
    if (key) {
        [self removeObjectsForKeys:@[key]];
    }
}

- (void)removeAllObjects {
    [self.memoryCache removeAllObjects];
    dispatch_async(self.ioQueue, ^{
        [self.diskCache removeAllData];
    });
}

#pragma mark - Metadata

- (NSDictionary *)metadataForKey:(NSString *)key {
    if (!key.length) {
        return nil;
    }
    NSDictionary *__block metadata;
    dispatch_sync(self.ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        metadata = [fileURL extendedAttributeValueForKey:DFCacheAttributeMetadataKey error:nil];
    });
    return metadata;
}

- (void)setMetadata:(NSDictionary *)metadata forKey:(NSString *)key {
    if (!metadata || !key.length) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        [fileURL setExtendedAttributeValue:metadata forKey:DFCacheAttributeMetadataKey];
    });
}

- (void)setMetadataValues:(NSDictionary *)keyedValues forKey:(NSString *)key {
    if (!keyedValues.count || !key.length) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        NSDictionary *metadata = [fileURL extendedAttributeValueForKey:DFCacheAttributeMetadataKey error:nil];
        NSMutableDictionary *mutableMetadata = [[NSMutableDictionary alloc] initWithDictionary:metadata];
        [mutableMetadata addEntriesFromDictionary:keyedValues];
        [fileURL setExtendedAttributeValue:mutableMetadata forKey:DFCacheAttributeMetadataKey];
    });
}

- (void)removeMetadataForKey:(NSString *)key {
    if (!key.length) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSURL *fileURL = [self.diskCache URLForKey:key];
        [fileURL removeExtendedAttributeForKey:DFCacheAttributeMetadataKey];
    });
}

#pragma mark - Cleanup

- (void)setCleanupTimerInterval:(NSTimeInterval)timeInterval {
    if (_cleanupTimeInterval != timeInterval) {
        _cleanupTimeInterval = timeInterval;
        [self _scheduleCleanupTimer];
    }
}

- (void)setCleanupTimerEnabled:(BOOL)enabled {
    if (_cleanupTimerEnabled != enabled) {
        _cleanupTimerEnabled = enabled;
        [self _scheduleCleanupTimer];
    }
}

- (void)_scheduleCleanupTimer {
    [_cleanupTimer invalidate];
    if (_cleanupTimerEnabled) {
        DFCache *__weak weakSelf = self;
        _cleanupTimer = [DFCacheTimer scheduledTimerWithTimeInterval:_cleanupTimeInterval block:^{
            [weakSelf cleanupDiskCache];
        } userInfo:nil repeats:YES];
    }
}

- (void)cleanupDiskCache {
    dispatch_async(self.ioQueue, ^{
        [self.diskCache cleanup];
    });
}

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
- (void)_didReceiveMemoryWarning:(NSNotification *__unused)notification {
    [self.memoryCache removeAllObjects];
}
#endif

#pragma mark - Data

- (void)cachedDataForKey:(NSString *)key completion:(void (^)(NSData *))completion {
    if (!completion) {
        return;
    }
    if (!key.length) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSData *data = [self.diskCache dataForKey:key];
        _dwarf_cache_callback(completion, data);
    });
}

- (NSData *)cachedDataForKey:(NSString *)key {
    if (!key.length) {
        return nil;
    }
    NSData *__block data;
    dispatch_sync(self.ioQueue, ^{
        data = [self.diskCache dataForKey:key];
    });
    return data;
}

- (void)storeData:(NSData *)data forKey:(NSString *)key {
    if (!data || !key.length) {
        return;
    }
    dispatch_async(self.ioQueue, ^{
        [self.diskCache setData:data forKey:key];
    });
}

#pragma mark - Miscellaneous

- (NSString *)debugDescription {
    return [NSString stringWithFormat:@"<%@ %p> { disk_cache = %@ }", [self class], self, [self.diskCache debugDescription]];
}

#pragma mark - Deprecated

- (void)storeObject:(id)object forKey:(NSString *)key cost:(NSUInteger)cost data:(NSData *)data {
    [self storeObject:object data:data forKey:key cost:cost];
}

- (void)storeObject:(id)object forKey:(NSString *)key cost:(NSUInteger)cost encode:(DFCacheEncodeBlock)encode {
    [self storeObject:object encode:encode forKey:key cost:cost];
}

@end
