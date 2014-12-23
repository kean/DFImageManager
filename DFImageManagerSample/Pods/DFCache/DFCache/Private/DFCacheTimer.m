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

#import "DFCacheTimer.h"
#import <objc/runtime.h>

@implementation DFCacheTimer

static char _blockToken;

+ (NSTimer *)scheduledTimerWithTimeInterval:(NSTimeInterval)timeInterval block:(void (^)())block userInfo:(id)userInfo repeats:(BOOL)repeats {
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:timeInterval target:self selector:@selector(_timerDidFire:) userInfo:userInfo repeats:repeats];
    objc_setAssociatedObject(timer, &_blockToken, block, OBJC_ASSOCIATION_COPY);
    return timer;
}

+ (NSTimer *)timerWithTimeInterval:(NSTimeInterval)timeInterval block:(void (^)())block userInfo:(id)userInfo repeats:(BOOL)repeats {
    NSTimer *timer = [NSTimer timerWithTimeInterval:timeInterval target:self selector:@selector(_timerDidFire:) userInfo:userInfo repeats:repeats];
    objc_setAssociatedObject(timer, &_blockToken, block, OBJC_ASSOCIATION_COPY);
    return timer;
}

+ (void)_timerDidFire:(NSTimer *)timer {
    void (^block)() = objc_getAssociatedObject(timer, &_blockToken);
    if (block) {
        block();
    }
}

@end
