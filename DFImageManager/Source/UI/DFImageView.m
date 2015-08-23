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
#import "DFImageManaging.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFImageTask.h"
#import "DFImageView.h"

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

@implementation DFImageView

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    _imageTargetSize = CGSizeZero;
    _imageContentMode = DFImageContentModeAspectFill;
    _allowsAnimations = YES;
    _managesRequestPriorities = NO;
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    _allowsGIFPlayback = YES;
#endif
    _imageRequestOptions = [DFImageRequestOptions new];
}

- (void)displayImage:(nullable UIImage *)image {
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    if (!image) {
        self.animatedImage = nil;
    }
    if (self.allowsGIFPlayback && [image isKindOfClass:[DFAnimatedImage class]]) {
        DFAnimatedImage *animatedImage = (DFAnimatedImage *)image;
        self.animatedImage = animatedImage.animatedImage;
        return;
    }
#endif
    self.image = image;
}

#pragma mark -

- (void)prepareForReuse {
    [self _cancelFetching];
    _imageTask = nil;
    self.image = nil;
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    self.animatedImage = nil;
#endif
    [self.layer removeAllAnimations];
}

- (void)_cancelFetching {
    _imageTask.completionHandler = nil;
    _imageTask.progressiveImageHandler = nil;
    [_imageTask cancel];
}

- (CGSize)imageTargetSize {
    if (CGSizeEqualToSize(CGSizeZero, _imageTargetSize)) {
        CGSize size = self.bounds.size;
        CGFloat scale = [UIScreen mainScreen].scale;
        return CGSizeMake(size.width * scale, size.height * scale);
    }
    return _imageTargetSize;
}

- (void)setImageWithResource:(nullable id)resource {
    [self setImageWithResource:resource targetSize:self.imageTargetSize contentMode:self.imageContentMode options:self.imageRequestOptions];
}

- (void)setImageWithResource:(nullable id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options {
    [self setImageWithRequest:(resource ? [DFImageRequest requestWithResource:resource targetSize:targetSize contentMode:contentMode options:options] : nil)];
}

- (void)setImageWithRequest:(DFImageRequest *)request {
    [self _cancelFetching];
    if (!request) {
        return;
    }
    if ([self.delegate respondsToSelector:@selector(imageView:willStartImageTaskForRequest:)]) {
        [self.delegate imageView:self willStartImageTaskForRequest:request];
    }
    typeof(self) __weak weakSelf = self;
    DFImageTask *task = [self.imageManager imageTaskForRequest:request completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull imageTask){
        [weakSelf.delegate imageView:self didCompleteImageTask:imageTask withImage:image];
        [weakSelf didCompleteImageTask:imageTask withImage:image];
    }];
    task.progressiveImageHandler = ^(UIImage *__nonnull image){
        weakSelf.image = image;
    };
    _imageTask = task;
    [task resume];
}

- (void)didCompleteImageTask:(nonnull DFImageTask *)task withImage:(nullable UIImage *)image {
    BOOL isFastResponse = task.response.isFastResponse;
    if (self.allowsAnimations && !isFastResponse && !self.image) {
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

#pragma mark - Priorities

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (self.managesRequestPriorities) {
        DFImageRequestPriority priority = (newWindow == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
        [_imageTask setPriority:priority];
    }
}

@end
