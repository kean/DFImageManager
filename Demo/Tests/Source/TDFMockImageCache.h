//
//  TDFImageCache.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/1/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <Foundation/Foundation.h>


static NSString *TDFMockImageCacheWillReturnCachedImageNotification = @"TDFMockImageCacheWillReturnCachedImageNotification";
static NSString *TDFMockImageCacheImageKey = @"TDFMockImageCacheImageKey";

/*! The DFImageCaching implementation that can be easily enabled and disabled, doesn't evict objects and provides other features required for testing.
 */
@interface TDFMockImageCache : NSObject <DFImageCaching>

/*! Default value is NO.
 */
@property (nonatomic) BOOL enabled;
@property (nonatomic, readonly) NSMutableDictionary *responses;

@end
