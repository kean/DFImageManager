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

#import "DFImageProcessor.h"
#import "DFImageRequest.h"
#import "DFImageRequestOptions.h"
#import "DFImageUtilities.h"

NSString *DFImageProcessingCornerRadiusKey = @"DFImageProcessingCornerRadiusKey";


@implementation DFImageProcessor

#pragma mark - <DFImageProcessing>

- (BOOL)isProcessingForRequestEquivalent:(DFImageRequest *)request1 toRequest:(DFImageRequest *)request2 {
    if (request1 == request2) {
        return YES;
    }
    if (!(CGSizeEqualToSize(request1.targetSize, request2.targetSize) &&
          request1.contentMode == request2.contentMode &&
          request1.options.allowsClipping == request2.options.allowsClipping)) {
        return NO;
    }
    NSDictionary *userInfo1 = request1.options.userInfo;
    NSDictionary *userInfo2 = request2.options.userInfo;
    if (!userInfo1.count && !userInfo2.count) {
        return YES;
    }
    return [userInfo1 isEqualToDictionary:userInfo2];
}

- (UIImage *)processedImage:(UIImage *)image forRequest:(DFImageRequest *)request {
    NSDictionary *userInfo = request.options.userInfo;
    
    switch (request.contentMode) {
        case DFImageContentModeAspectFit:
            image = [DFImageUtilities decompressedImageWithImage:image aspectFitPixelSize:request.targetSize];
            break;
        case DFImageContentModeAspectFill: {
            if (request.options.allowsClipping) {
                image = [DFImageUtilities croppedImageWithImage:image aspectFillPixelSize:request.targetSize];
            }
            image = [DFImageUtilities decompressedImageWithImage:image aspectFillPixelSize:request.targetSize];
        }
            break;
        default:
            break;
    }
    NSNumber *normalizedCornerRadius = userInfo[DFImageProcessingCornerRadiusKey];
    if (normalizedCornerRadius != nil) {
        CGFloat cornerRadius = [normalizedCornerRadius floatValue] * MIN(image.size.width, image.size.height);
        image = [DFImageUtilities imageWithImage:image cornerRadius:cornerRadius];
    }
    return image;
}

@end
