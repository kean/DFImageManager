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

#import "DFURLImageDeserializer.h"
#import <UIKit/UIKit.h>

#if __has_include("DFAnimatedImage.h")
#import <FLAnimatedImage.h>
#import "DFAnimatedImage.h"
#endif


@implementation DFURLImageDeserializer

- (id)objectFromResponse:(NSURLResponse *)response data:(NSData *)data error:(NSError *__autoreleasing *)error {
    if (!data.length) {
        return nil;
    }
#if __has_include("DFAnimatedImage.h")
    if ([self _isGIF:data]) {
        UIImage *image = [[DFAnimatedImage alloc] initWithAnimatedGIFData:data];
        if (image) {
            return image;
        }
    }
#endif
    return [[UIImage alloc] initWithData:data scale:[UIScreen mainScreen].scale];
}

/*! Based on http://en.wikipedia.org/wiki/Magic_number_(programming)
 */
- (BOOL)_isGIF:(NSData *)data {
    uint8_t c;
    [data getBytes:&c length:1];
    return c == 0x47;
}

@end
