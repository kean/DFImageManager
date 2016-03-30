// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManager.h"
#import "DFImageManagerDefines.h"
#import "DFImageManaging.h"
#import "DFImageRequest+UIKitAdditions.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageResponse.h"
#import "DFImageTask.h"
#import "DFImageView.h"

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

- (instancetype)initWithCoder:(NSCoder *)decoder {
    if (self = [super initWithCoder:decoder]) {
        [self _commonInit];
    }
    return self;
}

- (void)_commonInit {
    self.imageManager = [DFImageManager sharedManager];
    _allowsAnimations = YES;
    _fadeDuration = 0.25f;
}

- (void)prepareForReuse {
    [self _cancelFetching];
    self.image = nil;
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
        self.image = image;
        [self.layer addAnimation:({
            CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
            animation.keyPath = @"opacity";
            animation.fromValue = @0.f;
            animation.toValue = @1.f;
            animation.duration = self.fadeDuration;
            animation;
        }) forKey:@"opacity"];
    } else {
        self.image = image;
    }
}

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (self.managesRequestPriorities) {
        [_imageTask setPriority:(newWindow ? DFImageRequestPriorityNormal: DFImageRequestPriorityLow)];
    }
}

@end
