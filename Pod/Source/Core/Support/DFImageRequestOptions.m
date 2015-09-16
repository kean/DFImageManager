// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFImageRequestOptions.h"

@implementation DFImageRequestOptions

- (nonnull instancetype)init {
    return [self initWithBuilder:[DFMutableImageRequestOptions new]];
}

- (nonnull instancetype)initWithBuilder:(nonnull DFMutableImageRequestOptions *)builder {
    if (self = [super init]) {
        _priority = builder.priority;
        _allowsNetworkAccess = builder.allowsNetworkAccess;
        _allowsClipping = builder.allowsClipping;
        _allowsProgressiveImage = builder.allowsProgressiveImage;
        _memoryCachePolicy = builder.memoryCachePolicy;
        _expirationAge = builder.expirationAge;
        _userInfo = builder.userInfo;
    }
    return self;
}

@end


@implementation DFMutableImageRequestOptions

static DFMutableImageRequestOptions *_defaultOptions;

+ (void)initialize {
    _defaultOptions = [DFMutableImageRequestOptions new];
    _defaultOptions.priority = DFImageRequestPriorityNormal;
    _defaultOptions.allowsNetworkAccess = YES;
    _defaultOptions.memoryCachePolicy = DFImageRequestCachePolicyDefault;
    _defaultOptions.expirationAge = 60.0 * 10.0; // 600.0 seconds
}

+ (instancetype)defaultOptions {
    return _defaultOptions;
}

- (nonnull instancetype)init {
    if (self = [super init]) {
        DFImageRequestOptions *defaults = [[self class] defaultOptions];
        if (defaults) {
            _priority = defaults.priority;
            _allowsNetworkAccess = defaults.allowsNetworkAccess;
            _allowsClipping = defaults.allowsClipping;
            _allowsProgressiveImage = defaults.allowsProgressiveImage;
            _memoryCachePolicy = defaults.memoryCachePolicy;
            _expirationAge = defaults.expirationAge;
            _userInfo = [defaults.userInfo copy];
        }
    }
    return self;
}

- (DFImageRequestOptions * __nonnull)options {
    return [[DFImageRequestOptions alloc] initWithBuilder:self];
}

@end
