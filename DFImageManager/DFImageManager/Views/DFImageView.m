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

#import "DFCompositeImageRequest.h"
#import "DFImageManager.h"
#import "DFImageManagerProtocol.h"
#import "DFImageRequestOptions.h"
#import "DFImageView.h"


@implementation DFImageView {
    DFCompositeImageRequest *_request;
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
    _placeholderColor = [UIColor colorWithRed:225.0/255.0 green:225.0/255.0 blue:225.0/255.0 alpha:1.f];
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

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    _backgroundView.backgroundColor = placeholderColor;
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

- (void)setImageWithAsset:(id)asset targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    DFImageRequest *request;
    if (asset != nil) {
        request = [[DFImageRequest alloc] initWithAsset:asset targetSize:targetSize contentMode:contentMode options:options];
    }
    [self setImagesWithRequests:(request != nil) ? @[request] : nil];
}

- (void)setImagesWithRequests:(NSArray *)requests {
    [self prepareForReuse];
    
    if (!requests.count) {
        self.failureImageView.hidden = NO;
        return;
    }
    
    if (self.managesRequestPriorities) {
        for (DFImageRequest *request in requests) {
            request.options.priority = (self.window == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
        }
    }
    
    DFImageView *__weak weakSelf = self;
    NSTimeInterval startTime = CACurrentMediaTime();
    _request = [[DFCompositeImageRequest alloc] initWithRequests:requests handler:^(UIImage *image, NSDictionary *info, BOOL isLastRequest) {
        NSError *error = info[DFImageInfoErrorKey];
        if (image != nil) {
            [weakSelf requestDidFinishWithImage:image info:info elapsedTime:CACurrentMediaTime() - startTime];
        } else if (!self.imageView.image){
            [weakSelf requestDidFailWithError:error info:info];
        } else {
            // Do nothing.
        }
    }];
    [_request start];
}

- (void)requestDidFinishWithImage:(UIImage *)image info:(NSDictionary *)info elapsedTime:(NSTimeInterval)elapsedTime {
    BOOL isFastResponse = (elapsedTime * 1000.0) < 33.2; // Elapsed time is lower then 32 ms.
    DFImageViewAnimation animation = DFImageViewAnimationNone;
    if (self.animation != DFImageViewAnimationNone) {
        if (self.imageView.image != nil) {
            animation = DFImageViewAnimationNone;
        } else {
            animation = isFastResponse ? DFImageViewAnimationNone : _animation;
        }
    }
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
    if (self.imageView.image != nil) {
        self.failureImageView.hidden = NO;
    }
}

#pragma mark - Reuse

- (void)prepareForReuse {
    self.imageView.image = nil;
    _failureImageView.hidden = YES;
    _backgroundView.alpha = 1.f;
    [self _df_cancelFetching];
    _request = nil;
    [self.layer removeAllAnimations];
    [_backgroundView.layer removeAllAnimations];
    [_imageView.layer removeAllAnimations];
}

- (void)_df_cancelFetching {
    [_request cancel];
}

#pragma mark - Priorities

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (self.managesRequestPriorities) {
        DFImageRequestPriority priority = (newWindow == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
        [_request setPriority:priority];
    }
}

#pragma mark - Animation

- (void)setImage:(UIImage *)image {
    [self _df_setImage:image withAnimation:DFImageViewAnimationNone];
}

- (void)_df_setImage:(UIImage *)image withAnimation:(DFImageViewAnimation)animationType {
    self.imageView.image = image;
    switch (animationType) {
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
            [UIView transitionWithView:self.imageView
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
