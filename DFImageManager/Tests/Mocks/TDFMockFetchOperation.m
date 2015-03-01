//
//  TDFMockFetchOperation.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/1/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockFetchOperation.h"

@implementation TDFMockFetchOperation

- (void)cancel {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDFMockFetchOperationDidCancelNotification object:self];
    [super cancel];
}

@end
