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

NS_ASSUME_NONNULL_BEGIN

/*! The DFImageResponse class represents an immutable image response for a specified resource.
 */
@interface DFImageResponse : NSObject

/*! Returns the image from the response.
 */
@property (nullable, nonatomic, readonly) UIImage *image;

/*! Returns the error associated with the load.
 */
@property (nullable, nonatomic, readonly) NSError *error;

/*! Returns the metadata associated with the load.
 */
@property (nullable, nonatomic, readonly) NSDictionary *userInfo;

/*! Initializes response with a given image, error and userInfo associated with an image load.
 */
- (instancetype)initWithImage:(nullable UIImage *)image error:(nullable NSError *)error userInfo:(nullable NSDictionary *)userInfo NS_DESIGNATED_INITIALIZER;

/*! Returns response initialized with a given image.
 */
+ (instancetype)responseWithImage:(nullable UIImage *)image;

/*! Returns response initialized with a given error.
 */
+ (instancetype)responseWithError:(nullable NSError *)error;

@end

NS_ASSUME_NONNULL_END
