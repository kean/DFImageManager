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

#import "DFImageManaging.h"
#import "DFImageView.h"
#import <UIKit/UIKit.h>

@class DFImageRequestOptions;

typedef NS_ENUM(NSUInteger, DFImageViewAnimation) {
   DFImageViewAnimationNone,
   DFImageViewAnimationFade,
   DFImageViewAnimationCrossDissolve
};


/*! The DFImageContainerView is designed to work in pair with DFImageView to enable several additional features like dynamic  placeholder color, separate failure view and more.
 */
@interface DFImageContainerView : UIView <DFImageViewDelegate>

/*! Image view used by container view. Container view is set as an image view delegate.
 */
@property (nonatomic, readonly) DFImageView *imageView;

/*! Image view animation that should be used whenever necessary.
 */
@property (nonatomic) DFImageViewAnimation animation;

/*! Placeholder color is displayed when the image is being loaded. It disappear when the actual image is displayed so that the images that has transparency are displayed properly.
 */
@property (nonatomic) UIColor *placeholderColor;

/*! Image that gets displayed when either the request failes or when a given resource is nil.
 */
@property (nonatomic) UIImage *failureImage;

/*! Lazily creates and returns failure image view.
 */
@property (nonatomic, readonly) UIImageView *failureImageView;

/*! Performs any clean up necessary to prepare the view for use again. Calls prepareForReuse method of the image view.
 */
- (void)prepareForReuse;

/*! Creates image view used inside the container. Subclasses may customize created image view.
 */
- (DFImageView *)createImageView;

@end
