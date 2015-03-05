//
//  SDFGIFSampleViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 3/5/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFGIFSampleViewController.h"
#import <DFImageManagerKit.h>


static NSString *kReuseIdentifier = @"kReuseIdentifier";

@interface SDFGIFSampleViewController () <UICollectionViewDelegateFlowLayout>

@end

@implementation SDFGIFSampleViewController {
    NSArray *_imageURLs;
}
- (instancetype)init {
    return [self initWithCollectionViewLayout:[UICollectionViewFlowLayout new]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:kReuseIdentifier];
    self.collectionView.alwaysBounceVertical = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = self.view.backgroundColor;
    
    _imageURLs =
    @[
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505557/77ff05ac-c2e7-11e4-9a09-ce5b7995cad0.gif"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505565/8aa02c90-c2e7-11e4-8127-71df010ca06d.gif"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505571/a28a6e2e-c2e7-11e4-8161-9f39cc3bb8df.gif"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505576/b785a8ac-c2e7-11e4-831a-666e2b064b95.gif"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505579/c88c77ca-c2e7-11e4-88ad-d98c7360602d.gif"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505595/def06c06-c2e7-11e4-9cdf-d37d28618af0.gif"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505634/26e5dad2-c2e8-11e4-89c3-3c3a63110ac0.gif"],
      [NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/6505643/42eb3ee8-c2e8-11e4-8666-ac9c8e1dc9b5.gif"]
      
      ];
    
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.sectionInset = UIEdgeInsetsMake(8.f, 8.f, 8.f, 8.f);
    layout.minimumInteritemSpacing = 8.f;
}

#pragma mark - UICollectionViewController

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifier forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:235.f/255.f alpha:1.f];
    
    DFImageView *imageView = (id)[cell viewWithTag:15];
    if (!imageView) {
        imageView = [[DFImageView alloc] initWithFrame:cell.bounds];
        imageView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        imageView.tag = 15;
        [cell addSubview:imageView];
    }
    
    [imageView prepareForReuse];
    [imageView setImageWithResource:_imageURLs[indexPath.item]];
    
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    CGFloat side = (self.view.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right);
    return CGSizeMake(side, side);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _imageURLs.count;
}

@end
