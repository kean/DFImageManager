// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFCachedImageResponse.h"
#import "DFImageManagerDefines.h"

@implementation DFCachedImageResponse

DF_INIT_UNAVAILABLE_IMPL

- (nullable instancetype)initWithImage:(nonnull UIImage *)image info:(nullable NSDictionary *)info expirationDate:(NSTimeInterval)expirationDate {
    if (self = [super init]) {
        _image = image;
        _info = info;
        _expirationDate = expirationDate;
    }
    return self;
}

@end
