//
//  ViewController.h
//  BonjourConnectivity
//
//  Created by Nikolay Mamaev on 3/31/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITextView *textToShare;
@property (weak, nonatomic) IBOutlet UILabel *receivedText;
@property (weak, nonatomic) IBOutlet UILabel *statusText;
@property (weak, nonatomic) IBOutlet UIButton *shareTextButton;

- (IBAction)shareTextButtonPressed:(id)sender;

@end
