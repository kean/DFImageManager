// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*! The DFImageResponse class represents an image response for a specified resource. DFImageResponse encapsulates the metadata associated with a load.
 */
@interface DFImageResponse : NSObject

/*! Returns YES if response was returned using fast path, for instance from the memory cache.
 */
@property (nonatomic, readonly) BOOL isFastResponse;

/*! Returns the metadata associated with the load.
 */
@property (nullable, nonatomic, readonly) NSDictionary *info;

/*! Initializes response with a given parameters.
 */
- (nonnull instancetype)initWithInfo:(nullable NSDictionary *)info isFastResponse:(BOOL)isFastResponse;

@end
