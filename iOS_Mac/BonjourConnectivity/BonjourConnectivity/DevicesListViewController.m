//
//  DevicesListViewController.m
//  BonjourConnectivity
//
//  Created by Nikolay Mamaev on 12/6/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "DevicesListViewController.h"
#import "BCDevice.h"
#import "ViewController.h"

@interface DevicesListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, weak) AppDelegate* appDelegate;
@property (nonatomic) NSInteger selectedDeviceIdx;

- (void)observedDevicesListUpdatedNotification:(NSNotification*)notification;
- (void)connectedToDevice:(NSNotification*)notification;
- (void)failedConnectToDevice:(NSNotification*)notification;

@end

@implementation DevicesListViewController

@synthesize appDelegate = _appDelegate;
@synthesize selectedDeviceIdx = _selectedDeviceIdx;

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(observedDevicesListUpdatedNotification:) name:kObservedDevicesListUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectedToDevice:) name:kNetServiceConnectedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(failedConnectToDevice:) name:kNetServiceFailedToConnectNotification object:nil];
    self.appDelegate = (AppDelegate*)[UIApplication sharedApplication].delegate;

    self.progressViewContentContainer.layer.cornerRadius = 10.0f;
}

- (void)viewWillAppear:(BOOL)animated
{
    self.progressView.hidden = YES;
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceDisconnectFromDeviceNotification
                                                        object:nil];
}

#pragma mark Private methods
- (void)observedDevicesListUpdatedNotification:(NSNotification*)notification
{
    [self.tableView reloadData];
}

- (void)connectedToDevice:(NSNotification*)notification
{
    self.progressView.hidden = YES;
    UIStoryboard* storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
    ViewController* vc = [storyboard instantiateViewControllerWithIdentifier:@"TalkToDeviceViewController"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)failedConnectToDevice:(NSNotification*)notification
{
    UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:@"Error"
                                                        message:@"Failed to connect"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    self.progressView.hidden = YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.appDelegate.observedDevicesList.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"DevicesListCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    BCDevice* device =[self.appDelegate.observedDevicesList objectAtIndex:indexPath.row];
    cell.textLabel.text = device.name;
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.selectedDeviceIdx = indexPath.row;
    NSDictionary* userInfo = @{ kNetServiceConnectToDeviceNotificationDeviceIdxParam : @(self.selectedDeviceIdx) };
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceConnectToDeviceNotification
                                                        object:nil
                                                      userInfo:userInfo];
    self.progressView.hidden = NO;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end
