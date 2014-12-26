//
//  SDFPhotosKitSampleViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/23/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFPhotosKitSampleViewController.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <Photos/Photos.h>

static NSString * const reuseIdentifier = @"Cell";

@implementation SDFPhotosKitSampleViewController {
    PHFetchResult *_moments;
    NSArray * /* PHFetchResult */ _assets;
}

- (instancetype)init {
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (void)dealloc {
    [DFImageManager setSharedManager:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    [self _configureImageManager];
    
    PHAuthorizationStatus authorizationStatus = [PHPhotoLibrary authorizationStatus];
    switch (authorizationStatus) {
        case PHAuthorizationStatusAuthorized:
            [self _loadAssets];
            break;
        case PHAuthorizationStatusDenied:
        case PHAuthorizationStatusRestricted:
            [self _showErrorMessageForDeniedPhotoLibraryAccess];
            break;
        case PHAuthorizationStatusNotDetermined: {
            SDFPhotosKitSampleViewController *__weak weakSelf = self;
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                if (status == PHAuthorizationStatusAuthorized) {
                    [weakSelf _loadAssets];
                } else {
                    [weakSelf _showErrorMessageForDeniedPhotoLibraryAccess];
                }
            }];
        }
            break;
        default:
            break;
    }
}

- (void)_configureImageManager {
    DFPHImageManagerConfiguration *configuration = [DFPHImageManagerConfiguration new];
    DFImageManager *imageManager = [[DFImageManager alloc] initWithConfiguration:configuration imageProcessingManager:nil];
    
    DFCompositeImageManager *compositeImageManager = [[DFCompositeImageManager alloc] initWithImageManagers:@[imageManager]];
    
    [DFImageManager setSharedManager:compositeImageManager];
}

- (void)_loadAssets {
    PHFetchResult *moments = [PHAssetCollection fetchMomentsWithOptions:nil];
    NSMutableArray *assets = [NSMutableArray new];
    for (PHAssetCollection *moment in moments) {
        PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:moment options:nil];
        if (assetsFetchResults) {
            [assets addObject:assetsFetchResults];
        }
    }
    _moments = moments;
    _assets = [assets copy];
    
    [self.collectionView reloadData];
}

- (void)_showErrorMessageForDeniedPhotoLibraryAccess {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Photo library access denied." message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.minimumLineSpacing = 2.f;
    layout.minimumInteritemSpacing = 2.f;
    CGFloat side = (self.collectionView.bounds.size.width - 3.0 * 2.0) / 4.0;
    layout.itemSize = CGSizeMake(side, side);
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _moments.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PHFetchResult *result = _assets[section];
    return [result count];
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
    
    PHFetchResult *result = _assets[indexPath.section];
    PHAsset *asset = [result objectAtIndex:indexPath.item];
    [imageView setImageWithAsset:asset];
    
    return cell;
}

@end
