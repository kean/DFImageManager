//
//  TDFMockFetchOperation.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/1/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <Foundation/Foundation.h>

@class DFImageRequest;

static NSString *const TDFMockFetchOperationWillCancelNotification = @"TDFMockFetchOperationWillCancelNotification";

@interface TDFMockFetchOperation : NSBlockOperation

@property (nonatomic) DFImageRequest *request;

@end
