//
//  SDFCompositeSampleCollectionViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFFlickrPhoto.h"
#import "SDFFlickrRecentPhotosModel.h"
#import "SDFNetworkingDemoCollectionViewController.h"
#import "UIViewController+SDFImageManager.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <DFProxyImageManager.h>


@interface SDFNetworkingDemoCollectionViewController ()

<DFCollectionViewPreheatingControllerDelegate,
SDFFlickrRecentPhotosModelDelegate>

@end

@implementation SDFNetworkingDemoCollectionViewController {
    UIActivityIndicatorView *_activityIndicatorView;
    NSMutableArray *_photos;
    SDFFlickrRecentPhotosModel *_model;
    NSURLCache *_cache;
    
    DFCollectionViewPreheatingController *_preheatingController;
    
    // Debug
    UILabel *_detailsLabel;
}

static NSString * const reuseIdentifier = @"Cell";

- (instancetype)initWithCollectionViewLayout:(UICollectionViewLayout *)layout {
    if (self = [super initWithCollectionViewLayout:layout]) {
        _allowsPreheating = YES;
        _displaysPreheatingDetails = NO;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.collectionView.alwaysBounceVertical = NO;
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _activityIndicatorView = [self df_showActivityIndicatorView];

    _photos = [NSMutableArray new];
    
    _model = [SDFFlickrRecentPhotosModel new];
    _model.delegate = self;
    [_model poll];
    
    if (self.displaysPreheatingDetails) {
        [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Change direction" style:UIBarButtonItemStyleBordered target:self action:@selector(_buttonChangeScrollDirectionPressed:)]];
        
        _detailsLabel = [UILabel new];
        _detailsLabel.backgroundColor = [UIColor colorWithWhite:0.f alpha:0.6];
        _detailsLabel.font = [UIFont fontWithName:@"Courier" size:12.f];
        _detailsLabel.textColor = [UIColor whiteColor];
        _detailsLabel.textAlignment = NSTextAlignmentCenter;
        _detailsLabel.translatesAutoresizingMaskIntoConstraints = NO;
        NSDictionary *views = NSDictionaryOfVariableBindings(_detailsLabel);
        [self.view addSubview:_detailsLabel];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[_detailsLabel]|" options:kNilOptions metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[_detailsLabel(==40)]|" options:NSLayoutFormatAlignAllBottom metrics:nil views:views]];
    }
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
    
    // Resets preheat rect and stop preheating images via delegate call.
    [_preheatingController resetPreheatRect];
    _preheatingController = nil;
}

#pragma mark - Actions

- (void)_buttonChangeScrollDirectionPressed:(UIButton *)button {
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.scrollDirection = (layout.scrollDirection == UICollectionViewScrollDirectionHorizontal) ? UICollectionViewScrollDirectionVertical : UICollectionViewScrollDirectionHorizontal;
    [_preheatingController updatePreheatRect];
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
    [imageView setImageWithAsset:[NSURL URLWithString:photo.photoURL] targetSize:[self _imageTargetSize] contentMode:DFImageContentModeAspectFill options:nil];
    
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
    
    if (self.displaysPreheatingDetails) {
        _detailsLabel.text = [NSString stringWithFormat:@"Preheat window: %@", NSStringFromCGRect(controller.preheatRect)];
        [self _logAddedIndexPaths:addedIndexPaths removeIndexPaths:removedIndexPaths];
    }
}

- (void)_logAddedIndexPaths:(NSArray *)addedIndexPaths removeIndexPaths:(NSArray *)removeIndexPaths {
    NSMutableArray *added = [NSMutableArray new];
    for (NSIndexPath *indexPath in addedIndexPaths) {
        [added addObject:[NSString stringWithFormat:@"(%i,%i)", (int)indexPath.section, (int)indexPath.item]];
    }
    
    NSMutableArray *removed = [NSMutableArray new];
    for (NSIndexPath *indexPath in removeIndexPaths) {
        [removed addObject:[NSString stringWithFormat:@"(%i,%i)", (int)indexPath.section, (int)indexPath.item]];
    }
    
    NSLog(@"Did change preheat window. %@", @{ @"removed items" : [removed componentsJoinedByString:@" "], @"added items" : [added componentsJoinedByString:@" "] });
}

- (NSArray *)_imageAssetsAtIndexPaths:(NSArray *)indexPaths {
    NSMutableArray *assets = [NSMutableArray new];
    for (NSIndexPath *indexPath in indexPaths) {
        SDFFlickrPhoto *photo = _photos[indexPath.row];
        [assets addObject:[NSURL URLWithString:photo.photoURL]];
    }
    return assets;
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
        [_preheatingController updatePreheatRect];
    }
}

@end
