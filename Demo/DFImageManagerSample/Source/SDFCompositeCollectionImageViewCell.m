//
//  SDFCompositeCollectionImageViewCell.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 15/08/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFCompositeCollectionImageViewCell.h"
#import <DFImageManager/DFImageManagerKit.h>

@interface SDFCompositeCollectionImageViewCell ()

@property (nonnull, nonatomic, readonly) UIImageView *imageView;

@end

@implementation SDFCompositeCollectionImageViewCell {
    DFCompositeImageTask *_compositeImageTask;
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor colorWithWhite:235.f/255.f alpha:1.f];
        
        _imageView = [UIImageView new];
        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        [self addSubview:_imageView];
        
        _imageView.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(_imageView);
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_imageView]|" options:kNilOptions metrics:nil views:views]];
        [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_imageView]|" options:kNilOptions metrics:nil views:views]];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    
    _imageView.image = nil;
    [self _cancelFetching];
}

- (void)_cancelFetching {
    [_compositeImageTask cancel];
    _compositeImageTask = nil;
}

- (void)setImageWithRequests:(NSArray *)requests {
    [self _cancelFetching];
    
    typeof(self) __weak weakSelf = self;
    _compositeImageTask = [DFCompositeImageTask compositeImageTaskWithRequests:requests imageHandler:^(UIImage *__nullable image, DFImageTask *__nonnull completedTask, DFCompositeImageTask *__nonnull task){
        if (image) {
            weakSelf.imageView.image = image;
        }
    } completionHandler:nil];
    [_compositeImageTask resume];
}

@end
