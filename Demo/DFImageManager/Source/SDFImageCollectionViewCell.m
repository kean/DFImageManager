//
//  SDFImageCollectionViewCell.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 20/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFImageCollectionViewCell.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+UI.h>
#import <DFImageManager/DFImageManagerKit+GIF.h>

@interface SDFImageCollectionViewCell ()

@property (nonatomic, readonly) UIProgressView *progressView;
@property (nonatomic) NSProgress *currentProgress;

@end

@implementation SDFImageCollectionViewCell

- (void)dealloc {
    self.currentProgress = nil;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _imageView = [DFAnimatedImageView new];
        _progressView = [UIProgressView new];
        
        [self addSubview:_imageView];
        [self addSubview:_progressView];
        
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        _progressView.translatesAutoresizingMaskIntoConstraints = NO;
        
        NSDictionary *views = NSDictionaryOfVariableBindings(_imageView, _progressView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_imageView]|" options:kNilOptions metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]|" options:kNilOptions metrics:nil views:views]];
        
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_progressView]|" options:kNilOptions metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_progressView(==4)]" options:kNilOptions metrics:nil views:views]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    self.progressView.progress = 0;
    self.progressView.alpha = 1;
    self.currentProgress = nil;
    [self.imageView prepareForReuse];
}

- (void)setImageWithURL:(NSURL *)imageURL {
    [self setImageWithRequest:[DFImageRequest requestWithResource:imageURL]];
}

- (void)setImageWithRequest:(DFImageRequest *)request {
    [_imageView setImageWithRequest:request];
    self.currentProgress = _imageView.imageTask.progress;
    if (_imageView.imageTask.state == DFImageTaskStateCompleted) {
        self.progressView.alpha = 0;
    }
}

- (void)setCurrentProgress:(NSProgress *)currentProgress {
    if (_currentProgress != currentProgress) {
        [_currentProgress removeObserver:self forKeyPath:@"fractionCompleted" context:nil];
        _currentProgress = currentProgress;
        [self.progressView setProgress:currentProgress.fractionCompleted];
        [currentProgress addObserver:self forKeyPath:@"fractionCompleted" options:kNilOptions context:nil];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if (object == _currentProgress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressView setProgress:_currentProgress.fractionCompleted animated:YES];
            if (_currentProgress.fractionCompleted == 1) {
                [UIView animateWithDuration:0.2 animations:^{
                    self.progressView.alpha = 0;
                }];
            }
        });
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
