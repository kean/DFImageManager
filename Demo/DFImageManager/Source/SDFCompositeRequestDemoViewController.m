//
//  SDFCompositeRequestDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/5/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFCompositeCollectionImageViewCell.h"
#import "SDFCompositeRequestDemoViewController.h"
#import <DFImageManager/DFImageManagerKit.h>


static NSString * const reuseIdentifier = @"Cell";

@implementation SDFCompositeRequestDemoViewController {
    NSArray *_photosPreviewURLs;
    NSArray *_photosFullsizeURLs;
}

- (NSInteger)numberOfItemsPerRow {
    return 1;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[SDFCompositeCollectionImageViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _photosPreviewURLs =
    @[
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782554/b607e694-57a6-11e5-8335-621f3db4e746.jpg"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782409/94560644-57a5-11e5-84a4-6e8f515c197e.jpg"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782446/cf493bea-57a5-11e5-8c5f-e40e0afc348e.jpg"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782486/1a85ac38-57a6-11e5-9d83-aa21982ebe6b.jpg"]
      ];
    _photosFullsizeURLs =
    @[
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782562/d3ffc41e-57a6-11e5-8e57-452b25d7bca7.jpg"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782407/84ad8adc-57a5-11e5-9aa4-b98ec5f4f930.jpg"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782443/c85d28aa-57a5-11e5-86ce-722960add0a8.jpg"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9782481/168993e2-57a6-11e5-9535-9d3063a83ca0.jpg"]
      ];
}

#pragma mark - <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _photosPreviewURLs.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SDFCompositeCollectionImageViewCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSURL *previewURL = _photosPreviewURLs[indexPath.row];
    NSURL *fullsizeURL = _photosFullsizeURLs[indexPath.row];
    
    DFImageRequest *requestWithSmallURL = [[DFImageRequest alloc] initWithResource:previewURL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil];
    
    DFImageRequest *requestWithBigURL = [[DFImageRequest alloc] initWithResource:fullsizeURL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:nil];
    
    [cell setImageWithRequests:@[requestWithSmallURL, requestWithBigURL]];
    
    return cell;
}

- (CGSize)_imageTargetSize {
    CGSize size = ((UICollectionViewFlowLayout *)self.collectionViewLayout).itemSize;
    CGFloat scale = [UIScreen mainScreen].scale;
    return CGSizeMake(size.width * scale, size.height * scale);
}

@end
