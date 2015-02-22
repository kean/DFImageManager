//
//  SDFCompositeRequestDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/5/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFCompositeRequestDemoViewController.h"
#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotosModel.h"
#import "UIViewController+SDFImageManager.h"
#import <DFImageManager/DFImageManagerKit.h>


static NSString * const reuseIdentifier = @"Cell";

@interface SDFCompositeRequestDemoViewController ()

<SDFFlickrRecentPhotosModelDelegate>

@end

@implementation SDFCompositeRequestDemoViewController {
    UIActivityIndicatorView *_activityIndicatorView;
    NSMutableArray *_photos;
    SDFFlickrRecentPhotosModel *_model;
}

- (NSInteger)numberOfItemsPerRow {
    return 1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _activityIndicatorView = [self df_showActivityIndicatorView];
    
    _photos = [NSMutableArray new];
    
    _model = [SDFFlickrRecentPhotosModel new];
    _model.delegate = self;
    [_model poll];
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
    
    SDFFlickrPhoto *photo = _photos[indexPath.row];
    
    DFImageRequest *requestWithSmallURL = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:photo.photoURLSmall] targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil];
    
    DFImageRequest *requestWithBigURL = [[DFImageRequest alloc] initWithResource:[NSURL URLWithString:photo.photoURLBig] targetSize:imageView.imageTargetSize contentMode:DFImageContentModeAspectFill options:nil];
    
    [imageView prepareForReuse];
    [imageView setImageWithRequests:@[ requestWithSmallURL, requestWithBigURL ] ];
    
    return cell;
}

- (CGSize)_imageTargetSize {
    CGSize size = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake(size.width * scale, size.height * scale);
}

#pragma mark - <SDFFlickrRecentPhotosModelDelegate>

- (void)flickrRecentPhotosModel:(SDFFlickrRecentPhotosModel *)model didLoadPhotos:(NSArray *)photos forPage:(NSInteger)page {
    [_activityIndicatorView removeFromSuperview];
    [_photos addObjectsFromArray:photos];
    [self.collectionView reloadData];
}

@end
