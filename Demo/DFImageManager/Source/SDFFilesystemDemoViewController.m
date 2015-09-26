//
//  SDFFilesystemDemoViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 1/7/15.
//  Copyright (c) 2015 Alexander Grebenyuk. All rights reserved.
//

#import "SDFFilesystemDemoViewController.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+UI.h>


static NSString * const reuseIdentifier = @"Cell";

@implementation SDFFilesystemDemoViewController {
    NSArray *_photos;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    _photos = [self _photosWithNames:@[ @"10669363", @"10849093", @"10861057", @"10872981", @"10915709", @"10926234" ]];
    [self.collectionView reloadData];
}

- (NSArray *)_photosWithNames:(NSArray *)names {
    NSMutableArray *photos = [NSMutableArray new];
    for (NSString *name in names) {
        NSURL *URL = [[NSBundle mainBundle] URLForResource:name withExtension:@"jpg"];
        if (URL != nil) {
            [photos addObject:URL];
        }
    }
    return [photos copy];
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
    
    NSURL *imageURL = _photos[indexPath.row];
    [imageView setImageWithResource:imageURL targetSize:[self _imageTargetSize] contentMode:DFImageContentModeAspectFill options:nil];
    
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
