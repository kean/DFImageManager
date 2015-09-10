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
        _responses = enabled ? [NSMutableDictionary new] : nil;
    }
}

- (DFCachedImageResponse *)cachedImageResponseForKey:(id<NSCopying>)key {
    DFCachedImageResponse *response = [_responses objectForKey:key];
    if (response) {
        [[NSNotificationCenter defaultCenter] postNotificationName:TDFMockImageCacheWillReturnCachedImageNotification object:self userInfo:@{ TDFMockImageCacheImageKey : response.image }];
    }
    return response;
}

- (void)storeImageResponse:(DFCachedImageResponse *)cachedResponse forKey:(id<NSCopying>)key {
    [_responses setObject:cachedResponse forKey:key];
}

- (void)removeAllObjects {
    [_responses removeAllObjects];
}

@end
