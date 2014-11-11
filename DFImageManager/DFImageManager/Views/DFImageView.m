// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

#import "DFImageManagerProtocol.h"
#import "DFImageRequestOptions.h"
#import "DFImageView.h"


@implementation DFImageView {
   DFImageRequestID *_requestID;
}

- (instancetype)initWithFrame:(CGRect)frame {
   if (self = [super initWithFrame:frame]) {
      _animation = DFImageViewAnimationFade;
      _managesRequestPriorities = YES;
   }
   return self;
}

- (void)setImageWithAsset:(id)asset {
   [self setImageWithAsset:asset options:nil];
}

- (void)setImageWithAsset:(id)asset options:(DFImageRequestOptions *)options {
   DFImageView *__weak weakSelf = self;
   options = options ?: [self.imageManager requestOptionsForAsset:asset];
   if (self.managesRequestPriorities) {
      options.priority = (self.window == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
   }
   _requestID = [self.imageManager requestImageForAsset:asset options:options completion:^(UIImage *image, NSDictionary *info) {
      DFImageSource source = [info[DFImageInfoSourceKey] unsignedIntegerValue];
      NSError *error = info[DFImageInfoErrorKey];
      if (image) {
         [weakSelf requestDidFinishWithImage:image source:source info:info];
      } else {
         [weakSelf requestDidFailWithError:error info:info];
      }
   }];
}

- (void)requestDidFinishWithImage:(UIImage *)image source:(DFImageSource)source info:(NSDictionary *)info {
   DFImageViewAnimation animation = source != DFImageSourceMemoryCache ? _animation : DFImageViewAnimationNone;
   [self df_setImage:image withAnimation:animation];
   
}

- (void)requestDidFailWithError:(NSError *)error info:(NSDictionary *)info {
   // do nothing
}

- (void)prepareForReuse {
   self.image = nil;
   [self _df_cancelFetching];
   _requestID = nil;
}

- (void)_df_cancelFetching {
   if (_requestID) {
      [self.imageManager cancelRequestWithID:_requestID];
   }
}

#pragma mark - Priorities

- (void)willMoveToWindow:(UIWindow *)newWindow {
   [super willMoveToWindow:newWindow];
   if (self.managesRequestPriorities) {
      DFImageRequestPriority priority = (newWindow == nil) ? DFImageRequestPriorityNormal : DFImageRequestPriorityVeryHigh;
      if (_requestID) {
         [self.imageManager setPriority:priority forRequestWithID:_requestID];
      }
   }
}

@end
