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
