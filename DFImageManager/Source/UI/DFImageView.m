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

#import "DFCompositeImageTask.h"
#import "DFImageManager.h"
#import "DFImageManaging.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageTask.h"
#import "DFImageView.h"
#import "DFNetworkReachability.h"

#if DF_IMAGE_MANAGER_GIF_AVAILABLE
#import "DFImageManagerKit+GIF.h"
#endif

static const NSTimeInterval _kMinimumAutoretryInterval = 8.f;

@implementation DFImageView {
    NSTimeInterval _previousAutoretryTime;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _cancelFetching];
}

- (instancetype)initWithFrame:(CGRect)frame {
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
    
    _imageTargetSize = CGSizeZero;
    _imageContentMode = DFImageContentModeAspectFill;
    _allowsAnimations = YES;
    _allowsAutoRetries = YES;
    _managesRequestPriorities = NO;
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    _allowsGIFPlayback = YES;
#endif
    _imageRequestOptions = [DFImageRequestOptions new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_reachabilityDidChange:) name:DFNetworkReachabilityDidChangeNotification object:[DFNetworkReachability shared]];
}

- (void)displayImage:(UIImage *)image {
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
    _task = nil;
    _previousAutoretryTime = 0.0;
    self.image = nil;
#if DF_IMAGE_MANAGER_GIF_AVAILABLE
    self.animatedImage = nil;
#endif
    [self.layer removeAllAnimations];
}

- (void)_cancelFetching {
    [_task cancel];
}

- (CGSize)imageTargetSize {
    if (CGSizeEqualToSize(CGSizeZero, _imageTargetSize)) {
        CGSize size = self.bounds.size;
        CGFloat scale = [UIScreen mainScreen].scale;
        return CGSizeMake(size.width * scale, size.height * scale);
    }
    return _imageTargetSize;
}

- (void)setImageWithResource:(id)resource {
    [self setImageWithResource:resource targetSize:self.imageTargetSize contentMode:self.imageContentMode options:self.imageRequestOptions];
}

- (void)setImageWithResource:(id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(DFImageRequestOptions *)options {
    [self setImageWithRequest:[DFImageRequest requestWithResource:resource targetSize:targetSize contentMode:contentMode options:options]];
}

- (void)setImageWithRequest:(DFImageRequest *)request {
    [self setImageWithRequests:(@[request])];
}

- (void)setImageWithRequests:(NSArray *)requests {
    [self _cancelFetching];
    
    if ([self.delegate respondsToSelector:@selector(imageView:willStartFetchingImagesForRequests:)]) {
        [self.delegate imageView:self willStartFetchingImagesForRequests:requests];
    }
    NSParameterAssert(requests.count > 0);
    if (self.managesRequestPriorities) {
        for (DFImageRequest *request in requests) {
            request.options.priority = (self.window == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
        }
    }
    DFImageView *__weak weakSelf = self;
    _task = [self _createCompositeImageTaskForRequests:requests handler:^(UIImage *image, NSDictionary *info, DFCompositeImageTask *compositeTask) {
        DFImageTask *task = info[DFImageInfoTaskKey];
        [weakSelf.delegate imageView:self didCompleteRequest:task.request withImage:image info:info];
        [weakSelf didCompleteRequest:task.request withImage:image info:info];
    }];
    [self setNeedsUpdateConstraints];
    [_task resume];
}

- (DFCompositeImageTask *)_createCompositeImageTaskForRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFCompositeImageTask *))handler {
    NSMutableArray *tasks = [NSMutableArray new];
    for (DFImageRequest *request in requests) {
        DFImageTask *task = [self.imageManager imageTaskForRequest:request completion:nil];
        [tasks addObject:task];
    }
    return [[DFCompositeImageTask alloc] initWithImageTasks:tasks imageHandler:handler completionHandler:nil];
}

- (void)didCompleteRequest:(DFImageRequest *)request withImage:(UIImage *)image info:(NSDictionary *)info {
    BOOL isFastResponse = [info[DFImageInfoIsFromMemoryCacheKey] boolValue];
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
        [_task setPriority:priority];
    }
}

#pragma mark - Notifications

- (void)_reachabilityDidChange:(NSNotification *)notification {
    DFNetworkReachability *reachability = notification.object;
    if (self.allowsAutoRetries
        && reachability.isReachable
        && self.window != nil
        && self.hidden != YES
        && self.task.isFinished) {
        DFImageTask *task = [self.task.imageTasks lastObject];
        NSError *error = task.error;
        if (error && [self _isNetworkConnetionError:error]) {
            [self _attemptRetry];
        }
    }
}

- (void)_attemptRetry {
    if (_previousAutoretryTime == 0.0 || CACurrentMediaTime() > _previousAutoretryTime + _kMinimumAutoretryInterval) {
        _previousAutoretryTime = CACurrentMediaTime();
        [self setImageWithRequests:self.task.imageRequests];
    }
}

- (BOOL)_isNetworkConnetionError:(NSError *)error {
    return ([error.domain isEqualToString:NSURLErrorDomain] &&
            (error.code == NSURLErrorNotConnectedToInternet ||
             error.code == NSURLErrorTimedOut ||
             error.code == NSURLErrorCannotConnectToHost ||
             error.code == NSURLErrorNetworkConnectionLost));
}

@end
