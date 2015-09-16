// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

@interface NSCache (DFImageManager)

/*! Returns shared image cache with a recommended total cost limit (in bytes).
 @note Application should limit the number of separate caches to minimum to make total cost limit work properly.
 */
+ (nonnull NSCache *)df_sharedImageCache;

/*! Returns recommended total cost limit in bytes. The cost limit is computed using the amount of available physical memory.
 */
+ (NSUInteger)df_recommendedTotalCostLimit;

@end
