// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>

@interface NSCache (DFImageManager)

/*! Returns shared image cache with a recommended total cost limit.
 */
+ (nonnull NSCache *)df_sharedImageCache;

/*! Returns recommended total cost limit in bytes.
 */
+ (NSUInteger)df_recommendedTotalCostLimit;

@end
