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

#import "DFImageManager.h"
#import "DFImageManagerDefines.h"
#import "DFImageManaging.h"
#import "DFImageRequest+UIKitAdditions.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFImageTask.h"
#import "DFImageView.h"

#if __has_include("DFImageManagerKit+GIF.h")
#import "DFImageManagerKit+GIF.h"
#endif

@implementation DFImageView

- (void)dealloc {
    [self _cancelFetching];
}

- (nonnull instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.contentMode = UIViewContentModeScaleAspectFill;
        self.clipsToBounds = YES;
        [self _commonInit];
    }
    return self;
}

- (nullable instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    self.imageManager = [DFImageManager sharedManager];
    
    _allowsAnimations = YES;
#if __has_include("DFImageManagerKit+GIF.h")
    _allowsGIFPlayback = YES;
#endif
}

- (void)displayImage:(nullable UIImage *)image {
#if __has_include("DFImageManagerKit+GIF.h")
    if (!image) {
        self.animatedImage = nil;
    }
    if (self.allowsGIFPlayback && [image isKindOfClass:[DFAnimatedImage class]]) {
        self.animatedImage = ((DFAnimatedImage *)image).animatedImage;
        return;
    }
#endif
    self.image = image;
}

- (void)prepareForReuse {
    [self _cancelFetching];
    self.image = nil;
#if __has_include("DFImageManagerKit+GIF.h")
    self.animatedImage = nil;
#endif
    [self.layer removeAllAnimations];
}

- (void)_cancelFetching {
    _imageTask.completionHandler = nil;
    _imageTask.progressiveImageHandler = nil;
    [_imageTask cancel];
    _imageTask = nil;
}

- (void)setImageWithResource:(nullable id)resource {
    [self setImageWithResource:resource targetSize:[DFImageRequest targetSizeForView:self] contentMode:DFImageContentModeAspectFill options:nil];
}

- (void)setImageWithResource:(nullable id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options {
    [self setImageWithRequest:(resource ? [DFImageRequest requestWithResource:resource targetSize:targetSize contentMode:contentMode options:options] : nil)];
}

- (void)setImageWithRequest:(DFImageRequest *)request {
    [self _cancelFetching];
    if (!request) {
        return;
    }
    typeof(self) __weak weakSelf = self;
    DFImageTask *task = [self.imageManager imageTaskForRequest:request completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull imageTask){
        [weakSelf didCompleteImageTask:imageTask withImage:image];
    }];
    task.progressiveImageHandler = ^(UIImage *__nonnull image){
        weakSelf.image = image;
    };
    _imageTask = task;
    [task resume];
}

- (void)didCompleteImageTask:(nonnull DFImageTask *)task withImage:(nullable UIImage *)image {
    if (self.allowsAnimations && !task.response.isFastResponse && !self.image) {
        [self displayImage:image];
        [self.layer addAnimation:({
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.keyPath = @"opacity";
            animation.fromValue = @0.f;
            animation.toValue = @1.f;
            animation.duration = 0.25f;
            animation;
        }) forKey:@"opacity"];
    } else {
        [self displayImage:image];
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (self.managesRequestPriorities) {
        [_imageTask setPriority:(newWindow ? DFImageRequestPriorityNormal: DFImageRequestPriorityLow)];
    }
}

@end
