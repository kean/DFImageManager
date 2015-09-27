//
//  SDFPhotosKitSampleViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/23/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFMomentHeaderCollectionReusableView.h"
#import "SDFStickyHeaderCollectionViewFlowLayout.h"
#import "SDFPhotosKitDemoViewController.h"
#import "UIViewController+SDFImageManager.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+UI.h>
#import <DFImageManager/DFImageManagerKit+PhotosKit.h>
#import <Photos/Photos.h>


static inline NSString *_DFLocalizedPeriodString(NSDate *startDate, NSDate *endDate) {
    static NSDateFormatter *_formatter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _formatter = [NSDateFormatter new];
        _formatter.dateStyle = NSDateFormatterLongStyle;
        _formatter.timeStyle = NSDateFormatterNoStyle;
    });
    NSMutableArray *parts = [NSMutableArray new];
    if (startDate != nil) {
        [parts addObject:[_formatter stringFromDate:startDate]];
    }
    if (endDate != nil) {
        [parts addObject:[_formatter stringFromDate:endDate]];
    }
    return [parts componentsJoinedByString:@" - "];
}


static NSString * const reuseIdentifier = @"Cell";


@interface SDFPhotosKitDemoViewController () <DFCollectionViewPreheatingControllerDelegate>

@end

@implementation SDFPhotosKitDemoViewController {
    PHFetchResult *_moments;
    NSArray * /* PHFetchResult */ _assets;
    UIActivityIndicatorView *_indicator;
    DFCollectionViewPreheatingController *_preheatingController;
}

- (instancetype)init {
    return [self initWithCollectionViewLayout:[SDFStickyHeaderCollectionViewFlowLayout new]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    [self.collectionView registerNib:[UINib nibWithNibName:NSStringFromClass([SDFMomentHeaderCollectionReusableView class]) bundle:nil] forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([SDFMomentHeaderCollectionReusableView class])];
    self.collectionView.alwaysBounceVertical = YES;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleBlack];
    
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
            SDFPhotosKitDemoViewController *__weak weakSelf = self;
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

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    _preheatingController = [[DFCollectionViewPreheatingController alloc] initWithCollectionView:self.collectionView];
    _preheatingController.delegate = self;
    [_preheatingController updatePreheatRect];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    // Resets preheat rect and stop preheating images via delegate call.
    [_preheatingController resetPreheatRect];
    _preheatingController = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.minimumLineSpacing = 2.f;
    layout.minimumInteritemSpacing = 2.f;
    CGFloat side = (self.collectionView.bounds.size.width - 2.f) / 2.f;
    layout.itemSize = CGSizeMake(side, side);
    
    layout.sectionInset = UIEdgeInsetsMake(0.f, 0.f, 14.f, 0.f);
}

- (void)_loadAssets {
    _indicator = [self df_showActivityIndicatorView];
    _indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        PHFetchResult *moments = [PHAssetCollection fetchMomentsWithOptions:nil];
        NSMutableArray *assets = [NSMutableArray new];
        for (PHAssetCollection *moment in moments) {
            PHFetchOptions *options = [PHFetchOptions new];
            options.predicate = [NSPredicate predicateWithFormat:@"mediaType == %d", PHAssetMediaTypeImage];
            PHFetchResult *assetsFetchResults = [PHAsset fetchAssetsInAssetCollection:moment options:options];
            if (assetsFetchResults) {
                [assets addObject:assetsFetchResults];
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            _moments = moments;
            _assets = [assets copy];
            
            [_indicator removeFromSuperview];
            [self.collectionView reloadData];
            
            NSInteger section = [self numberOfSectionsInCollectionView:self.collectionView] - 1;
            NSInteger item = [self collectionView:self.collectionView numberOfItemsInSection:section] - 1;
            NSIndexPath *lastIndexPath = [NSIndexPath indexPathForItem:item inSection:section];
            [self.collectionView scrollToItemAtIndexPath:lastIndexPath atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
            
            [_preheatingController updatePreheatRect];
        });
    });
}

