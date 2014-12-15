// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

#import "DFImageManagerProtocol.h"
#import <UIKit/UIKit.h>

@class DFImageRequestOptions;

typedef NS_ENUM(NSUInteger, DFImageViewAnimation) {
   DFImageViewAnimationNone,
   DFImageViewAnimationFade,
   DFImageViewAnimationCrossDissolve
};


/*! Implements most of the basic functionality required to fetch images and then display them with animation.
 */
@interface DFImageView : UIView

@property (nonatomic) id<DFImageManager> imageManager;
@property (nonatomic) DFImageViewAnimation animation;

/*! Placeholder color is displayed when the image is being loaded. It doesn't interfere with the background color of the view so that the images that has transparency are displayed properly.
 */
@property (nonatomic) UIColor *placeholderColor;

/*! Automatically changes image request priorities when image view gets added/removed from the window. Default value is YES.
 */
@property (nonatomic) BOOL managesRequestPriorities;

/*! Image that gets displayed when either the request failes or when a given asset is nil.
 */
@property (nonatomic) UIImage *failureImage;

@property (nonatomic, readonly) UIImageView *imageView;

/*! Lazily creates and returns failure image view. The property is made public so that you can modify view's behavior. For example, you might want to change it's layout or content mode.
 */
@property (nonatomic, readonly) UIImageView *failureImageView;

- (void)setImage:(UIImage *)image;

- (void)setImageWithAsset:(id)asset;
- (void)setImageWithAsset:(id)asset options:(DFImageRequestOptions *)options;

- (void)prepareForReuse;

@end


/*! Subclassing hooks are method intended to be overrided in case you want to extend/or change default behavior of DFImageView. You don't have to call super if you override one of this methods.
 */
@interface DFImageView (SubclassingHooks)

- (void)requestDidFinishWithImage:(UIImage *)image source:(DFImageSource)source info:(NSDictionary *)info;
- (void)requestDidFailWithError:(NSError *)error info:(NSDictionary *)info;

@end
