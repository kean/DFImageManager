//
//  TDFCommonTests.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/6/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

/*! Validates that instance of DFImageRequestOptions class has all default options set propertly.
 */
#define TDFAssertDefaultOptionsAreValid(options) \
({ \
    DFImageRequestOptions *opt = (options); \
    XCTAssertNotNil(opt); \
    XCTAssertEqual(opt.priority, DFImageRequestPriorityNormal); \
    XCTAssertEqual(opt.allowsNetworkAccess, YES); \
    XCTAssertEqual(opt.allowsClipping, NO); \
    XCTAssertEqual(opt.memoryCachePolicy, DFImageRequestCachePolicyDefault); \
    XCTAssertEqual(opt.expirationAge, 600.); \
    XCTAssertNil(opt.userInfo); \
})

__unused static DFImageRequestOptions *
TDFCreateRequestOptionsWithNotDefaultParameters() {
    DFImageRequestOptions *options = [DFImageRequestOptions new];
    options.priority = DFImageRequestPriorityVeryLow;
    options.allowsNetworkAccess = NO;
    options.allowsClipping = YES;
    options.memoryCachePolicy = DFImageRequestCachePolicyReloadIgnoringCache;
    options.expirationAge = 300.0;
    options.userInfo = @{ @"TestKey" : @YES };
    return options;
}

/*! Compares properties from the base DFImageRequestOptions class.
 */
#define TDFAssertBaseOptionsAreEqual(options1, options2) \
({ \
    DFImageRequestOptions *opt1 = (options1); \
    DFImageRequestOptions *opt2 = (options2); \
    XCTAssertEqual(opt1.priority, opt2.priority); \
    XCTAssertEqual(opt1.allowsNetworkAccess, opt2.allowsNetworkAccess); \
    XCTAssertEqual(opt1.allowsClipping, opt2.allowsClipping); \
    XCTAssertEqual(opt1.memoryCachePolicy, opt2.memoryCachePolicy); \
    XCTAssertEqual(opt1.expirationAge, opt2.expirationAge); \
    XCTAssertEqual(opt1.userInfo, opt2.userInfo); \
    XCTAssertTrue((opt1.userInfo == nil && opt2.userInfo == nil) || [opt1.userInfo isEqualToDictionary:opt2.userInfo]); \
})

