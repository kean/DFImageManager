//
//  SDFCompositeSampleCollectionViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFNetworkSampleCollectionViewController.h"
#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotosModel.h"
#import <DFProxyImageManager.h>
#import <DFImageManager/DFImageManagerKit.h>
#import <DFCache/DFCache.h>


@interface SDFNetworkSampleCollectionViewController () <SDFFlickrRecentPhotosModelDelegate>

@end

@implementation SDFNetworkSampleCollectionViewController {
    UIActivityIndicatorView *_activityIndicatorView;
    NSMutableArray *_photos;
    SDFFlickrRecentPhotosModel *_model;
    
    DFCache *_cache;
}

static NSString * const reuseIdentifier = @"Cell";

- (void)dealloc {
    [_cache removeAllObjects];
    [DFImageManager setSharedManager:nil];
}

- (instancetype)init {
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithCollectionViewLayout:layout]) {
        _numberOfItemsPerRow = 4;
        _shouldUseCompositeImageRequests = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    _activityIndicatorView.translatesAutoresizingMaskIntoConstraints = NO;
    [_activityIndicatorView startAnimating];
    [self.view addSubview:_activityIndicatorView];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicatorView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:_activityIndicatorView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
    
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
    
    DFCompositeImageManager *compositeImageManager = [[DFCompositeImageManager alloc] initWithImageManagers:@[networkImageManager]];
    DFProxyImageManager *proxyImageManager = [[DFProxyImageManager alloc] initWithImageManager:compositeImageManager];
    [proxyImageManager setValueTransformerWithBlock:^id(id asset) {
      //  NSLog(@"starting/cancelling asset request = %@", asset);
        return asset;
    }];
    
    [DFImageManager setSharedManager:proxyImageManager];
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
    if (self.shouldUseCompositeImageRequests ){
        // We specifically resize placeholder to make it even smaller
        DFImageRequest *requestWithSmallURL = [[DFImageRequest alloc] initWithAsset:photo.photoURLSmall targetSize:DFImageManagerMaximumSize contentMode:DFImageContentModeAspectFit options:nil];

        DFImageRequest *requestWithBigURL = [[DFImageRequest alloc] initWithAsset:photo.photoURLBig targetSize:imageView.targetSize contentMode:imageView.contentMode options:nil];
        
        [imageView setImagesWithRequests:@[ requestWithSmallURL, requestWithBigURL] ];
    } else {
        [imageView setImageWithAsset:photo.photoURL];
    }
    
    return cell;
}

#pragma mark - <SDFFlickrRecentPhotosModelDelegate>

- (void)flickrRecentPhotosModel:(SDFFlickrRecentPhotosModel *)model didLoadPhotos:(NSArray *)photos forPage:(NSInteger)page {
    [_activityIndicatorView removeFromSuperview];
    [_photos addObjectsFromArray:photos];
    [self.collectionView reloadData];
}

@end
