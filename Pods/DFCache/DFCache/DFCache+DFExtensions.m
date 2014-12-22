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
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *batch = [self batchCachedDataForKeys:keys];
        _dwarf_cache_callback(completion, batch);
    });
}

- (NSDictionary *)batchCachedDataForKeys:(NSArray *)keys {
    if (!keys.count) {
        return nil;
    }
    NSMutableDictionary *batch = [NSMutableDictionary new];
    for (NSString *key in keys) {
        NSData *data = [self cachedDataForKey:key];
        if (data) {
            batch[key] = data;
        }
    }
    return [batch copy];
}

- (void)batchCachedObjectsForKeys:(NSArray *)keys completion:(void (^)(NSDictionary *))completion {
    if (!completion) {
        return;
    }
    if (!keys.count) {
        _dwarf_cache_callback(completion, nil);
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSDictionary *batch = [self batchCachedObjectsForKeys:keys];
        _dwarf_cache_callback(completion, batch);
    });
}

- (NSDictionary *)batchCachedObjectsForKeys:(NSArray *)keys {
    if (!keys.count) {
        return nil;
    }
    NSMutableDictionary *batch = [NSMutableDictionary new];
    for (NSString *key in keys) {
        id object = [self cachedObjectForKey:key];
        if (object) {
            batch[key] = object;
        }
    }
    return batch;
}

- (void)firstCachedObjectForKeys:(NSArray *)keys completion:(void (^)(id, NSString *))completion {
    if (!completion) {
        return;
    }
    [self _firstCachedObjectForKeys:[keys mutableCopy] completion:completion];
}

- (void)_firstCachedObjectForKeys:(NSMutableArray *)keys completion:(void (^)(id, NSString *))completion {
    if (!keys.count) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(nil, nil);
        });
        return;
    }
    NSString *key = keys[0];
    [keys removeObjectAtIndex:0];
    DFCache *__weak weakSelf = self;
    [self cachedObjectForKey:key completion:^(id object) {
        if (object) {
            dispatch_async(dispatch_get_main_queue(), ^{
                completion(object, key);
            });
        } else {
            [weakSelf _firstCachedObjectForKeys:keys completion:completion];
        }
    }];
}

@end
