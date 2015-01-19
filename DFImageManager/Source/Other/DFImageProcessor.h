// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "DFImageCacheProtocol.h"
#import "DFImageProcessorProtocol.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/*! Boolean that indicates that some portion of the content should be clipped so that the image aspect ratio is the same as of the target size. This option only works for DFImageContentModeAspectFill. Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *DFImageProcessingClipsToBoundsKey;

/*! NSNumber with float value that specifies a normalized image corner radius, where 0.5 is a corner radius that is half of the minimum image side. Should be put into DFImageRequestOptions userInfo dictionary.
 */
extern NSString *DFImageProcessingCornerRadiusKey;


@interface DFImageProcessor : NSObject <DFImageProcessor, DFImageCache>

- (instancetype)initWithCache:(NSCache *)cache NS_DESIGNATED_INITIALIZER;
- (instancetype)init;

@property (nonatomic, readonly) NSCache *cache;

/*! The maximum entry age after which entry is considered expired and is removed from the cache.
 */
@property (nonatomic) NSUInteger maximumCachedEntryAge;

@end


@interface NSCache (DFImageProcessingManager)

+ (NSCache *)df_sharedImageCache;
+ (NSUInteger)df_recommendedTotalCostLimit;

@end
