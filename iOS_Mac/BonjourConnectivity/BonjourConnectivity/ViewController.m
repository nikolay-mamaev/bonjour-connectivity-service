//
//  ViewController.m
//  BonjourConnectivity
//
//  Created by Nikolay Mamaev on 3/31/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import <QuartzCore/QuartzCore.h>

@interface ViewController ()

- (void)onNetServiceReceivedData:(NSNotification*)notification;
- (void)onNetServiceSendDataTimeout:(NSNotification*)notification;
- (void)onNetServiceSendDataSuccessful:(NSNotification*)notification;
- (void)onNetServiceDisconnected:(NSNotification *)notification;

@end

@implementation ViewController

@synthesize textToShare = _textToShare;
@synthesize receivedText = _receivedText;
@synthesize statusText = _statusText;
@synthesize shareTextButton = _shareTextButton;

- (void)viewDidLoad
{
    [super viewDidLoad];

	self.textToShare.layer.borderColor = [UIColor blackColor].CGColor;
    self.textToShare.layer.borderWidth = 1.0;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetServiceReceivedData:)
                                                 name:kNetServiceReceivedDataNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetServiceSendDataTimeout:)
                                                 name:kNetServiceSendDataTimeoutNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetServiceSendDataSuccessful:)
                                                 name:kNetServiceSendDataSuccessfulNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetServiceDisconnected:)
                                                 name:kNetServiceDisconnectedNotification
                                               object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)shareTextButtonPressed:(id)sender
{
    self.shareTextButton.enabled = NO;
    self.statusText.text = @"Sending...";

    NSDictionary* userInfo = @{ kNetServiceTransmitDataNotificationTextParam : self.textToShare.text };
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceSendDataNotification
                                                        object:nil
                                                      userInfo:userInfo];
    [self.textToShare resignFirstResponder];
}

- (void)onNetServiceReceivedData:(NSNotification*)notification
{
    NSString* receivedString = [notification.userInfo objectForKey:kNetServiceTransmitDataNotificationTextParam];
    self.receivedText.text = receivedString;
}

- (void)onNetServiceSendDataTimeout:(NSNotification*)notification
{
    self.statusText.text = @"Sharing unsuccessful (operation timed out)";
    self.shareTextButton.enabled = YES;
}

- (void)onNetServiceSendDataSuccessful:(NSNotification*)notification
{
    self.statusText.text = @"Sharing successful";
    self.shareTextButton.enabled = YES;
}

- (void)onNetServiceDisconnected:(NSNotification *)notification
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
