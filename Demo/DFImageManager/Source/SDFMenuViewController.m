//
//  ViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFBuiltinNetworkingDemoViewController.h"
#import "SDFFilesystemDemoViewController.h"
#import "SDFGIFDemoViewController.h"
#import "SDFMenuViewController.h"
#import "SDFNetworkingDemoCollectionViewController.h"
#import "SDFPhotosKitDemoViewController.h"
#import "SDFProgressiveJPEGDemoViewController.h"
#import <Photos/Photos.h>
#import <DFImageManager/DFImageManagerKit.h>


@interface SDFMenuSection : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSArray *items;

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray *)items;

@end

@implementation SDFMenuSection

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray *)items {
    SDFMenuSection *section = [SDFMenuSection new];
    section.title = title;
    section.items = items;
    return section;
}

@end



@interface SDFMenuItem : NSObject

@property (nonatomic) NSString *title;
@property (nonatomic) NSString *subtitle;
@property (nonatomic, copy) void (^action)(void);

+ (instancetype)itemWithTitle:(NSString *)title action:(void (^)(void))action;
+ (instancetype)itemWithTitle:(NSString *)title subtitle:(NSString *)subtitle action:(void (^)(void))action;

@end

@implementation SDFMenuItem

+ (instancetype)itemWithTitle:(NSString *)title action:(void (^)(void))action {
    return [self itemWithTitle:title subtitle:nil action:action];
}

+ (instancetype)itemWithTitle:(NSString *)title subtitle:(NSString *)subtitle action:(void (^)(void))action {
    SDFMenuItem *item = [SDFMenuItem new];
    item.title = title;
    item.subtitle = subtitle;
    item.action = action;
    return item;
}

@end


@interface SDFMenuViewController ()

@end

@implementation SDFMenuViewController {
    NSArray /* SDFSection */ *_sections;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc] initWithTitle:@"Clean Cache" style:UIBarButtonItemStylePlain target:self action:@selector(_cleanCacheButtonTapped)]];
    
    NSMutableArray *sections = [NSMutableArray new];
    
    SDFMenuViewController *__weak weakSelf = self;
    
    [sections addObject:({
        NSMutableArray *items = [NSMutableArray new];

        [items addObject:[SDFMenuItem itemWithTitle:@"Networking Demo" subtitle:@"Built-in networking on top of NSURLSession" action:^{
            SDFBuiltinNetworkingDemoViewController *controller = [SDFBuiltinNetworkingDemoViewController new];
            controller.title = @"Networking Demo";
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }]];
        
        [items addObject:[SDFMenuItem itemWithTitle:@"Filesystem Demo" subtitle:nil action:^{
            SDFFilesystemDemoViewController *controller = [SDFFilesystemDemoViewController new];
            controller.title = @"Filesystem Demo";
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }]];
        
        [items addObject:[SDFMenuItem itemWithTitle:@"Photos Kit Demo" subtitle:@"'PhotosKit' subspec" action:^{
            SDFPhotosKitDemoViewController *controller = [SDFPhotosKitDemoViewController new];
            controller.title = @"Photos Kit Demo";
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }]];
        
        [items addObject:[SDFMenuItem itemWithTitle:@"AFNetworking Demo" subtitle:@"'AFNetworking' subspec"  action:^{
            SDFNetworkingDemoCollectionViewController *controller = [SDFNetworkingDemoCollectionViewController new];
            controller.allowsPreheating = NO;
            controller.title = @"AFNetworking Demo";
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }]];
        
        [SDFMenuSection sectionWithTitle:@"Image Managers" items:items];
    })];
    
    [sections addObject:({
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[SDFMenuItem itemWithTitle:@"GIF Demo" subtitle:@"'GIF' subspec" action:^{
            SDFGIFDemoViewController *controller = [SDFGIFDemoViewController new];
            controller.title = @"GIF Demo";
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }]];
        [items addObject:[SDFMenuItem itemWithTitle:@"Progressive Decoding Demo" subtitle:@"Progressive and baseline JPEG" action:^{
            SDFProgressiveJPEGDemoViewController *controller = [SDFProgressiveJPEGDemoViewController new];
            controller.title = @"Progressive JPEG Demo";
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }]];
        [items addObject:[SDFMenuItem itemWithTitle:@"Preheating Demo" subtitle:@"Preheat images close to viewport"  action:^{
            SDFNetworkingDemoCollectionViewController *controller = [SDFNetworkingDemoCollectionViewController new];
            controller.allowsPreheating = YES;
            controller.numberOfItemsPerRow = 3;
            controller.displaysPreheatingDetails = YES;
            controller.title = @"Preheating Demo";
            [weakSelf.navigationController pushViewController:controller animated:YES];
        }]];
        [SDFMenuSection sectionWithTitle:@"Other" items:items];
    })];
    
    _sections = [sections copy];
}

#pragma mark - Actions

- (void)_cleanCacheButtonTapped {
    [[DFImageManager sharedManager] removeAllCachedImages];
}

#pragma mark - <UITableViewDataSource>

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return _sections.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    SDFMenuSection *menuSection = _sections[section];
    return menuSection.items.count;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    SDFMenuSection *menuSection = _sections[section];
    return menuSection.title;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseID" forIndexPath:indexPath];
    SDFMenuItem *item = [self _itemAtIndexPath:indexPath];
    cell.textLabel.text = item.title;
    cell.detailTextLabel.text = item.subtitle;
    return cell;
}

- (SDFMenuItem *)_itemAtIndexPath:(NSIndexPath *)indexPath {
    SDFMenuSection *section = _sections[indexPath.section];
    return section.items[indexPath.row];
}

#pragma mark - <UITableViewDelegate>

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    SDFMenuItem *item = [self _itemAtIndexPath:indexPath];
    item.action();
}

@end
