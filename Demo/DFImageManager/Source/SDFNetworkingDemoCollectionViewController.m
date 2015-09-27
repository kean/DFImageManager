//
//  SDFCompositeSampleCollectionViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFPhotos.h"
#import "SDFNetworkingDemoCollectionViewController.h"
#import <DFImageManager/DFImageManagerKit.h>
#import <DFImageManager/DFImageManagerKit+UI.h>
#import <DFImageManager/DFImageManagerKit+AFNetworking.h>
#import <AFNetworking/AFNetworkActivityIndicatorManager.h>
#import <AFNetworking/AFHTTPSessionManager.h>

@interface SDFNetworkingDemoCollectionViewController () <DFCollectionViewPreheatingControllerDelegate>

@end

@implementation SDFNetworkingDemoCollectionViewController {
    NSArray *_photos;
    
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
        
    [AFNetworkActivityIndicatorManager sharedManager].enabled = YES;
    
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
    _photos = [SDFPhotos URLsForSmallPhotos];
    
    if (self.displaysPreheatingDetails) {
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
    
    [imageView prepareForReuse];
    
    NSURL *URL = _photos[indexPath.row];
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

#pragma mark - <DFCollectionViewPreheatingControllerDelegate>

- (void)collectionViewPreheatingController:(DFCollectionViewPreheatingController *)controller didUpdatePreheatRectWithAddedIndexPaths:(NSArray *)addedIndexPaths removedIndexPaths:(NSArray *)removedIndexPaths {
    [[DFImageManager sharedManager] startPreheatingImagesForRequests:[self _imageRequestsAtIndexPaths:addedIndexPaths]];
    [[DFImageManager sharedManager] stopPreheatingImagesForRequests:[self _imageRequestsAtIndexPaths:removedIndexPaths]];
    
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

- (NSArray *)_imageRequestsAtIndexPaths:(NSArray *)indexPaths {
    CGSize targetSize = [self _imageTargetSize];
    NSMutableArray *requests = [NSMutableArray new];
    for (NSIndexPath *indexPath in indexPaths) {
        NSURL *URL = _photos[indexPath.row];
        [requests addObject:[DFImageRequest requestWithResource:URL targetSize:targetSize contentMode:DFImageContentModeAspectFill options:nil]];
    }
    return requests;
}

@end
