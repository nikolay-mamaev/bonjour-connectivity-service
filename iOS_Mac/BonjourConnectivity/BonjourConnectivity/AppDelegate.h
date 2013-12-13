//
//  AppDelegate.h
//  BonjourConnectivity
//
//  Created by Nikolay Mamaev on 3/31/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import <UIKit/UIKit.h>

extern NSString* const kNetServiceConnectToDeviceNotification;
extern NSString* const kNetServiceConnectToDeviceNotificationDeviceIdxParam;
extern NSString* const kNetServiceConnectedNotification;
extern NSString* const kNetServiceFailedToConnectNotification;
extern NSString* const kNetServiceDisconnectFromDeviceNotification;
extern NSString* const kNetServiceDisconnectedNotification;
extern NSString* const kNetServiceReceivedDataNotification;
extern NSString* const kNetServiceSendDataNotification;
extern NSString* const kNetServiceSendDataTimeoutNotification;
extern NSString* const kNetServiceSendDataSuccessfulNotification;
extern NSString* const kNetServiceTransmitDataNotificationTextParam;
extern NSString* const kObservedDevicesListUpdatedNotification;
extern NSString* const kNetServiceType;

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (nonatomic, strong) UIWindow *window;
@property (nonatomic, readonly) NSArray* observedDevicesList;

@end
