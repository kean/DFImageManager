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
#import "DFImageManager.h"
#import "DFImageManaging.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageView.h"
#import "DFNetworkReachability.h"

#if __has_include("DFAnimatedImage.h")
#import "DFAnimatedImage.h"
#endif


static const NSTimeInterval _kMinimumAutoretryInterval = 8.f;

@implementation DFImageView {
    NSTimeInterval _previousAutoretryTime;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self _df_cancelFetching];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self _df_commonInit];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self _df_commonInit];
    }
    return self;
}

- (void)_df_commonInit {
    self.contentMode = UIViewContentModeScaleAspectFill;
    self.clipsToBounds = YES;
    
    self.imageManager = [DFImageManager sharedManager];
    
    _imageTargetSize = CGSizeZero;
    _imageContentMode = DFImageContentModeAspectFill;
    _allowsAnimations = YES;
    _allowsAutoRetries = YES;
    _managesRequestPriorities = NO;
#if __has_include("DFAnimatedImage.h")
    _allowsGIFPlayback = YES;
#endif
    _imageRequestOptions = [DFImageRequestOptions new];
    
    self.delegate = self;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_reachabilityDidChange:) name:DFNetworkReachabilityDidChangeNotification object:[DFNetworkReachability shared]];
}

- (void)displayImage:(UIImage *)image {
#if __has_include("DFAnimatedImage.h")
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
    [self _df_cancelFetching];
    _operation = nil;
    _previousAutoretryTime = 0.0;
    self.image = nil;
#if __has_include("DFAnimatedImage.h")
    self.animatedImage = nil;
#endif
    [self.layer removeAllAnimations];
}

- (void)_df_cancelFetching {
    [_operation cancel];
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
    DFImageRequest *request;
    if (resource != nil) {
        request = [[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options];
    }
    [self setImageWithRequest:request];
}

- (void)setImageWithRequest:(DFImageRequest *)request {
    [self setImageWithRequests:(request != nil) ? @[request] : nil];
}

- (void)setImageWithRequests:(NSArray *)requests {
    [self _df_cancelFetching];
    
    if ([self.delegate respondsToSelector:@selector(imageView:willStartFetchingImagesForRequests:)]) {
        [self.delegate imageView:self willStartFetchingImagesForRequests:requests];
    }
    
    if (requests.count > 0) {
        if (self.managesRequestPriorities) {
            for (DFImageRequest *request in requests) {
                request.options.priority = (self.window == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
            }
        }
        
        DFImageView *__weak weakSelf = self;
        _operation = [self createCompositeImageFetchOperationForRequests:requests handler:^(UIImage *image, NSDictionary *info, DFImageRequest *request) {
            [weakSelf.delegate imageView:weakSelf didCompleteRequest:request withImage:image info:info];
        }];
        [_operation start];
    }
}

- (DFCompositeImageFetchOperation *)createCompositeImageFetchOperationForRequests:(NSArray *)requests handler:(void (^)(UIImage *, NSDictionary *, DFImageRequest *))handler {
    return [[DFCompositeImageFetchOperation alloc] initWithRequests:requests handler:handler];
}

#pragma mark - Priorities

- (void)willMoveToWindow:(UIWindow *)newWindow {
    [super willMoveToWindow:newWindow];
    if (self.managesRequestPriorities) {
        DFImageRequestPriority priority = (newWindow == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
        [_operation setPriority:priority];
    }
}

#pragma mark - <DFImageViewDelegate>

- (void)imageView:(DFImageView *)imageView didCompleteRequest:(DFImageRequest *)request withImage:(UIImage *)image info:(NSDictionary *)info {
    BOOL isFastResponse = (_operation.elapsedTime * 1000.0) < 64.f; // Elapsed time is lower then 64 ms, if we miss 4 frames, that's good enough
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

#pragma mark - Notifications

- (void)_reachabilityDidChange:(NSNotification *)notification {
    DFNetworkReachability *reachability = notification.object;
    if (self.allowsAutoRetries
        && reachability.isReachable
        && self.window != nil
        && self.hidden != YES
        && self.operation.isFinished) {
        DFCompositeImageRequestContext *context = [self.operation contextForRequest:[self.operation.requests lastObject]];
        NSError *error = context.info[DFImageInfoErrorKey];
        if (error && [self _isNetworkConnetionError:error]) {
            [self _attemptRetry];
        }
    }
}

- (void)_attemptRetry {
    if (_previousAutoretryTime == 0.0 || CACurrentMediaTime() > _previousAutoretryTime + _kMinimumAutoretryInterval) {
        _previousAutoretryTime = CACurrentMediaTime();
        [self setImageWithRequests:self.operation.requests];
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
