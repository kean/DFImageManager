//
//  ViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFMainDemoViewController.h"
#import "SDFMenuViewController.h"
#import "SDFNetworkSampleCollectionViewController.h"
#import "SDFPhotosKitSampleViewController.h"


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
    
    NSMutableArray *sections = [NSMutableArray new];
    
    [sections addObject:({
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[SDFMenuItem itemWithTitle:@"Zero Config Demo" subtitle:@"Showcases most of image manager features" action:^{
            SDFMainDemoViewController *controller = [SDFMainDemoViewController new];
            controller.title = @"Demo";
            [self.navigationController pushViewController:controller animated:YES];
        }]];
        [SDFMenuSection sectionWithTitle:@"Main" items:items];
    })];
    
    [sections addObject:({
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[SDFMenuItem itemWithTitle:@"Network Demo" action:^{
            UIViewController *controller = [SDFNetworkSampleCollectionViewController new];
            controller.title = @"Network Demo";
            [self.navigationController pushViewController:controller animated:YES];
        }]];
        [items addObject:[SDFMenuItem itemWithTitle:@"Photos Kit Demo" action:^{
            [self.navigationController pushViewController:[SDFPhotosKitSampleViewController new] animated:YES];
        }]];
        [SDFMenuSection sectionWithTitle:@"Image Managers" items:items];
    })];
    
    [sections addObject:({
        NSMutableArray *items = [NSMutableArray new];
        [items addObject:[SDFMenuItem itemWithTitle:@"Preheating Demo" subtitle:@"Preheating with complex collection view layout"  action:^{
            // TODO: Open demo
        }]];
        [items addObject:[SDFMenuItem itemWithTitle:@"Composite Request Demo" action:^{
            SDFNetworkSampleCollectionViewController *controller = [SDFNetworkSampleCollectionViewController new];
            controller.allowsCompositeImageRequests = YES;
            controller.numberOfItemsPerRow = 2;
            [self.navigationController pushViewController:controller animated:YES];
        }]];
        [SDFMenuSection sectionWithTitle:@"Other" items:items];
    })];
    
    _sections = [sections copy];
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
