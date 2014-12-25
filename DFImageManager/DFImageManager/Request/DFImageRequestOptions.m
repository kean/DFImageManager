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

#import "DFImageRequestOptions.h"


@implementation DFImageRequestOptions

+ (instancetype)defaultOptions {
    return [[self class] new];
}

- (instancetype)init {
    if (self = [super init]) {
        _cacheStoragePolicy = DFImageCacheStorageAllowed;
        _priority = DFImageRequestPriorityNormal;
        _networkAccessAllowed = YES;
    }
    return self;
}

- (instancetype)initWithOptions:(DFImageRequestOptions *)options {
    if (self = [self init]) {
        _cacheStoragePolicy = options.cacheStoragePolicy;
        _priority = options.priority;
        _networkAccessAllowed = options.networkAccessAllowed;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [[DFImageRequestOptions alloc] initWithOptions:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { cache_storage_policy = %i, priority = %@, network_access_allowed = %i }", [self class], self, (int)_cacheStoragePolicy, [DFImageRequestOptions _descriptionForPriority:_priority], _networkAccessAllowed];
}

+ (NSString *)_descriptionForPriority:(DFImageRequestPriority)priority {
    static NSDictionary *table;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        table = @{ @(DFImageRequestPriorityVeryLow) : @".VeryLow",
                   @(DFImageRequestPriorityLow) : @".Low",
                   @(DFImageRequestPriorityNormal) : @".Normal",
                   @(DFImageRequestPriorityHigh) : @".High",
                   @(DFImageRequestPriorityVeryHigh) : @".VeryHigh" };
    });
    return table[@(priority)];
}

@end
