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

#import "DFCompositeImageFetchOperation.h"
#import "DFImageContainerView.h"


@implementation DFImageContainerView {
    UIView *_backgroundView;
    UIImageView *_failureImageView;
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
    _animation = DFImageViewAnimationFade;
    
    _placeholderColor = [UIColor colorWithWhite:235.f/255.f alpha:1.f];
    self.clipsToBounds = YES;
    
    _backgroundView = ({
        UIView *view = [[UIView alloc] initWithFrame:self.bounds];
        view.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        view.backgroundColor = self.placeholderColor;
        view;
    });
    
    _imageView = ({
        DFImageView *imageView = [self createImageView];
        imageView.delegate = self;
        imageView.frame = self.bounds;
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        imageView.clipsToBounds = YES;
        imageView;
    });
    
    [self addSubview:_backgroundView];
    [self addSubview:_imageView];
}

- (DFImageView *)createImageView {
    return [DFImageView new];
}

- (void)setPlaceholderColor:(UIColor *)placeholderColor {
    _placeholderColor = placeholderColor;
    _backgroundView.backgroundColor = placeholderColor;
}

- (UIImageView *)failureImageView {
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

#pragma mark - <DFImageViewDelegate>

- (void)imageView:(DFImageView *)imageView willStartFetchingImagesForRequests:(NSArray *)requests {
    if (requests.count == 0) {
        [self _handleFailureWithError:nil];
    }
}

- (void)imageView:(DFImageView *)imageView didCompleteRequest:(DFImageRequest *)request withImage:(UIImage *)image info:(NSDictionary *)info {
    BOOL isFastResponse = (self.imageView.operation.elapsedTime * 1000.0) < 64.f;
    if (image) {
        DFImageViewAnimation animation = DFImageViewAnimationNone;
        if (self.animation != DFImageViewAnimationNone) {
            if (self.imageView.image != nil) {
                animation = DFImageViewAnimationNone;
            } else {
                animation = isFastResponse ? DFImageViewAnimationNone : _animation;
            }
        }
        [self _setImage:image withAnimation:animation];
    } else {
        [self _handleFailureWithError:info[DFImageInfoErrorKey]];
    }
}

- (void)_handleFailureWithError:(NSError *)error {
    if (self.imageView.image == nil) {
        self.failureImageView.hidden = NO;
    }
}

#pragma mark - Reuse

- (void)prepareForReuse {
    [self.imageView prepareForReuse];
    _failureImageView.hidden = YES;
    _backgroundView.alpha = 1.f;
    [self.layer removeAllAnimations];
    [_backgroundView.layer removeAllAnimations];
    [_imageView.layer removeAllAnimations];
}

#pragma mark - Animation

- (void)setImage:(UIImage *)image {
    [self _setImage:image withAnimation:DFImageViewAnimationNone];
}

- (void)_setImage:(UIImage *)image withAnimation:(DFImageViewAnimation)animationType {
    [self.imageView displayImage:image];
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
                animation.duration = 0.25f;
                animation;
            }) forKey:@"opacity"];
            
            _backgroundView.alpha = 0.f;
            [_backgroundView.layer addAnimation:({
                CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
                animation.keyPath = @"opacity";
                animation.fromValue = @1.f;
                animation.toValue = @0.f;
                animation.duration = 0.25f;
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
