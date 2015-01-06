//
//  SDFMainDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/5/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotosModel.h"
#import "SDFMainDemoViewController.h"
#import "UIViewController+SDFImageManager.h"
#import <DFImageManager/DFImageManagerKit.h>


@interface SDFMainDemoViewController () <SDFFlickrRecentPhotosModelDelegate>

@end


static NSString * const reuseIdentifier = @"Cell";

@implementation SDFMainDemoViewController {
    UIActivityIndicatorView *_activityIndicatorView;
    NSMutableArray *_photos;
    SDFFlickrRecentPhotosModel *_model;
}

- (instancetype)init {
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _activityIndicatorView = [self showActivityIndicatorView];
    
    _photos = [NSMutableArray new];
    
    _model = [SDFFlickrRecentPhotosModel new];
    _model.delegate = self;
    [_model poll];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.minimumLineSpacing = 2.f;
    layout.minimumInteritemSpacing = 2.f;
    CGFloat side = (self.collectionView.bounds.size.width - 3 * 2.0) / 4;
    layout.itemSize = CGSizeMake(side, side);
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    DFImageView *imageView = (id)[cell viewWithTag:15];
    if (!imageView) {
        imageView = [[DFImageView alloc] initWithFrame:cell.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.tag = 15;
        [cell addSubview:imageView];
    }
        
    SDFFlickrPhoto *photo = _photos[indexPath.row];
    [imageView setImageWithAsset:photo.photoURL];
    
    return cell;
}

#pragma mark - <SDFFlickrRecentPhotosModelDelegate>

- (void)flickrRecentPhotosModel:(SDFFlickrRecentPhotosModel *)model didLoadPhotos:(NSArray *)photos forPage:(NSInteger)page {
    [_activityIndicatorView removeFromSuperview];
    [_photos addObjectsFromArray:photos];
    [self.collectionView reloadData];
}

@end
