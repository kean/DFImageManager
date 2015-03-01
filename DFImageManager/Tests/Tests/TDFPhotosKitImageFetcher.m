//
//  TDFPhotosKitImageFetcher.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <XCTest/XCTest.h>

/*! Test suite for DFURLImageFetcher class.
 */
@interface TDFPhotosKitImageFetcher : XCTestCase

@end

@implementation TDFPhotosKitImageFetcher {
    DFPhotosKitImageFetcher *_fetcher;
}

- (void)setUp {
    [super setUp];
    
    _fetcher = [DFPhotosKitImageFetcher new];
}

- (void)tearDown {
    [super tearDown];
}

#pragma mark - Test Canonical Requests

- (void)testThatCanonicalRequestCreatesSpecificSubclassWithDefaultOptions {
    DFImageRequestOptions *options = [DFImageRequestOptions new];
    options.allowsNetworkAccess = NO;
    
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:[NSURL df_assetURLWithAssetLocalIdentifier:@"frugh438t35235325"] targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:options];
    
    DFImageRequest *canonicalRequest = [_fetcher canonicalRequestForRequest:[request copy]];
    
    [self _validateCanonicalOptions:(id)canonicalRequest.options];
    
    XCTAssertTrue(canonicalRequest.options.allowsNetworkAccess == NO);
}

- (void)testThatCanonicalRequestCreatesOptionsWhenOptionsAreNil {
    DFImageRequest *request = [[DFImageRequest alloc] initWithResource:[NSURL df_assetURLWithAssetLocalIdentifier:@"frugh438t35235325"] targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil];
    
    DFImageRequest *canonicalRequest = [_fetcher canonicalRequestForRequest:[request copy]];
    
    [self _validateCanonicalOptions:(id)canonicalRequest.options];
}

- (void)_validateCanonicalOptions:(DFPhotosKitImageRequestOptions *)options {
    XCTAssertTrue([options isKindOfClass:[DFPhotosKitImageRequestOptions class]]);
    
    XCTAssertTrue(options.version == PHImageRequestOptionsVersionCurrent);
    XCTAssertTrue(options.deliveryMode == PHImageRequestOptionsDeliveryModeHighQualityFormat);
    XCTAssertTrue(options.resizeMode == PHImageRequestOptionsResizeModeFast);
}

@end
