//
//  TDFWebP.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 19/07/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface TDFImageFormats : XCTestCase

@end

@implementation TDFImageFormats

- (void)testThatWebPIsDecoded {
    NSData *data = [self _webpImageData];
    XCTAssertEqual(data.length, 118042);
    UIImage *image = [UIImage df_imageWithWebPData:data];
    XCTAssertNotNil(image);
    XCTAssertEqual(image.size.width, 768);
    XCTAssertEqual(image.size.height, 768);
}

- (void)testThatDFURLImageDeserializerSupportsWebP {
    DFURLImageDeserializer *deserializer = [DFURLImageDeserializer new];
    NSData *data = [self _webpImageData];
    XCTAssertEqual(data.length, 118042);
    UIImage *image = [deserializer objectFromResponse:nil data:data error:nil];
    XCTAssertNotNil(image);
    XCTAssertEqual(image.size.width, 768);
    XCTAssertEqual(image.size.height, 768);
}

- (void)testThatDFAFImageDeserializerSupportsWebP {
    DFAFImageDeserializer *deserializer = [DFAFImageDeserializer new];
    NSData *data = [self _webpImageData];
    XCTAssertEqual(data.length, 118042);
    UIImage *image = [deserializer responseObjectForResponse:nil data:data error:nil];
    XCTAssertNotNil(image);
    XCTAssertEqual(image.size.width, 768);
    XCTAssertEqual(image.size.height, 768);
}

#pragma mark -

- (NSData *)_webpImageData {
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [bundle pathForResource:@"lhfer5lguvi76a9uedez" ofType:@"webp"];
    return [NSData dataWithContentsOfFile:path];
}

@end
