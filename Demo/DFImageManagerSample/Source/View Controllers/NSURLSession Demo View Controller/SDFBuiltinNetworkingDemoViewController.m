//
//  SDFAFNetworkingDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 3/8/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFBuiltinNetworkingDemoViewController.h"
#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotosModel.h"
#import "UIViewController+SDFImageManager.h"
#import <DFImageManagerKit.h>


static NSString * const reuseIdentifier = @"Cell";

@interface SDFBuiltinNetworkingDemoViewController ()

<SDFFlickrRecentPhotosModelDelegate>

@end

@implementation SDFBuiltinNetworkingDemoViewController {
    id<DFImageManaging> _previousSharedManager;
    
    UIActivityIndicatorView *_activityIndicatorView;
    NSMutableArray *_photos;
    SDFFlickrRecentPhotosModel *_model;
}

- (void)dealloc {
    [[DFImageManager sharedManager] invalidateAndCancel];
    [DFImageManager setSharedManager:_previousSharedManager];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithCollectionViewLayout:layout]) {
        [self _configureBuiltinManager];
    }
    return self;
}

- (void)_configureBuiltinManager {
    _previousSharedManager = [DFImageManager sharedManager];
    
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    configuration.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:1024 * 1024 * 256 diskPath:@"com.github.kean.default_image_cache"];
    
    DFURLImageFetcher *fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:configuration];
    id<DFImageManaging> manager = [[DFImageManager alloc] initWithConfiguration:[DFImageManagerConfiguration configurationWithFetcher:fetcher processor:[DFImageProcessor new] cache:[DFImageCache new]]];
    [DFImageManager setSharedManager:manager];
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
    [imageView prepareForReuse];
    [imageView setImageWithResource:[NSURL URLWithString:photo.photoURL] targetSize:[self _imageTargetSize] contentMode:DFImageContentModeAspectFill options:nil];
    
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
    if (page == 0) {
        self.collectionView.alpha = 0.0;
        [UIView animateWithDuration:0.2f animations:^{
            self.collectionView.alpha = 1.0;
        }];
    }
}

@end
