//
//  DFValueTransformer.h
//  DFCache
//
//  Created by Alexander Grebenyuk on 12/17/14.
//  Copyright (c) 2014 com.github.kean. All rights reserved.
//

#import <Foundation/Foundation.h>


@protocol DFValueTransforming <NSObject, NSCoding>

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

@end

#endif
