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

- (instancetype)init {
    if (self = [super init]) {
        _priority = DFImageRequestPriorityNormal;
        _allowsNetworkAccess = YES;
        _allowsClipping = NO;
        _memoryCachePolicy = DFImageRequestCachePolicyDefault;
        _expirationAge = 60.0 * 10.0; // 600.0 seconds
    }
    return self;
}

- (instancetype)initWithOptions:(DFImageRequestOptions *)options {
    if (self = [self init]) {
        if (options) {
            _priority = options.priority;
            _allowsNetworkAccess = options.allowsNetworkAccess;
            _allowsClipping = options.allowsClipping;
            _memoryCachePolicy = options.memoryCachePolicy;
            _expirationAge = options.expirationAge;
            _progressHandler = [options.progressHandler copy];
            _userInfo = [options.userInfo copy];
        }
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    return [((DFImageRequestOptions *)[[self class] allocWithZone:zone]) initWithOptions:self];
}

- (NSString *)description {
    return [NSString stringWithFormat:@"<%@ %p> { priority = %i, network = %i, clip = %i, cache = %i, expires = %0.2f }", [self class], self, (int)_priority, _allowsNetworkAccess, _allowsClipping, _memoryCachePolicy == DFImageRequestCachePolicyDefault ? 1 : 0, _expirationAge];
}

@end
