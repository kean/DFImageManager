//
//  SDFCompositeSampleCollectionViewController.h
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDFNetworkSampleCollectionViewController : UICollectionViewController

@property (nonatomic) BOOL allowsCompositeImageRequests;
@property (nonatomic) BOOL allowsPreheating;
@property (nonatomic) NSInteger numberOfItemsPerRow;

@end
