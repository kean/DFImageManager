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

#import <UIKit/UIKit.h>
#import <FLAnimatedImage/FLAnimatedImage.h>

/*! The DFAnimatedImage subclasses UIImage and represents a poster image for the underlying animated image. It is a regular UIImage that doesn't override any of the native UIImage behaviors it can be used anywhere where a regular `UIImage` can be used.
 */
@interface DFAnimatedImage : UIImage

/* The animated image that the receiver was initialized with. An `FLAnimatedImage`'s job is to deliver frames in a highly performant way and works in conjunction with `FLAnimatedImageView`.
 */
@property (nonatomic, readonly) FLAnimatedImage *animatedImage;

/*! Initializes the DFAnimatedImage with an instance of FLAnimatedImage class.
 */
- (instancetype)initWithAnimatedImage:(FLAnimatedImage *)animatedImage NS_DESIGNATED_INITIALIZER;

/*! Initializes the DFAnimatedImage with an instance of FLAnimatedImage class created from a given data.
 */
- (instancetype)initWithAnimatedGIFData:(NSData *)data;

/*! Returns the DFAnimatedImage object with an instance of FLAnimatedImage class created from a given data.
 */
+ (instancetype)animatedImageWithGIFData:(NSData *)data;

/*! Returns YES if the data represents an animated GIF.
 */
+ (BOOL)isAnimatedGIFData:(NSData *)data;

@end
