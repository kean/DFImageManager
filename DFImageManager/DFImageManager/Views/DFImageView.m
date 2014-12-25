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

#import "DFImageManager.h"
#import "DFImageManagerProtocol.h"
#import "DFImageRequestOptions.h"
#import "DFImageView.h"


@implementation DFImageView {
    DFImageRequestID *_requestID;
    UIView *_backgroundView;
    UIImageView *_failureImageView;
}

- (void)dealloc {
    [self _df_cancelFetching];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _commonInit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    self.imageManager = [DFImageManager sharedManager];
    
    _animation = DFImageViewAnimationFade;
    _contentMode = DFImageContentModeDefault;
    _managesRequestPriorities = YES;
    _placeholderColor = [UIColor colorWithRed:200.0/255.0 green:200.0/255.0 blue:200.0/255.0 alpha:1.f];
    self.clipsToBounds = YES;
    
    _imageView = ({
        UIImageView *view = [[UIImageView alloc] initWithFrame:self.bounds];
        view.contentMode = UIViewContentModeScaleAspectFill;
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        view.clipsToBounds = YES;
        view;
    });
    
    _backgroundView = ({
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        view.backgroundColor = self.placeholderColor;
        view;
    });
    
    [self addSubview:_backgroundView];
    [self addSubview:_imageView];
}

- (CGSize)targetSize {
    if (CGSizeEqualToSize(CGSizeZero, _targetSize)) {
        CGSize size = self.bounds.size;
        CGFloat scale = [UIScreen mainScreen].scale;
        return CGSizeMake(size.width * scale, size.height * scale);
    }
    return _targetSize;
}

- (void)setImageWithAsset:(id)asset {
    [self setImageWithAsset:asset targetSize:self.targetSize contentMode:self.contentMode options:nil];
}

- (void)setImageWithAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode {
    [self setImageWithAsset:asset targetSize:targetSize contentMode:contentMode options:nil];
}

- (void)setImageWithAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self prepareForReuse];
    
    if (!asset) {
        self.failureImageView.hidden = NO;
        return;
    }
    
    DFImageView *__weak weakSelf = self;
    options = options ?: [DFImageRequestOptions defaultOptions];
    if (self.managesRequestPriorities) {
        options.priority = (self.window == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
    }
    _requestID = [self.imageManager requestImageForAsset:asset targetSize:targetSize contentMode:contentMode options:options completion:^(UIImage *image, NSDictionary *info) {
        DFImageSource source = [info[DFImageInfoSourceKey] unsignedIntegerValue];
        NSError *error = info[DFImageInfoErrorKey];
        if (image) {
            [weakSelf requestDidFinishWithImage:image source:source info:info];
        } else {
            [weakSelf requestDidFailWithError:error info:info];
        }
    }];
}

- (void)requestDidFinishWithImage:(UIImage *)image source:(DFImageSource)source info:(NSDictionary *)info {
    DFImageViewAnimation animation = source != DFImageSourceMemoryCache ? _animation : DFImageViewAnimationNone;
    [self _df_setImage:image withAnimation:animation];
    
}

#pragma mark - Handling Failure

- (UIImageView *)failureImageView {
    if (!self.failureImage) {
        return nil;
    }
    if (!_failureImageView) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:self.bounds];
        imageView.contentMode = UIViewContentModeCenter;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        imageView.image = self.failureImage;
        imageView.hidden = YES;
        _failureImageView = imageView;
        [self addSubview:_failureImageView];
    }
    return _failureImageView;
}

- (void)setFailureImage:(UIImage *)failureImage {
    _failureImage = failureImage;
    _failureImageView.image = failureImage;
}

- (void)requestDidFailWithError:(NSError *)error info:(NSDictionary *)info {
    self.failureImageView.hidden = NO;
}

#pragma mark - Reuse

- (void)prepareForReuse {
    self.imageView.image = nil;
    _failureImageView.hidden = YES;
    _backgroundView.alpha = 1.f;
    [self _df_cancelFetching];
    _requestID = nil;
    [_backgroundView.layer removeAllAnimations];
    [_imageView.layer removeAllAnimations];
}

- (void)_df_cancelFetching {
    [_requestID cancel];
}

#pragma mark - Priorities

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (self.managesRequestPriorities) {
        DFImageRequestPriority priority = (newWindow == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
        [_requestID setPriority:priority];
    }
}

#pragma mark - Animation

- (void)setImage:(UIImage *)image {
    [self _df_setImage:image withAnimation:DFImageViewAnimationNone];
}

- (void)_df_setImage:(UIImage *)image withAnimation:(DFImageViewAnimation)animation {
    self.imageView.image = image;
    switch (animation) {
        case DFImageViewAnimationNone:
            _backgroundView.alpha = 0.f;
            break;
        case DFImageViewAnimationFade: {
            [self.imageView.layer addAnimation:({
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                animation.keyPath = @"opacity";
                animation.fromValue = @0.f;
                animation.toValue = @1.f;
                animation.duration = 0.2f;
                animation;
            }) forKey:@"opacity"];
            
            _backgroundView.alpha = 0.f;
            [_backgroundView.layer addAnimation:({
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                animation.keyPath = @"opacity";
                animation.fromValue = @1.f;
                animation.toValue = @0.f;
                animation.duration = 0.3f;
                animation;
            }) forKey:@"opacity"];
        }
            break;
        case DFImageViewAnimationCrossDissolve: {
            [UIView transitionWithView:self
                              duration:0.2f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:nil
                            completion:nil];
            
            _backgroundView.alpha = 0.f;
            [_backgroundView.layer addAnimation:({
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                animation.keyPath = @"opacity";
                animation.fromValue = @1.f;
                animation.toValue = @0.f;
                animation.duration = 0.3f;
                animation;
            }) forKey:@"opacity"];
        }
            break;
        default:
            break;
    }
}

@end
