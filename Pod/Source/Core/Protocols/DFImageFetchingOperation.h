// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManagerDefines.h"
#import <Foundation/Foundation.h>

@protocol DFImageFetchingOperation <NSObject>

/*! Cancels image fetching operation.
 */
- (void)cancelImageFetching;

/*! Changes image fetching operation priority.
 */
- (void)setImageFetchingPriority:(DFImageRequestPriority)priority;

@end