- (void)_showErrorMessageForDeniedPhotoLibraryAccess {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Photo library access denied." message:nil delegate:nil cancelButtonTitle:@"Ok" otherButtonTitles:nil];
    [alert show];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return _assets.count;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    PHFetchResult *result = _assets[section];
    return [result count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:0.1f alpha:1.f];
    
    DFImageView *imageView = (id)[cell viewWithTag:15];
    if (!imageView) {
        imageView = [[DFImageView alloc] initWithFrame:cell.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.tag = 15;
        [cell addSubview:imageView];
    }
    
    PHFetchResult *result = _assets[indexPath.section];
    PHAsset *asset = result[indexPath.item];
    
    [imageView prepareForReuse];
    [imageView setImageWithResource:asset targetSize:[self _imageTargetSize] contentMode:DFImageContentModeAspectFill options:nil];

    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    DFImageView *imageView = (id)[cell viewWithTag:15];
    [imageView prepareForReuse];
}

- (CGSize)_imageTargetSize {
    CGSize size = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake(size.width * scale, size.height * scale);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout referenceSizeForHeaderInSection:(NSInteger)section {
    return CGSizeMake(self.collectionView.bounds.size.width, 44.f);
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath {
    SDFMomentHeaderCollectionReusableView *header = [collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:NSStringFromClass([SDFMomentHeaderCollectionReusableView class]) forIndexPath:indexPath];
    
    PHAssetCollection *moment = _moments[indexPath.section];
    
    NSArray *locationNames = [moment localizedLocationNames];
    NSString *localizedTitle = [moment localizedTitle];
    
    NSString *locationName1;
    NSString *locationName2;
    if (localizedTitle) {
        locationName1 = localizedTitle;
        locationName2 = [locationNames firstObject];
    } else {
        locationName1 = [locationNames firstObject];
        locationName2 = locationNames.count > 1 ? locationNames[1] : nil;
    }
    
    NSString *dateString = _DFLocalizedPeriodString(nil, [moment endDate]);
    
    if (locationName1.length) {
        header.labelTopLeft.text = locationName1 ?: @"";
        header.labelBottomLeft.text = locationName2 ?: @"";
        header.labelTopLeftConstraintCenterVertically.active = locationName2.length == 0;
        header.labelTopLeftConstraintTopSpacing.active = locationName2.length > 0;
        
        header.labelBottomRight.text = dateString;
    } else {
        header.labelTopLeft.text = dateString;
        header.labelTopLeftConstraintCenterVertically.active = YES;
        header.labelTopLeftConstraintTopSpacing.active = NO;
    }
    
    return header;
}

#pragma mark - <DFCollectionViewPreheatingControllerDelegate>

- (void)collectionViewPreheatingController:(DFCollectionViewPreheatingController *)controller didUpdatePreheatRectWithAddedIndexPaths:(NSArray *)addedIndexPaths removedIndexPaths:(NSArray *)removedIndexPaths {
    [[DFImageManager sharedManager] startPreheatingImagesForRequests:[self _imageRequestsAtIndexPaths:addedIndexPaths]];
    [[DFImageManager sharedManager] stopPreheatingImagesForRequests:[self _imageRequestsAtIndexPaths:removedIndexPaths]];
}

- (NSArray *)_imageRequestsAtIndexPaths:(NSArray *)indexPaths {
    CGSize targetSize = [self _imageTargetSize];
    NSMutableArray *requests = [NSMutableArray new];
    for (NSIndexPath *indexPath in indexPaths) {
        PHFetchResult *result = _assets[indexPath.section];
        PHAsset *asset = result[indexPath.row];
        [requests addObject:[DFImageRequest requestWithResource:asset targetSize:targetSize contentMode:DFImageContentModeAspectFill options:nil]];
    }
    return requests;
}

@end
