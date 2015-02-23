//
//  SDFAssetsLibraryDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/7/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFAssetsLibraryDemoViewController.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <DFImageManager/DFImageManagerKit.h>
#import "UIViewController+SDFImageManager.h"


static NSString * const reuseIdentifier = @"Cell";

@implementation SDFAssetsLibraryDemoViewController {
    NSArray /* DFALAsset */ *_photos;
    UIActivityIndicatorView *_activity;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    ALAuthorizationStatus authorizationStatus = [ALAssetsLibrary authorizationStatus];
    switch (authorizationStatus) {
        case ALAuthorizationStatusAuthorized:
            [self _loadAssets];
            break;
        case ALAuthorizationStatusDenied:
        case ALAuthorizationStatusRestricted:
            [self _showErrorMessageForDeniedPhotoLibraryAccess];
            break;
        case ALAuthorizationStatusNotDetermined: {
            [self _loadAssets];
        }
            break;
        default:
            break;
    }
}

- (void)_loadAssets {
    _activity = [self df_showActivityIndicatorView];
    
    SDFAssetsLibraryDemoViewController *__weak weakSelf = self;
    NSMutableArray *assets = [NSMutableArray new];
    [[ALAssetsLibrary df_sharedLibrary] enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            NSString *assetType = [result valueForProperty:ALAssetPropertyType];
            if ([assetType isEqual:ALAssetTypePhoto]) {
                DFALAsset *wrapper = [[DFALAsset alloc] initWithAsset:result];
                if (wrapper) {
                    [assets addObject:wrapper];
                }
            }
        }];
        if (group == nil) { // Enumeration is done
            [self _didLoadAssets:assets];
        }
    } failureBlock:^(NSError *error) {
        [weakSelf _didFailWithError:error];
    }];
}

- (void)_didLoadAssets:(NSArray *)assets {
    [_activity removeFromSuperview];
    _photos = assets;
    [self.collectionView reloadData];
}

- (void)_didFailWithError:(NSError *)error {
    [_activity removeFromSuperview];
    if (error.code == ALAssetsLibraryAccessUserDeniedError) {
        [self _showErrorMessageForDeniedPhotoLibraryAccess];
    }
}

- (void)_showErrorMessageForDeniedPhotoLibraryAccess {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Photo library access denied." message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
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
    cell.backgroundColor = [UIColor colorWithWhite:235.f/255.f alpha:1.f];
    
    DFImageView *imageView = (id)[cell viewWithTag:15];
    if (!imageView) {
        imageView = [[DFImageView alloc] initWithFrame:cell.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.tag = 15;
        [cell addSubview:imageView];
    }
    
    DFALAsset *asset = _photos[indexPath.row];
    [imageView prepareForReuse];
    [imageView setImageWithResource:asset];

    return cell;
}

@end