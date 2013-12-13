//
//  AppDelegate.m
//  BonjourConnectivity
//
//  Created by Nikolay Mamaev on 3/31/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//


#import <CoreFoundation/CoreFoundation.h>
#import <sys/socket.h>
#import <netinet/in.h>
#import "AppDelegate.h"
#import "BCService.h"
#import "ViewController.h"


#pragma mark - Constants
NSString* const kNetServiceConnectToDeviceNotification = @"NetServiceConnectToDeviceNotification";
NSString* const kNetServiceConnectToDeviceNotificationDeviceIdxParam = @"NetServiceConnectToDeviceNotificationDeviceIdxParam";
NSString* const kNetServiceConnectedNotification = @"NetServiceConnectedNotification";
NSString* const kNetServiceFailedToConnectNotification = @"NetServiceFailedToConnectNotification";
NSString* const kNetServiceDisconnectFromDeviceNotification = @"NetServiceDisconnectFromDeviceNotification";
NSString* const kNetServiceDisconnectedNotification = @"NetServiceDisconnectedNotification";
NSString* const kNetServiceReceivedDataNotification = @"NetServiceReceivedDataNotification";
NSString* const kNetServiceSendDataNotification = @"NetServiceSendDataNotification";
NSString* const kNetServiceSendDataTimeoutNotification = @"NetServiceSendDataTimeoutNotification";
NSString* const kNetServiceSendDataSuccessfulNotification = @"NetServiceSendDataSuccessfulNotification";
NSString* const kNetServiceTransmitDataNotificationTextParam = @"NetServiceTransmitDataNotificationTextParam";
NSString* const kObservedDevicesListUpdatedNotification = @"ObservedDevicesListUpdated";
//const NSString* kNetServiceType = @"_clipbrdshare._tcp.";
//const NSString* kNetServiceName = @"Bonjour Connectivity";


#pragma mark - AppDelegate interface extension
@interface AppDelegate() <BCServiceDelegate>

@property (nonatomic, strong) BCService* bcService;

- (void)onNetServiceConnectToDevice:(NSNotification*)notification;
- (void)onNetServiceDisconnectFromDevice:(NSNotification*)notification;
- (void)onNetServiceSendDataNotification:(NSNotification*)notification;

@end


#pragma mark - AppDelegate inteface implementation
@implementation AppDelegate

#pragma mark Properties
@synthesize bcService = _bcService;

#pragma mark Application lifecycle
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetServiceSendDataNotification:)
                                                 name:kNetServiceSendDataNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetServiceConnectToDevice:)
                                                 name:kNetServiceConnectToDeviceNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(onNetServiceDisconnectFromDevice:)
                                                 name:kNetServiceDisconnectFromDeviceNotification
                                               object:nil];
    
    self.bcService = [[BCService alloc] initWithDelegate:self withDeviceName:[UIDevice currentDevice].name];
    [self.bcService startObserving];

    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

#pragma mark Properties accessors
- (NSArray*)observedDevicesList
{
    return self.bcService.observedDevices;
}

#pragma mark Private methods
- (void)onNetServiceConnectToDevice:(NSNotification*)notification
{
    NSNumber* deviceIdxObj = [notification.userInfo objectForKey:kNetServiceConnectToDeviceNotificationDeviceIdxParam];
    NSInteger deviceIdx = deviceIdxObj.integerValue;
    [self.bcService connectToDevice:[self.observedDevicesList objectAtIndex:deviceIdx]];
}

- (void)onNetServiceDisconnectFromDevice:(NSNotification*)notification
{
    [self.bcService disconnectFromConnectedDevice];
}

- (void)onNetServiceSendDataNotification:(NSNotification*)notification
{
    NSString* stringToSend = [notification.userInfo objectForKey:kNetServiceTransmitDataNotificationTextParam];
    [self.bcService shareString:stringToSend];
}

#pragma mark BCServiceDelegate methods
// Called if hosting device name changed automatically (happens if there is another
// BonjourConnectivity device with the same name is presented in the network
- (void)bonjourConnectivityService:(BCService*)service
    didChangeHostingDeviceName:(NSString*)newDeviceName
{
    // TODO: Change device name and re-create BCService
    DebugLog(@"Host service name changed to %@", newDeviceName);
}

