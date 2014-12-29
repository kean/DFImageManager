// The MIT License (MIT)
//
// Copyright (c) 2014 Alexander Grebenyuk (github.com/kean).
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

#import "DFValueTransformerFactory.h"


@implementation DFValueTransformerFactory {
    NSMutableDictionary *_transformers;
}

static id<DFValueTransformerFactory> _sharedFactory;

+ (void)initialize {
    [self setDefaultFactory:[DFValueTransformerFactory new]];
}

- (instancetype)init {
    if (self = [super init]) {
        _transformers = [NSMutableDictionary new];

        [self registerValueTransformer:[DFValueTransformerNSCoding new] forName:DFValueTransformerNSCodingName];
        [self registerValueTransformer:[DFValueTransformerJSON new] forName:DFValueTransformerJSONName];
        
#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
        DFValueTransformerUIImage *transformerUIImage = [DFValueTransformerUIImage new];
        transformerUIImage.compressionQuality = 0.75f;
        transformerUIImage.allowsImageDecompression = YES;
        [self registerValueTransformer:transformerUIImage forName:DFValueTransformerUIImageName];
#endif
    }
    return self;
}

- (void)registerValueTransformer:(id<DFValueTransforming>)valueTransformer forName:(NSString *)name {
    _transformers[name] = valueTransformer;
}

- (id<DFValueTransforming>)valueTransformerForName:(NSString *)name {
    return _transformers[name];
}

#pragma mark - <DFValueTransformerFactory>

- (NSString *)valueTransformerNameForValue:(id)value {
#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
    if ([value isKindOfClass:[UIImage class]]) {
        return DFValueTransformerUIImageName;
    }
#endif
    
    if ([value conformsToProtocol:@protocol(NSCoding)]) {
        return DFValueTransformerNSCodingName;
    }
    
    return nil;
}

#pragma mark - Dependency Injectors

+ (id<DFValueTransformerFactory>)defaultFactory {
    return _sharedFactory;
}

+ (void)setDefaultFactory:(id<DFValueTransformerFactory>)factory {
    _sharedFactory = factory;
}

@end
