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

#import "DFImageCaching.h"
#import <Foundation/Foundation.h>


/*! Memory cache implementation that is built on top of NSCache and adds more functionality to it, like cached entries expiration, automatic cleanup on memory warnings and more.
 */
@interface DFImageCache : NSObject <DFImageCaching>

- (instancetype)initWithCache:(NSCache *)cache NS_DESIGNATED_INITIALIZER;

@property (nonatomic, readonly) NSCache *cache;

/*! The maximum entry age after which entry is considered expired and is removed from the cache. Default value is INT_MAX so that entries never expire.
 */
@property (nonatomic) NSUInteger maximumEntryAge;

@end
