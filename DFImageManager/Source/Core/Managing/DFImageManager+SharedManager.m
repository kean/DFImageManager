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

#import "DFCompositeImageManager.h"
#import "DFImageManager.h"
#import <libkern/OSAtomic.h>

@implementation DFImageManager (SharedManager)

static id<DFImageManaging> _sharedManager;
static OSSpinLock _lock = OS_SPINLOCK_INIT;

+ (void)initialize {
    _sharedManager = [self createDefaultManager];
}

+ (id<DFImageManaging>)sharedManager {
    id<DFImageManaging> manager;
    OSSpinLockLock(&_lock);
    manager = _sharedManager;
    OSSpinLockUnlock(&_lock);
    return manager;
}

+ (void)setSharedManager:(id<DFImageManaging>)manager {
    OSSpinLockLock(&_lock);
    _sharedManager = manager;
    OSSpinLockUnlock(&_lock);
}

+ (void)addSharedManager:(id<DFImageManaging>)manager {
    NSMutableArray *managers = [NSMutableArray arrayWithObject:manager];
    id<DFImageManaging> sharedManager = [self sharedManager];
    if (sharedManager) {
        [managers addObject:sharedManager];
    }
    [self setSharedManager:[[DFCompositeImageManager alloc] initWithImageManagers:managers]];
}

@end
