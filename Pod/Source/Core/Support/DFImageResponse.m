// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageResponse.h"

@implementation DFImageResponse

- (nonnull instancetype)initWithInfo:(nullable NSDictionary *)info isFastResponse:(BOOL)isFastResponse {
    if (self = [super init]) {
        _info = info;
        _isFastResponse = isFastResponse;
    }
    return self;
}

@end
