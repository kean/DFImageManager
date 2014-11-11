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

#import "UIImageView+DFImageManager.h"

@implementation UIImageView (DFImageManager)

- (void)df_setImage:(UIImage *)image withAnimation:(DFImageViewAnimation)animation {
   self.image = image;
   switch (animation) {
      case DFImageViewAnimationNone:
         break;
      case DFImageViewAnimationFade: {
         CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:@"opacity"];
         animation.keyPath = @"opacity";
         animation.fromValue = @0.f;
         animation.toValue = @1.f;
         animation.duration = 0.15f;
         [self.layer addAnimation:animation forKey:@"opacity"];
      }
         break;
      case DFImageViewAnimationCrossDissolve: {
         [UIView transitionWithView:self
                           duration:0.2f
                            options:UIViewAnimationOptionTransitionCrossDissolve
                         animations:nil
                         completion:nil];
      }
         break;
      default:
         break;
   }
}

@end
