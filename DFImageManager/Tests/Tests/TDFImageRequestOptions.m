//
//  TDFImageRequestOptions.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/6/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFTestingKit.h"
#import "DFImageManagerKit.h"
#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>

@interface TDFImageRequestOptions : XCTestCase

@end

@implementation TDFImageRequestOptions

- (void)testThatDefaultOptionsAreCreated {
    DFImageRequestOptions *options = [DFImageRequestOptions new];
    TDFAssertDefaultOptionsAreValid(options);
}

- (void)testThatOptionsAreCopied {
    DFImageRequestOptions *options = TDFCreateRequestOptionsWithNotDefaultParameters();
    DFImageRequestOptions *copy = [options copy];
    XCTAssertTrue(copy != options); // New instance is created
    TDFAssertBaseOptionsAreEqual(options, copy);
}

- (void)testThatOptionsInitWithOptionsMethodsWorks {
    DFImageRequestOptions *options = TDFCreateRequestOptionsWithNotDefaultParameters();
    DFImageRequestOptions *copy = [[DFImageRequestOptions alloc] initWithOptions:options];
    TDFAssertBaseOptionsAreEqual(options, copy);
}

@end
