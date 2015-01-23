//
//  TDFURLImageFetcher.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 1/22/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import "TDFTesting.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>


@interface TDFURLImageFetcher : XCTestCase

@end

@implementation TDFURLImageFetcher

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testThatURLImageFetcherSupportsDataScheme {
    NSData *imgData = [TDFTesting testImageData];
    NSString *dataFormatString = @"data:image/png;base64,%@";
    NSString *dataString = [NSString stringWithFormat:dataFormatString, [imgData base64EncodedStringWithOptions:0]];
    NSURL *dataURL = [NSURL URLWithString:dataString];
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"image_fetched"];
    
    [[DFImageManager sharedManager] requestImageForResource:dataURL completion:^(UIImage *image, NSDictionary *info) {
        XCTAssertNotNil(image);
        [expectation fulfill];
    }];
    
    [self waitForExpectationsWithTimeout:3.0 handler:nil];
}


@end
