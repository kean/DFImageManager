//
//  SDFBaseCollectionViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/7/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFBaseCollectionViewController.h"

@implementation SDFBaseCollectionViewController

- (instancetype)init {
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithCollectionViewLayout:layout]) {
        _numberOfItemsPerRow = 4;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.alwaysBounceVertical = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = [UIColor whiteColor];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
 
    [self _updateItemSize];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self _updateItemSize];
}

- (void)_updateItemSize {
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.minimumLineSpacing = 2.f;
    layout.minimumInteritemSpacing = 2.f;
    CGFloat side = (self.collectionView.bounds.size.width - (self.numberOfItemsPerRow - 1) * 2.0) / self.numberOfItemsPerRow;
    layout.itemSize = CGSizeMake(side, side);
}

@end
