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
    DFImageRequest *request = [DFImageRequest requestWithResource:@"Resourse"];
    XCTAssertTrue(CGSizeEqualToSize(request.targetSize, DFImageMaximumSize));
    XCTAssertTrue(request.contentMode == DFImageContentModeAspectFill);
    TDFAssertDefaultOptionsAreValid(request.options);
}

@end