// After this call, then hosting device is unable to receive data from other BonjourConnectivity
// devices until bonjourConnectivityServiceDidPublish: is called again
- (void)bonjourConnectivityServiceDidStop:(BCService*)service
{
    DebugLog(@"Host service stopped");
}

// If called, then hosting device is ready to receive data from other BonjourConnectivity devices
- (void)bonjourConnectivityServiceDidPublish:(BCService*)service
{
    DebugLog(@"Host service published");
}

// If called, then hosting device can't receive data from other BonjourConnectivity devices
- (void)bonjourConnectivityService:(BCService*)service
     didFailToPublishWithError:(NSNetServicesError)error
{
    DebugLog(@"Host service failed to publish");
}

- (void)bonjourConnectivityServiceWillStartObserving:(BCService*)service
{
    DebugLog(@"Host service will start observing");
}

- (void)bonjourConnectivityServiceDidStopObserving:(BCService*)service
{
    DebugLog(@"Host service did stop observing");
}

// Called each time when BCService finds another devices with BonjourConnectivity app ('devices'
// array's elements are of BCDevice class)
- (void)bonjourConnectivityService:(BCService*)service
             didObserveDevices:(NSArray*)devices
{
    DebugLog(@"Host service found the following devices:");

    for (BCDevice* device in devices)
    {
        DebugLog(@"\t%@", device.name);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kObservedDevicesListUpdatedNotification object:nil];
}

// Called each time when BCService finds that a previously observed devices with BonjourConnectivity
// app have disappeared ('devices' array's elements are of BCDevice class)
- (void)bonjourConnectivityService:(BCService*)service
              didRemoveDevices:(NSArray*)devices
{
    DebugLog(@"Host service removed the following devices:");
    for (BCDevice* device in devices)
    {
        DebugLog(@"\t%@", device.name);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kObservedDevicesListUpdatedNotification object:nil];
}

- (void)bonjourConnectivityService:(BCService*)service
            didConnectToDevice:(BCDevice*)device
{
    DebugLog(@"Host service connected to the device %@", device.name);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceConnectedNotification object:nil];
}

- (void)bonjourConnectivityService:(BCService*)service
      didFailToConnectToDevice:(BCDevice*)device
                     withError:(BCServiceResult)errorCode
{
    DebugLog(@"Host service failed to connect to the device %@", device.name);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceFailedToConnectNotification object:nil];
}

- (void)bonjourConnectivityService:(BCService *)service
       didDisconnectFromDevice:(BCDevice *)device
{
    DebugLog(@"Host service disconnected from the device %@", device.name);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceDisconnectedNotification object:nil];
}

#pragma mark Receiving
// Called when another device with BonjourConnectivity app sends its data to this device
- (void)bonjourConnectivityService:(BCService*)service
              didReceiveString:(NSString *)string
                    fromDevice:(BCDevice *)device
{
    DebugLog(@"Host service received data from device %@", device.name);
    [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceReceivedDataNotification
                                                        object:nil
                                                      userInfo:@{kNetServiceTransmitDataNotificationTextParam : string}];
}

- (void)bonjourConnectivityService:(BCService*)service
     failedToReceiveFromDevice:(BCDevice*)device
                     withError:(BCServiceResult)errorCode
{
    DebugLog(@"Host service failed to receive data from device %@", device.name);
}

#pragma mark Sharing
// Called in response to BCService's shareData:ofType:toDevice: method
- (void)bonjourConnectivityService:(BCService*)service
            didShareWithDevice:(BCDevice*)device
                    withResult:(BCServiceResult)result
{
    DebugLog(@"Host service sent data to the device %@ with result %d", device.name, result);
    if (result == BCServiceSuccess) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceSendDataSuccessfulNotification
                                                            object:nil];
    } else if (result == BCServiceFailTimeout) {
        [[NSNotificationCenter defaultCenter] postNotificationName:kNetServiceSendDataTimeoutNotification
                                                            object:nil];
    }
}

@end
