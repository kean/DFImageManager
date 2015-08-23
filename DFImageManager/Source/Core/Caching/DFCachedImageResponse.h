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
  @param image An image, for best performance users should store decompressed images into memory cache.
 */
- (nullable instancetype)initWithImage:(nonnull UIImage *)image info:( nullable NSDictionary *)info expirationDate:(NSTimeInterval)expirationDate NS_DESIGNATED_INITIALIZER;

/*! Unavailable initializer, please use designated initializer.
 */
- (nullable instancetype)init NS_UNAVAILABLE;

@end
