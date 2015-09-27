//
//  SDFAFNetworkingDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 3/8/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFPhotos.h"
#import "SDFBuiltinNetworkingDemoViewController.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+UI.h>

static NSString * const reuseIdentifier = @"Cell";

@implementation SDFBuiltinNetworkingDemoViewController {
    id<DFImageManaging> _previousSharedManager;
    
    NSArray *_photos;
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
    
    _photos = [SDFPhotos URLsForSmallPhotos];
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
    
    NSURL *URL = _photos[indexPath.row];
    [imageView prepareForReuse];
    [imageView setImageWithResource:URL targetSize:[self _imageTargetSize] contentMode:DFImageContentModeAspectFill options:nil];
    
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

@end
