//
//  TDFImageProcessor.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockImageProcessor.h"

@implementation TDFMockImageProcessor

- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return CGSizeEqualToSize(request1.targetSize, request2.targetSize);
}

- (UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    _numberOfProcessedImageCalls++;
    if (self.processingTime > 0.0) {
        [NSThread sleepForTimeInterval:self.processingTime];
    }
    return image;
}

@end
