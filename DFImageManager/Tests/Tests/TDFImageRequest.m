//
//  TDFImageRequest.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/6/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFTestingKit.h"
#import "DFImageManagerKit.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface TDFImageRequest : XCTestCase

@end

@implementation TDFImageRequest

- (void)testThatDefaultsAreSet {
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:@"Resourse"];
    XCTAssertTrue(CGSizeEqualToSize(request.targetSize, DFImageMaximumSize));
    XCTAssertTrue(request.contentMode == DFImageContentModeAspectFill);
    TDFAssertDefaultOptionsAreValid(request.options);
}

- (void)testThatRequestIsCopied {
    TDFMockResource *resource = [TDFMockResource resourceWithID:@"ID"];
    CGSize targetSize = CGSizeMake(20.f, 20.f);
    DFImageContentMode contentMode = DFImageContentModeAspectFit;
    DFImageRequestOptions *options = [DFImageRequestOptions new];
    options.allowsNetworkAccess = NO;
    
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:resource targetSize:targetSize contentMode:contentMode options:options];
    XCTAssertTrue(request.resource == resource);
    XCTAssertTrue(request.contentMode == contentMode);
    XCTAssertTrue(request.options == options);
    
    DFImageRequest *copy = [request copy];
    XCTAssertTrue(copy != request);
    XCTAssertTrue(copy.resource == resource);
    XCTAssertEqual(copy.contentMode, contentMode);
    // Test that options are copied
    XCTAssertTrue(copy.options != options);
    XCTAssertEqual(copy.options.allowsNetworkAccess, NO);
}

@end
