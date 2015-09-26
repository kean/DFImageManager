// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageTask.h"

@implementation DFImageTask

- (DFImageTask *)resume {
    [NSException raise:NSInternalInconsistencyException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
    return self;
}

- (void)cancel {
    [NSException raise:NSInternalInconsistencyException format:@"Abstract method called %@", NSStringFromSelector(_cmd)];
}

- (id)copyWithZone:(NSZone *)zone {
    return self;
}

@end
