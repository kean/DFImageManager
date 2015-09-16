// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManager.h"
#import "DFImageRequest+UIKitAdditions.h"
#import "DFImageRequest.h"
#import "DFImageTask.h"
#import "UIImageView+DFImageManager.h"
#import <objc/runtime.h>

static char *_imageTaskKey;

@implementation UIImageView (DFImageManager)

- (DFImageTask *)_df_imageTask {
    return objc_getAssociatedObject(self, &_imageTaskKey);
}

- (void)_df_setImageTask:(DFImageTask *)task {
    objc_setAssociatedObject(self, &_imageTaskKey, task, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (void)df_prepareForReuse {
    self.image = nil;
    [self _df_cancelFetching];
}

- (nullable DFImageTask *)df_setImageWithResource:(nullable id)resource {
    return [self df_setImageWithResource:resource targetSize:[DFImageRequest targetSizeForView:self] contentMode:DFImageContentModeAspectFill options:nil];
}

- (nullable DFImageTask *)df_setImageWithResource:(nullable id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options {
    return [self df_setImageWithRequest:(resource ? [DFImageRequest requestWithResource:resource targetSize:targetSize contentMode:contentMode options:options] : nil)];
}

- (nullable DFImageTask *)df_setImageWithRequest:(nullable DFImageRequest *)request {
    [self _df_cancelFetching];
    if (!request) {
        return nil;
    }
    typeof(self) __weak weakSelf = self;
    DFImageTask *task = [[DFImageManager sharedManager] imageTaskForRequest:request completion:^(UIImage *__nullable image, NSError *__nullable error, DFImageResponse *__nullable response, DFImageTask *__nonnull imageTask){
        if (image) {
            weakSelf.image = image;
        }
    }];
    task.progressiveImageHandler = ^(UIImage *__nonnull image){
        weakSelf.image = image;
    };
    [task resume];
    [self _df_setImageTask:task];
    return task;
}

- (void)_df_cancelFetching {
    DFImageTask *imageTask = [self _df_imageTask];
    imageTask.completionHandler = nil;
    imageTask.progressiveImageHandler = nil;
    [imageTask cancel];
    [self _df_setImageTask:nil];
}

@end
