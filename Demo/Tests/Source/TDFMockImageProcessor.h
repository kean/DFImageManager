//
//  TDFImageProcessor.h
//  DFImageManager
//
//  Created by Alexander Grebenyuk on 2/28/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "DFImageManagerKit.h"
#import <Foundation/Foundation.h>

@interface UIImage (TDFMockImageProcessor)

- (BOOL)tdf_isImageProcessed;

@end

/*! The mock implementation of DFImageProcessing protocol.
 */
@interface TDFMockImageProcessor : NSObject <DFImageProcessing>

@property (nonatomic) NSTimeInterval processingTime;

@end
