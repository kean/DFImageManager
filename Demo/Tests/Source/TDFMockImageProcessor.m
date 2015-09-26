//
//  TDFImageProcessor.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockImageProcessor.h"
#import <objc/runtime.h>

static char *_imageProcessedKey;

@implementation UIImage (TDFMockImageProcessor)

- (BOOL)tdf_isImageProcessed {
    return [objc_getAssociatedObject(self, &_imageProcessedKey) boolValue];
}

@end



@implementation TDFMockImageProcessor

- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    return CGSizeEqualToSize(request1.targetSize, request2.targetSize);
}

- (UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request partial:(BOOL)partial {
    objc_setAssociatedObject(image, &_imageProcessedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return image;
}

@end
