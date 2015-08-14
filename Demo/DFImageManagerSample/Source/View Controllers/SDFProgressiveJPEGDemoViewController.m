//
//  SDFProgressiveJPEGDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 14/08/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFProgressiveJPEGDemoViewController.h"
#import "SDFImageCollectionViewCell.h"
#import <DFImageManager/DFImageManagerKit.h>

static NSString *const kReuseIdentifierImageCell = @"kReuseIdentifierImageCell";

@implementation SDFProgressiveJPEGDemoViewController  {
    id<DFImageManaging> _previousSharedManager;
    
    NSArray *_imageURLs;
}

- (void)dealloc {
    [DFImageManager setSharedManager:_previousSharedManager];
}

- (instancetype)init {
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithCollectionViewLayout:layout]) {
        [self _configureProgressiveEnabledImageManager];
    }
    return self;
}

- (void)_configureProgressiveEnabledImageManager {
    _previousSharedManager = [DFImageManager sharedManager];
    
    DFURLImageFetcher *fetcher = [[DFURLImageFetcher alloc] initWithSessionConfiguration:({
        NSURLSessionConfiguration *conf = [NSURLSessionConfiguration defaultSessionConfiguration];
        conf.URLCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:1024 * 1024 * 256 diskPath:@"com.github.kean.default_image_cache"];
        conf;
    })];
    DFImageManagerConfiguration *conf = [DFImageManagerConfiguration configurationWithFetcher:fetcher processor:[DFImageProcessor new] cache:[DFImageCache new]];
    conf.allowsProgressiveImage = YES;
    id<DFImageManaging> manager = [[DFImageManager alloc] initWithConfiguration:conf];
    [DFImageManager addSharedManager:manager];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[SDFImageCollectionViewCell class] forCellWithReuseIdentifier:kReuseIdentifierImageCell];
    self.collectionView.alwaysBounceVertical = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = self.view.backgroundColor;
    
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.sectionInset = UIEdgeInsetsMake(8.f, 8.f, 8.f, 8.f);
    layout.minimumInteritemSpacing = 8.f;
    
    _imageURLs = @[[NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9279542/f56dd15e-42c0-11e5-950d-75a29d1b2464.jpg"]];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SDFImageCollectionViewCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifierImageCell forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:235.f/255.f alpha:1.f];
    [cell.imageView df_prepareForReuse];
    NSURL *URL = _imageURLs[indexPath.row];
    DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new];
    options.allowsProgressiveImage = YES;
    [cell.imageView df_setImageWithResource:URL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:options.options];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    CGFloat width = (self.view.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right);
    return CGSizeMake(width, width);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _imageURLs.count;
}

@end
