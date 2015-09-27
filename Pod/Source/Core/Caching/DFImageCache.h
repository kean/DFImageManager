// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageCaching.h"
#import <Foundation/Foundation.h>

/*! Memory cache implementation built on top of NSCache. Adds cached entries expiration, automatic cleanup on memory warnings and more.
 */
@interface DFImageCache : NSObject <DFImageCaching>

/*! Returns the cache that the DFImageCache was initialized with.
 */
@property (nonnull, nonatomic, readonly) NSCache *cache;

/*! Initializes image cache with an instance of NSCache class.
 */
- (nonnull instancetype)initWithCache:(nonnull NSCache *)cache NS_DESIGNATED_INITIALIZER;

/*! Returns cost for a given cached image response.
 */
- (NSUInteger)costForImageResponse:(nonnull DFCachedImageResponse *)cachedResponse;

@end
