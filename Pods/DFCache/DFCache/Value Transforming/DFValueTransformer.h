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

#import <Foundation/Foundation.h>


extern NSString *const DFValueTransformerNSCodingName;
extern NSString *const DFValueTransformerJSONName;

#if (__IPHONE_OS_VERSION_MIN_REQUIRED)
extern NSString *const DFValueTransformerUIImageName;
#endif


@protocol DFValueTransforming <NSObject>

- (NSData *)transformedValue:(id)value;
- (id)reverseTransfomedValue:(NSData *)data;

@optional
/*! The cost that is associated with the value in the memory cache. Typically, the obvious cost is the size of the object in bytes.
 */
- (NSUInteger)costForValue:(id)value;

@end


@interface DFValueTransformer : NSObject <DFValueTransforming>

@end


@interface DFValueTransformerNSCoding : DFValueTransformer

@end


@interface DFValueTransformerJSON : DFValueTransformer

@end


#if (__IPHONE_OS_VERSION_MIN_REQUIRED)

@interface DFValueTransformerUIImage : DFValueTransformer

/*! The quality of the resulting JPEG image, expressed as a value from 0.0 to 1.0. The value 0.0 represents the maximum compression (or lowest quality) while the value 1.0 represents the least compression (or best quality).
 @discussion Applies only or images that don't have an alpha channel and cab be encoded in JPEG format.
 */
@property (nonatomic) CGFloat compressionQuality;

@property (nonatomic) BOOL allowsImageDecompression;

@end

#endif
