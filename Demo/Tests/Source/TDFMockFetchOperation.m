//
//  TDFMockFetchOperation.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 3/1/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFMockFetchOperation.h"

static inline NSOperationQueuePriority _DFQueuePriorityForRequestPriority(DFImageRequestPriority priority) {
    switch (priority) {
        case DFImageRequestPriorityHigh: return NSOperationQueuePriorityHigh;
        case DFImageRequestPriorityNormal: return NSOperationQueuePriorityNormal;
        case DFImageRequestPriorityLow: return NSOperationQueuePriorityLow;
    }
}

@implementation TDFMockFetchOperation

- (void)cancel {
    [[NSNotificationCenter defaultCenter] postNotificationName:TDFMockFetchOperationWillCancelNotification object:self];
    [super cancel];
}

- (void)cancelImageFetching {
    [self cancel];
}

- (void)setImageFetchingPriority:(DFImageRequestPriority)priority {
    self.queuePriority = _DFQueuePriorityForRequestPriority(priority);
}

@end
