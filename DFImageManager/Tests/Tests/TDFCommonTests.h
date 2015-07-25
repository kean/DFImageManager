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
