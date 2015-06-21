//
//  TDFImageCache.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/19/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFTestingKit.h"
#import "DFImageManagerKit.h"
#import <XCTest/XCTest.h>

@interface TDFImageCache : XCTestCase

@end

@implementation TDFImageCache {
    DFImageCache *_cache;
}

- (void)setUp {
    [super setUp];
    _cache = [DFImageCache new];
}

- (void)testThatDefaultCacheIsInitializedWithSharedCache {
    DFImageCache *cache = [DFImageCache new];
    XCTAssertEqual(cache.cache, [NSCache df_sharedImageCache]);
    XCTAssertEqual(cache.cache.totalCostLimit, [NSCache df_recommendedTotalCostLimit]);
}

- (void)testThatImageIsCached {
    DFImageResponse *response = [DFImageResponse responseWithImage:[UIImage new]];
    DFCachedImageResponse *cachedResponse = [[DFCachedImageResponse alloc] initWithResponse:response expirationDate:CACurrentMediaTime() + 1.0];
    [_cache storeImageResponse:cachedResponse forKey:@"key"];
    XCTAssertNotNil([_cache cachedImageResponseForKey:@"key"]);
    XCTAssertEqual([_cache cachedImageResponseForKey:@"key"].response, response);
}

- (void)testThatExpiredImageIsntReturned {
    DFImageResponse *response = [DFImageResponse responseWithImage:[UIImage new]];
    DFCachedImageResponse *cachedImage = [[DFCachedImageResponse alloc] initWithResponse:response expirationDate:CACurrentMediaTime() + 0.01];
    [_cache storeImageResponse:cachedImage forKey:@"key"];
    XCTAssertNotNil([_cache cachedImageResponseForKey:@"key"]);
    XCTAssertEqual([_cache cachedImageResponseForKey:@"key"].response, response);
    [NSThread sleepForTimeInterval:0.02];
    XCTAssertNil([_cache cachedImageResponseForKey:@"key"]);
}

@end
