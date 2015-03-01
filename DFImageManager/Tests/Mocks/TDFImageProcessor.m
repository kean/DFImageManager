//
//  TDFImageProcessor.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFImageProcessor.h"

@implementation TDFImageProcessor

- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return CGSizeEqualToSize(request1.targetSize, request2.targetSize);
}

- (UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    _numberOfProcessedImageCalls++;
    return image;
}

@end
