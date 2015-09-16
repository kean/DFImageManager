// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@class DFCachedImageResponse;

/*! Cache for storing image responses into memory.
 */
@protocol DFImageCaching <NSObject>

/*! Returns cached image response associated with a given key.
 */
- (nullable DFCachedImageResponse *)cachedImageResponseForKey:(nullable id<NSCopying>)key;

/*! Stores cached image response for the given key.
 */
- (void)storeImageResponse:(nullable DFCachedImageResponse *)cachedResponse forKey:(nullable id<NSCopying>)key;

/*! Removes all cached image responses.
 */
- (void)removeAllObjects;

@end
