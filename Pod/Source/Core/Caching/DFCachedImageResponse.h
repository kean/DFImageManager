// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*! Wrapper for image responses stored in the framework's memory caching system.
 */
@interface DFCachedImageResponse : NSObject

/*! Returns response image.
 */
@property (nonnull, nonatomic, readonly) UIImage *image;

/*! Returns response info.
 */
@property (nullable, nonatomic, readonly) NSDictionary *info;

/*! Returns the expiration date of the receiver.
 */
@property (nonatomic, readonly) NSTimeInterval expirationDate;

/*! Initializes the DFCachedImageResponse with the given image, info and expiration date.
 */
- (nullable instancetype)initWithImage:(nonnull UIImage *)image info:( nullable NSDictionary *)info expirationDate:(NSTimeInterval)expirationDate NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end
