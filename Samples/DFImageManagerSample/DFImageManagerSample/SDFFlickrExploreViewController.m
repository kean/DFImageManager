//
//  FirstViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 11/11/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFFlickrExploreViewController.h"
#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotosModel.h"
#import <DFImageManagerKit.h>


@interface SDFFlickrExploreViewController ()

<UICollectionViewDataSource,
UICollectionViewDelegate,
UICollectionViewDelegateFlowLayout,
SDFFlickrRecentPhotosDelegate>

@property (nonatomic) IBOutlet UICollectionView *collectionView;

@end

@implementation SDFFlickrExploreViewController {
    SDFFlickrRecentPhotosModel *_model;
    NSMutableArray *_photos;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class])];
    UICollectionViewFlowLayout *layout = (id)self.collectionView.collectionViewLayout;
    layout.sectionInset = UIEdgeInsetsMake(4.f, 4.f, 4.f, 4.f);
    
    _photos = [NSMutableArray new];
    
    _model = [SDFFlickrRecentPhotosModel new];
    _model.delegate = self;
    [_model load];
}

#pragma mark - <SDFFlickrRecentPhotosDelegate>

- (void)flickrRecentPhotosModel:(SDFFlickrRecentPhotosModel *)model didLoadPhotos:(NSArray *)photos forPage:(NSUInteger)page {
    [_photos addObjectsFromArray:photos];
    [_collectionView reloadData];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photos.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass([UICollectionViewCell class]) forIndexPath:indexPath];

    DFImageView *imageView = (id)[cell viewWithTag:123];
    if (!imageView) {
        imageView = [[DFImageView alloc] initWithFrame:cell.contentView.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        imageView.tag = 123;
        [cell addSubview:imageView];
    }

    SDFFlickrPhoto *photo = _photos[indexPath.row];
    [imageView setImageWithAsset:photo.photoURLSmall];
    
    return cell;
}

#pragma mark - <UICollectionViewDelegate>

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *layout = (id)collectionViewLayout;
    CGFloat width = collectionView.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right - layout.minimumInteritemSpacing * 3;
    CGFloat side = width / 4.0; // It's not pixel perfect, but it's ok for now.
    return CGSizeMake(side, side);
}

@end
