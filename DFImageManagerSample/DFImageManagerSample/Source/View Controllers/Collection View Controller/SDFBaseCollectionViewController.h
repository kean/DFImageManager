//
//  SDFBaseCollectionViewController.h
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/7/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SDFBaseCollectionViewController : UICollectionViewController

@property (nonatomic) NSInteger numberOfItemsPerRow;

- (instancetype)init;

@end
