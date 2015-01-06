//
//  SDFCompositeSampleCollectionViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotosModel.h"
#import "SDFNetworkSampleCollectionViewController.h"
#import "UIViewController+SDFImageManager.h"
#import <DFCache/DFCache.h>
#import <DFImageManager/DFImageManagerKit.h>
#import <DFProxyImageManager.h>


@interface SDFNetworkSampleCollectionViewController ()

<DFCollectionViewPreheatingControllerDelegate,
SDFFlickrRecentPhotosModelDelegate>

@end

@implementation SDFNetworkSampleCollectionViewController {
    UIActivityIndicatorView *_activityIndicatorView;
    NSMutableArray *_photos;
    SDFFlickrRecentPhotosModel *_model;
    
    DFCollectionViewPreheatingController *_preheatingController;
    DFCache *_cache;
}

static NSString * const reuseIdentifier = @"Cell";

- (void)dealloc {
    [_cache removeAllObjects];
    [DFImageManager setSharedManager:[DFImageManager defaultManager]];
}

- (instancetype)init {
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithCollectionViewLayout:layout]) {
        _numberOfItemsPerRow = 4;
        _allowsCompositeImageRequests = NO;
        _allowsPreheating = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _activityIndicatorView = [self showActivityIndicatorView];
    
    [self _configureImageManager];
    
    _photos = [NSMutableArray new];
    
    _model = [SDFFlickrRecentPhotosModel new];
    _model.delegate = self;
    [_model poll];
}

- (void)_configureImageManager {
    DFImageProcessingManager *imageProcessor = [DFImageProcessingManager new];
    
    // We don't want memory cache, because we use caching image processing manager.
    DFCache *cache = [[DFCache alloc] initWithName:[[NSUUID UUID] UUIDString] memoryCache:nil];
    [cache setAllowsImageDecompression:NO];
    _cache = cache;
    
    DFNetworkImageManagerConfiguration *networkImageManagerConfiguration = [[DFNetworkImageManagerConfiguration alloc] initWithCache:cache];
    DFImageManager *networkImageManager = [[DFImageManager alloc] initWithConfiguration:networkImageManagerConfiguration imageProcessor:imageProcessor cache:imageProcessor];
    
    [DFImageManager setSharedManager:networkImageManager];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if (self.allowsPreheating) {
        _preheatingController = [[DFCollectionViewPreheatingController alloc] initWithCollectionView:self.collectionView];
        _preheatingController.delegate = self;
        [_preheatingController updatePreheatRect];
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_preheatingController resetPreheatRect];
    _preheatingController = nil;
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.minimumLineSpacing = 2.f;
    layout.minimumInteritemSpacing = 2.f;
    CGFloat side = (self.collectionView.bounds.size.width - (self.numberOfItemsPerRow - 1) * 2.0) / self.numberOfItemsPerRow;
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
    if (self.allowsCompositeImageRequests ){
        DFImageRequest *requestWithSmallURL = [[DFImageRequest alloc] initWithAsset:photo.photoURLSmall targetSize:DFImageManagerMaximumSize contentMode:DFImageContentModeAspectFit options:nil];
        
        CGSize targetSize = [self _imageTargetSize];
        DFImageRequest *requestWithBigURL = [[DFImageRequest alloc] initWithAsset:photo.photoURLBig targetSize:targetSize contentMode:DFImageContentModeAspectFill options:nil];
        
        [imageView setImagesWithRequests:@[ requestWithSmallURL, requestWithBigURL] ];
    } else {
        [imageView setImageWithAsset:photo.photoURL];
    }
    
    return cell;
}

- (CGSize)_imageTargetSize {
    CGSize size = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake(size.width * scale, size.height * scale);
}

#pragma mark - <DFCollectionViewPreheatingControllerDelegate>

- (void)collectionViewPreheatingController:(DFCollectionViewPreheatingController *)controller didUpdatePreheatRectWithAddedIndexPaths:(NSArray *)addedIndexPaths removedIndexPaths:(NSArray *)removedIndexPaths {
    CGSize targetSize = [self _imageTargetSize];
    
    NSArray *addedAssets = [self _imageAssetsAtIndexPaths:addedIndexPaths];
    
    [[DFImageManager sharedManager] startPreheatingImageForAssets:addedAssets targetSize:targetSize contentMode:DFImageContentModeAspectFill options:nil];
    NSArray *removedAssets = [self _imageAssetsAtIndexPaths:removedIndexPaths];
    [[DFImageManager sharedManager] stopPreheatingImagesForAssets:removedAssets targetSize:targetSize contentMode:DFImageContentModeAspectFill options:nil];
}

- (NSArray *)_imageAssetsAtIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *assets = [NSMutableArray new];
    for (NSIndexPath *indexPath in indexPaths) {
        SDFFlickrPhoto *photo = _photos[indexPath.row];
        [assets addObject:photo.photoURL];
    }
    return assets;
}

#pragma mark - <SDFFlickrRecentPhotosModelDelegate>

- (void)flickrRecentPhotosModel:(SDFFlickrRecentPhotosModel *)model didLoadPhotos:(NSArray *)photos forPage:(NSInteger)page {
    [_activityIndicatorView removeFromSuperview];
    [_photos addObjectsFromArray:photos];
    [self.collectionView reloadData];
    if (page == 0) {
        [_preheatingController updatePreheatRect];
    }
}

@end
