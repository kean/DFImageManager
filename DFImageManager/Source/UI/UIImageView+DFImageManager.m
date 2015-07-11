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

- (void)df_setImageWithResource:(id)resource {
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize targetSize = CGSizeMake(self.bounds.size.width * scale, self.bounds.size.height * scale);
    [self df_setImageWithResource:resource targetSize:targetSize contentMode:DFImageContentModeAspectFill options:nil];
}

- (void)df_setImageWithResource:(id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self _df_cancelFetching];
    
    UIImageView *__weak weakSelf = self;
    DFImageRequest *request = [DFImageRequest requestWithResource:resource targetSize:targetSize contentMode:contentMode options:options];
    DFImageTask *task = [[DFImageManager sharedManager] imageTaskForRequest:request completion:^(UIImage *image, NSDictionary *info) {
        if (image) {
            weakSelf.image = image;
        }
    }];
    [task resume];
    [self _df_setImageTask:task];
}

- (void)_df_cancelFetching {
    [[self _df_imageTask] cancel];
}

@end
