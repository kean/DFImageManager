//
//  TDFImageCache.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/1/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockImageCache.h"

@implementation TDFMockImageCache

- (instancetype)init {
    if (self = [super init]) {
        _enabled = NO;
    }
    return self;
}

- (void)setEnabled:(BOOL)enabled {
    if (_enabled != enabled) {
        _enabled = enabled;
        _images = enabled ? [NSMutableDictionary new] : nil;
    }
}

- (DFCachedImage *)cachedImageForKey:(id<NSCopying>)key {
    return [_images objectForKey:key];
}

- (void)storeImage:(DFCachedImage *)image forKey:(id<NSCopying>)key {
    [_images setObject:image forKey:key];
}

- (void)removeAllObjects {
    [_images removeAllObjects];
}

@end
