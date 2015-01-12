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
#import "DFImageFetcherProtocol.h"
#import "DFImageProcessorProtocol.h"
#import <Foundation/Foundation.h>


@interface DFImageManagerConfiguration : NSObject <NSCopying>

@property (nonatomic, readonly) id<DFImageFetcher> fetcher;
@property (nonatomic) id<DFImageProcessor> processor;

/*! Memory cache that stores processed images.
  @note It's a good idea to implement <DFImageProcessing> and <DFImageCache> in that same object.
 */
@property (nonatomic) id<DFImageCache> cache;

- (instancetype)initWithFetcher:(id<DFImageFetcher>)fetcher NS_DESIGNATED_INITIALIZER;

+ (instancetype)configurationWithFetcher:(id<DFImageFetcher>)fetcher;
+ (instancetype)configurationWithFetcher:(id<DFImageFetcher>)fetcher processor:(id<DFImageProcessor>)processor cache:(id<DFImageCache>)cache;

@end
