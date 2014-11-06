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

#import "DFCache+DFExtensions.h"
#import "DFCachePrivate.h"

@implementation DFCache (DFCacheExtended)

#pragma mark - Read (Batch)

- (void)batchCachedDataForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *batch))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    dispatch_async(self.ioQueue, ^{
        NSDictionary *batch = [self _batchCachedDataForKeys:keys];
        _dwarf_cache_callback(completion, batch);
    });
}

- (NSDictionary *)batchCachedDataForKeys:(NSArray *)keys {
    if (!keys.count) {
        return nil;
    }
    NSDictionary *__block batch;
    dispatch_sync(self.ioQueue, ^{
        batch = [self _batchCachedDataForKeys:keys];
    });
    return batch;
}

- (NSDictionary *)_batchCachedDataForKeys:(NSArray *)keys {
    NSMutableDictionary *batch = [NSMutableDictionary new];
    for (NSString *key in keys) {
        NSAssert([key isKindOfClass:[NSString class]], @"Key must be an an instance of NSString or an instance of any class that inherits from NSString.");
        NSData *data = [self.diskCache dataForKey:key];
        if (data) {
            batch[key] = data;
        }
    }
    return [batch copy];
}

- (NSDictionary *)batchCachedObjectsForKeys:(NSArray *)keys {
    if (!keys.count) {
        return nil;
    }
    NSMutableDictionary *batch = [NSMutableDictionary new];
    for (NSString *key in keys) {
        NSAssert([key isKindOfClass:[NSString class]], @"Key must be an an instance of NSString or an instance of any class that inherits from NSString.");
        id object = [self.memoryCache objectForKey:key];
        if (object) {
            batch[key] = object;
        }
    }
    return [batch copy];
}

- (void)batchCachedObjectsForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(NSDictionary *))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    
    // Retrieve objects from memory cache.
    NSArray *remainingKeys;
    NSMutableDictionary *batch = [self _batchCachedObjectForKeys:keys remainingKeys:&remainingKeys];
    if (!remainingKeys.count) {
        _dwarf_cache_callback(completion, batch);
        return;
    }
    
    // Retrieve remaining objects from disk cache.
    [self batchCachedDataForKeys:keys completion:^(NSDictionary *dataBatch) {
        dispatch_async(self.processingQueue, ^{
            [batch addEntriesFromDictionary:[self _objectsBatchFromDataBatch:dataBatch decode:decode cost:cost]];
            _dwarf_cache_callback(completion, batch);
        });
    }];
}

- (NSDictionary *)batchCachedObjectsForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost {
    if (!keys.count) {
        return nil;
    }
    // Retrieve objects from memory cache.
    NSArray *remainingKeys;
    NSMutableDictionary *batch = [self _batchCachedObjectForKeys:keys remainingKeys:&remainingKeys];
    if (!remainingKeys.count) {
        return [batch copy];
    }
    
    // Retrieve remaining objects from disk cache.
    NSDictionary *dataBatch = [self batchCachedDataForKeys:remainingKeys];
    [batch addEntriesFromDictionary:[self _objectsBatchFromDataBatch:dataBatch decode:decode cost:cost]];
    return [batch copy];
}

- (NSMutableDictionary *)_batchCachedObjectForKeys:(NSArray *)keys remainingKeys:(NSArray *__autoreleasing *)remainingKeys {
    NSMutableDictionary *batch = [[NSMutableDictionary alloc] initWithDictionary:[self batchCachedObjectsForKeys:keys]];
    if (remainingKeys) {
        *remainingKeys = [keys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary *__unused bindings) {
            return !batch[evaluatedObject];
        }]];
    }
    return batch;
}

- (NSDictionary *)_objectsBatchFromDataBatch:(NSDictionary *)dataBatch decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost {
    NSMutableDictionary *batch = [NSMutableDictionary new];
    @autoreleasepool {
        for (NSString *key in dataBatch) {
            NSData *data = dataBatch[key];
            id object = decode(data);
            if (object) {
                [self storeObject:object forKey:key cost:cost];
                batch[key] = object;
            }
        }
    }
    return batch;
}

- (void)firstCachedObjectForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id, NSString *))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, nil);
        });
        return;
    }
    for (NSString *key in keys) {
        id object = [self.memoryCache objectForKey:key];
        if (object) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(object, key);
            });
            return;
        }
    }
    dispatch_async(self.ioQueue, ^{
        @autoreleasepool {
            id foundObject;
            NSString *foundKey;
            for (NSString *key in keys) {
                NSData *data = [self.diskCache dataForKey:key];
                if (!data) {
                    continue;
                }
                id object = decode(data);
                if (object) {
                    foundObject = object;
                    foundKey = key;
                    [self storeObject:object forKey:key cost:cost];
                    break;
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(foundObject, foundKey);
            });
        }
    });
}

#pragma mark - Deprecated

- (void)cachedDataForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *))completion {
    [self batchCachedDataForKeys:keys completion:completion];
}

- (void)cachedObjectsForKeys:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(NSDictionary *))completion {
    [self batchCachedObjectsForKeys:keys decode:decode cost:cost completion:completion];
}

- (void)cachedObjectForAnyKey:(NSArray *)keys decode:(DFCacheDecodeBlock)decode cost:(DFCacheCostBlock)cost completion:(void (^)(id, NSString *))completion {
    [self firstCachedObjectForKeys:keys decode:decode cost:cost completion:completion];
}

@end
