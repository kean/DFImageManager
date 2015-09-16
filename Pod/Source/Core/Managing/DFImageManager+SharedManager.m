// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageManager.h"
#import <libkern/OSAtomic.h>

@implementation DFImageManager (SharedManager)

static id<DFImageManaging> _sharedManager;
static OSSpinLock _lock = OS_SPINLOCK_INIT;

+ (nonnull id<DFImageManaging>)sharedManager {
    id<DFImageManaging> manager;
    OSSpinLockLock(&_lock);
    manager = _sharedManager;
    OSSpinLockUnlock(&_lock);
    return manager;
}

+ (void)setSharedManager:(nonnull id<DFImageManaging>)manager {
    OSSpinLockLock(&_lock);
    _sharedManager = manager;
    OSSpinLockUnlock(&_lock);
}

@end
