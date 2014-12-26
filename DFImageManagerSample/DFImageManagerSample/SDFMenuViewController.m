//
//  ViewController.m
//  DFImageManagerSample
//
//  Created by Alexander Grebenyuk on 12/22/14.
//  Copyright (c) 2014 Alexander Grebenyuk. All rights reserved.
//

#import "SDFMenuViewController.h"
#import "SDFNetworkSampleCollectionViewController.h"
#import "SDFPhotosKitSampleViewController.h"


@interface SDFMenuViewController ()

@end

@implementation SDFMenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuseID" forIndexPath:indexPath];
    NSString *title;
    NSInteger row = indexPath.row;
    if (row == 0) title = @"Network Sample";
    if (row == 1) title = @"Photos Kit Sample";
    if (row == 2) title = @"Composite Image Request";
    cell.textLabel.text = title;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == 0) {
        [self.navigationController pushViewController:[SDFNetworkSampleCollectionViewController new] animated:YES];
    } else if (indexPath.row == 1) {
        [self.navigationController pushViewController:[SDFPhotosKitSampleViewController new] animated:YES];
    } else if (indexPath.row == 2) {
        SDFNetworkSampleCollectionViewController *controller = [SDFNetworkSampleCollectionViewController new];
        controller.shouldUseCompositeImageRequests = YES;
        controller.numberOfItemsPerRow = 2;
        [self.navigationController pushViewController:controller animated:YES];
    }
}

@end
