// The MIT License (MIT)
//
// Copyright (c) 2015 Alexander Grebenyuk (github.com/kean).

#import "DFAnimatedImage.h"
#import "DFAnimatedImageProcessor.h"
#import "DFImageManagerDefines.h"

@implementation DFAnimatedImageProcessor {
    id<DFImageProcessing> _processor;
}

DF_INIT_UNAVAILABLE_IMPL

- (instancetype)initWithProcessor:(id<DFImageProcessing>)processor {
    if (self = [super init]) {
        _processor = processor;
    }
    return self;
}

- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return [_processor isProcessingForRequestEquivalent:request1 toRequest:request2];
}

- (BOOL)shouldProcessImage:(UIImage *)image forRequest:(DFImageRequest *)request partial:(BOOL)partial {
    if ([image isKindOfClass:[DFAnimatedImage class]]) {
        return NO;
    }
    if ([_processor respondsToSelector:@selector(shouldProcessImage:forRequest:partial:)]) {
        return [_processor shouldProcessImage:image forRequest:request partial:partial];
    }
    return YES;
}

- (UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request partial:(BOOL)partial {
    return [_processor processedImage:image forRequest:request partial:partial];
}

@end
