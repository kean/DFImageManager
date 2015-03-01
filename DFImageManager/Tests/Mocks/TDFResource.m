//
//  TDFResource.m
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "TDFResource.h"

@implementation TDFResource

- (instancetype)initWithID:(NSString *)ID {
    if (self = [super init]) {
        _ID = ID;
    }
    return self;
}

+ (instancetype)resourceWithID:(NSString *)ID {
    return [[[self class] alloc] initWithID:ID];
}

- (NSUInteger)hash {
    return _ID.hash;
}

- (BOOL)isEqual:(id)other {
    if (other == self) {
        return YES;
    }
    if (!other || ![other isKindOfClass:[self class]]) {
        return NO;
    }
    return [self.ID isEqualToString:((TDFResource *)other).ID];
}
            
@end
