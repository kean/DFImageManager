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
    UISegmentedControl *_segmentedControl;
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
        // disable URL cache for this fetcher
        conf.URLCache = nil;
        conf;
    })];
    DFImageManagerConfiguration *conf = [DFImageManagerConfiguration configurationWithFetcher:fetcher processor:[DFImageProcessor new] cache:[DFImageCache new]];
    conf.allowsProgressiveImage = YES;
    id<DFImageManaging> manager = [[DFImageManager alloc] initWithConfiguration:conf];
    [DFImageManager addSharedManager:manager];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _imageURLs = @[ @[[NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9294021/5d8d5c86-4448-11e5-8e48-f8279ea98514.jpg"]],
                    @[[NSURL URLWithString:@"https://cloud.githubusercontent.com/assets/1567433/9294013/350b1c1c-4448-11e5-9951-e2aa2ae2e600.jpg"]] ];
    
    self.navigationItem.titleView = ({
        UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"progressive", @"baseline"]];
        segmentedControl.selectedSegmentIndex = 0;
        [segmentedControl addTarget:self action:@selector(_segmentedControlValueChanged:) forControlEvents:UIControlEventValueChanged];
        _segmentedControl = segmentedControl;
        segmentedControl;
    });
    
    [self.collectionView registerClass:[SDFImageCollectionViewCell class] forCellWithReuseIdentifier:kReuseIdentifierImageCell];
    self.collectionView.alwaysBounceVertical = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.collectionView.backgroundColor = self.view.backgroundColor;
    
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    layout.sectionInset = UIEdgeInsetsMake(8.f, 8.f, 8.f, 8.f);
    layout.minimumInteritemSpacing = 8.f;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SDFImageCollectionViewCell *cell = (id)[collectionView dequeueReusableCellWithReuseIdentifier:kReuseIdentifierImageCell forIndexPath:indexPath];
    cell.backgroundColor = [UIColor colorWithWhite:235.f/255.f alpha:1.f];
    NSURL *URL = [self _currentDataSource][indexPath.row];
    [cell setImageWithRequest:({
        [DFImageRequest requestWithResource:URL targetSize:DFImageMaximumSize contentMode:DFImageContentModeAspectFill options:({
            DFMutableImageRequestOptions *options = [DFMutableImageRequestOptions new];
            options.allowsProgressiveImage = YES;
            options.options;
        })];
    })];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewFlowLayout *layout = (id)self.collectionViewLayout;
    CGFloat width = (self.view.bounds.size.width - layout.sectionInset.left - layout.sectionInset.right);
    return CGSizeMake(width, width);
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [self _currentDataSource].count;
}

- (NSArray *)_currentDataSource {
    return _imageURLs[_segmentedControl.selectedSegmentIndex];
}

#pragma mark - Actions

- (void)_segmentedControlValueChanged:(UISegmentedControl *)control {
    [self.collectionView reloadData];
}

@end
