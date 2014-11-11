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
#import "UIImageView+DFImageManager.h"
#import <UIKit/UIKit.h>

@class DFImageRequestOptions;


@interface DFImageView : UIImageView

@property (nonatomic) id<DFImageManager> imageManager;
@property (nonatomic) DFImageViewAnimation animation;

/*! Automatically changes image request priorities when image view gets added/removed from the window. Default value is YES.
 */
@property (nonatomic) BOOL managesRequestPriorities;

- (void)setImageWithAsset:(id)asset;
- (void)setImageWithAsset:(id)asset options:(DFImageRequestOptions *)options;

- (void)prepareForReuse;

@end


@interface DFImageView (SubclassingHooks)

- (void)requestDidFinishWithImage:(UIImage *)image source:(DFImageSource)source info:(NSDictionary *)info;
- (void)requestDidFailWithError:(NSError *)error info:(NSDictionary *)info;

@end
