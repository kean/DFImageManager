// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import <UIKit/UIKit.h>
#import "DFProgressiveImageDecoder.h"
#import "DFImageDecoding.h"

@interface DFProgressiveImageDecoder () <NSLocking>

@property (nonnull, nonatomic, readonly) id<DFImageDecoding> decoder;
@property (nonnull, nonatomic, readonly) NSOperationQueue *queue;
@property (nonnull, nonatomic, readonly) NSMutableData *data;
@property (nonatomic) BOOL executing;
@property (nonatomic) BOOL decoding;
@property (nonatomic) uint64_t decodedByteCount;
@property (nonnull, nonatomic, readonly) NSRecursiveLock *recursiveLock;

@end

@implementation DFProgressiveImageDecoder

- (nonnull instancetype)initWithQueue:(nonnull NSOperationQueue *)queue decoder:(nonnull id<DFImageDecoding>)decoder {
    if (self = [super init]) {
        _decoder = decoder;
        _queue = queue;
        _data = [NSMutableData new];
        _recursiveLock = [NSRecursiveLock new];
    }
    return self;
}

- (void)resume {
    [self lock];
    if (!_executing) {
        _executing = YES;
        [self _decodeIfNeeded];
    }
    [self unlock];
}

- (void)invalidate {
    [self lock];
    _executing = NO;
    _data = nil;
    [self unlock];
}

- (void)appendData:(nullable NSData *)data {
    if (data.length) {
        [self lock];
        [_data appendData:data];
        [self _decodeIfNeeded];
        [self unlock];
    }
}

- (void)_decodeIfNeeded {
    if (_decoding || !_executing) {
        return;
    }
    if (_data.length <= _decodedByteCount) {
        return;
    }
    if (self.totalByteCount > 0) {
        if ((_data.length / (_totalByteCount * 1.0)) - (_decodedByteCount / (_totalByteCount * 1.0)) < _threshold) {
            return;
        }
    }
    _decoding = YES;
    typeof(self) __weak weakSelf = self;
    [_queue addOperationWithBlock:^{
        DFProgressiveImageDecoder *strongSelf = weakSelf;
        if (!strongSelf || !strongSelf.executing) {
            return;
        }
        [strongSelf lock];
        NSData *data = [strongSelf.data copy];
        [strongSelf unlock];
        UIImage *image = [strongSelf.decoder imageWithData:data partial:YES];
        void (^handler)(UIImage *) = strongSelf.handler;
        if (image && handler) {
            handler(image);
        }
        [strongSelf lock];
        strongSelf.decodedByteCount = data.length;
        strongSelf.decoding = NO;
        [self _decodeIfNeeded];
        [strongSelf unlock];
    }];
}

#pragma mark <NSLocking>

- (void)lock {
    [_recursiveLock lock];
}

- (void)unlock {
    [_recursiveLock unlock];
}

@end
