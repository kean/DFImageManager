// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFAnimatedImage.h"
#import "DFAnimatedImageView.h"
#import "DFImageResponse.h"
#import "DFImageTask.h"

@implementation DFAnimatedImageView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _createUI];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self _createUI];
    }
    return self;
}

- (void)_createUI {
    _allowsGIFPlayback = YES;
    _animatedImageView = [[FLAnimatedImageView alloc] initWithFrame:self.bounds];
    _animatedImageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self addSubview:_animatedImageView];
}

- (void)displayImage:(nullable UIImage *)image {
    if (!image) {
        self.image = nil;
        self.animatedImageView.animatedImage = nil;
        return;
    }
    if (self.allowsGIFPlayback && [image isKindOfClass:[DFAnimatedImage class]]) {
        self.animatedImageView.animatedImage = ((DFAnimatedImage *)image).animatedImage;
    } else {
        self.image = image;
    }
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.animatedImageView.animatedImage = nil;
}

- (void)didCompleteImageTask:(DFImageTask *)task withImage:(UIImage *)image {
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

@end
