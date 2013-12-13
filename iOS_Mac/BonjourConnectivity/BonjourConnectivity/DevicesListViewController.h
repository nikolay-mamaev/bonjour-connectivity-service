//
//  DevicesListViewController.h
//  BonjourConnectivity
//
//  Created by Nikolay Mamaev on 12/6/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@interface DevicesListViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIView *progressView;
@property (weak, nonatomic) IBOutlet UIView *progressViewContentContainer;


@end
