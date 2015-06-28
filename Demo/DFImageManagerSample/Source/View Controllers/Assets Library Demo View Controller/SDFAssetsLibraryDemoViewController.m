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

@interface SDFAssetsLibraryDemoViewController () <DFCollectionViewPreheatingControllerDelegate>

@end

@implementation SDFAssetsLibraryDemoViewController {
    NSArray /* NSURL */ *_photos;
    UIActivityIndicatorView *_activity;
    DFCollectionViewPreheatingController *_preheatingController;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _preheatingController = [[DFCollectionViewPreheatingController alloc] initWithCollectionView:self.collectionView];
    _preheatingController.delegate = self;
    [_preheatingController updatePreheatRect];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Resets preheat rect and stop preheating images via delegate call.
    [_preheatingController resetPreheatRect];
    _preheatingController = nil;
}

- (void)_loadAssets {
    _activity = [self df_showActivityIndicatorView];
    
    SDFAssetsLibraryDemoViewController *__weak weakSelf = self;
    NSMutableArray *assets = [NSMutableArray new];
    [[DFAssetsLibraryImageFetcher defaulLibrary] enumerateGroupsWithTypes:ALAssetsGroupSavedPhotos usingBlock:^(ALAssetsGroup *group, BOOL *stop) {
        [group enumerateAssetsUsingBlock:^(ALAsset *result, NSUInteger index, BOOL *stop) {
            NSString *assetType = [result valueForProperty:ALAssetPropertyType];
            if ([assetType isEqual:ALAssetTypePhoto]) {
                /*! 
                 The example of DFALAsset usage
                DFALAsset *wrapper = [[DFALAsset alloc] initWithAsset:result];
                // For more info about DLALAsset and warmup methods see DFAssetsLibraryImageFetcher docs.
                [wrapper warmup];
                if (wrapper) {
                    [assets addObject:wrapper];
                }
                 */
                
                NSURL *assetURL = [result valueForProperty:ALAssetPropertyAssetURL];
                if (assetURL) {
                    [assets addObject:assetURL];
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
    
    NSURL *assetURL = _photos[indexPath.row];
    [imageView prepareForReuse];
    [imageView setImageWithResource:assetURL];

    return cell;
}

#pragma mark - <DFCollectionViewPreheatingControllerDelegate>

- (void)collectionViewPreheatingController:(DFCollectionViewPreheatingController *)controller didUpdatePreheatRectWithAddedIndexPaths:(NSArray *)addedIndexPaths removedIndexPaths:(NSArray *)removedIndexPaths {
    [[DFImageManager sharedManager] startPreheatingImagesForRequests:[self _imageRequestsAtIndexPaths:addedIndexPaths]];
    [[DFImageManager sharedManager] stopPreheatingImagesForRequests:[self _imageRequestsAtIndexPaths:removedIndexPaths]];
}

- (NSArray *)_imageRequestsAtIndexPaths:(NSArray *)indexPaths {
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    CGSize targetSize = ({
        CGFloat scale = [UIScreen mainScreen].scale;
        CGSizeMake(layout.itemSize.width * scale, layout.itemSize.height * scale);
    });
    NSMutableArray *requests = [NSMutableArray new];
    for (NSIndexPath *indexPath in indexPaths) {
        NSURL *assetURL = _photos[indexPath.row];
        [requests addObject:[DFImageRequest requestWithResource:assetURL targetSize:targetSize contentMode:DFImageContentModeAspectFill options:nil]];
    }
    return requests;
}

@end