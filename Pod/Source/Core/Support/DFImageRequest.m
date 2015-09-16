// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"

@implementation DFImageRequest

DF_INIT_UNAVAILABLE_IMPL

- (nonnull instancetype)initWithResource:(nonnull id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options {
    if (self = [super init]) {
        _resource = resource;
        _targetSize = targetSize;
        _contentMode = contentMode;
        _options = options ?: [DFImageRequestOptions new];
    }
    return self;
}

+ (nonnull instancetype)requestWithResource:(nonnull id)resource {
    return [[[self class] alloc] initWithResource:resource targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil];
}

+ (nonnull instancetype)requestWithResource:(nonnull id)resource targetSize:(CGSize)targetSize contentMode:(DFImageContentMode)contentMode options:(nullable DFImageRequestOptions *)options {
    return [[[self class] alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options];
}

@end
