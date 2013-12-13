//
//  BCService.m
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/1/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//


#import <netinet/in.h>
#import <arpa/inet.h>
#import "BCService.h"
#import "BCDevicePrivate.h"
#import "GCDAsyncSocket.h"
#import "BCMessage.h"
#import "JSONEncoder.h"
#import "JSONDecoder.h"


#pragma mark - Types declaration


#pragma mark - Constants
NSString* const kNetServiceType = @"_bcservice._tcp.";
NSString* const kDeviceInfoPersistentStorageName = @"StoredDevices.data";
NSString* const kUniqeIdUserDefaultsKey = @"UniqeIdUserDefaultsName";
const long kBCDeviceHandhsakeTag = 1;
const long kBCDataTransferTag = 2;
const NSTimeInterval kDefaultSocketTimeout = 2.0;


#pragma mark - BCService interface extension
@interface BCService () <NSNetServiceDelegate, NSNetServiceBrowserDelegate, GCDAsyncSocketDelegate>

@property (nonatomic, strong) NSUserDefaults* userDefaults;

// Devices browsing properties
@property (nonatomic, strong) NSMutableArray* addedServicesPendingNotification;
@property (nonatomic) BOOL moreObservedServicesComing;
@property (nonatomic, strong) NSMutableArray* addedDevicesPendingNotification;
@property (nonatomic, strong) NSMutableArray* removedDevicesPendingNotification;

// Array of all BCDevice's whenever observed by the app and stored in the app's persistent storage
@property (nonatomic, strong) NSMutableDictionary* storedDevices;
@property (nonatomic, strong) NSString* deviceInfoFileName;

// Array of BCDevicePrivate's, contains devices observed during current session
@property (nonatomic, strong) NSMutableDictionary* observedDevicesInternal;

// Device on which the BonjourConnectivityService app is installed
@property (nonatomic, strong) BCDevicePrivate* hostingDevice;

// Currently connected device, should be contained in observedDevicesInternal
@property (nonatomic, strong) BCDevice* connectedDevice;
@property (nonatomic, strong) BCDevicePrivate* privateConnectedDevice;
@property (nonatomic, strong) NSMutableArray* addressesToConnect;

@property (nonatomic, strong) GCDAsyncSocket* localSocket;
@property (nonatomic, strong) GCDAsyncSocket* remoteSocket;
@property (nonatomic, strong) NSNetService* netService;
@property (nonatomic, strong) NSNetServiceBrowser* netServiceBrowser;
@property (nonatomic) NSUInteger netServicePort;

@property (nonatomic) BOOL isConnected;

- (void)prepareIncomingConnection;
- (void)startNetServiceBrowser;
- (void)stopNetServiceBrowser;
- (void)deallocNetServiceBrowser;
- (void)connectToNextDeviceAddress;

- (void)sendCommand:(NSString*)command withPayload:(BCMessagePayload*)payload;
- (void)parseHandshakeCommand:(BCHandshake*)handshakeData;
- (void)parseContentCommand:(BCMsgContent*)content;
- (void)parseErrorReceivingCommand:(BCError*)errorData;
- (void)parseReceivedSuccessfullyCommand;

- (void)storedDevicesUpdated;

- (NSArray*)inetAddressesFromArray:(NSArray*)addresses;

@end


#pragma mark - BCService interface implementation
@implementation BCService

@synthesize delegate = _delegate;
@synthesize userDefaults = _userDefaults;
@synthesize addedServicesPendingNotification = _addedServicesPendingNotification;
@synthesize moreObservedServicesComing = _moreObservedServicesComing;
@synthesize addedDevicesPendingNotification = _addedDevicesPendingNotification;
@synthesize removedDevicesPendingNotification = _removedDevicesPendingNotification;
@synthesize storedDevices = _storedDevices;
@synthesize deviceInfoFileName = _deviceInfoFileName;
@synthesize observedDevicesInternal = _observedDevicesInternal;
@synthesize hostingDevice = _hostingDevice;
@synthesize connectedDevice = _connectedDevice;
@synthesize privateConnectedDevice = _privateConnectedDevice;
@synthesize addressesToConnect = _addressesToConnect;
@synthesize localSocket = _localSocket;
@synthesize remoteSocket = _remoteSocket;
@synthesize netService = _netService;
@synthesize netServiceBrowser = _netServiceBrowser;
@synthesize netServicePort = _netServicePort;
@synthesize isConnected = _isConnected;

#pragma mark Properties accessors
- (NSArray*)observedDevices
{
    return [self.observedDevicesInternal allValues];
}

#pragma mark Interface methods
- (id)initWithDelegate:(id<BCServiceDelegate, NSObject>)delegate withDeviceName:(NSString*)deviceName
{
    self = [super init];
    if (nil != self) {
        self.delegate = delegate;
        self.userDefaults = [NSUserDefaults standardUserDefaults];
        self.hostingDevice = [[BCDevicePrivate alloc] initWithName:deviceName];
        NSString* hostingDeviceUuidString = [self.userDefaults stringForKey:kUniqeIdUserDefaultsKey];
        if (nil == hostingDeviceUuidString)
        {
            [self.hostingDevice generateUniqueId];
            [self.userDefaults setObject:self.hostingDevice.uniqueId.UUIDString forKey:kUniqeIdUserDefaultsKey];
        }
        else
        {
            self.hostingDevice.uniqueId = [[NSUUID alloc] initWithUUIDString:hostingDeviceUuidString];
        }
        
        NSString* docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        self.deviceInfoFileName = [NSString stringWithFormat:@"%@/%@", docsDir, kDeviceInfoPersistentStorageName];
        self.storedDevices = [NSMutableDictionary dictionaryWithContentsOfFile:self.deviceInfoFileName];
        if (nil == self.storedDevices) {
            self.storedDevices = [[NSMutableDictionary alloc] init];
        }
        
        [self prepareIncomingConnection];
//        [self startNetServiceBrowser];
    }
    
    return self;
}

- (void)connectToDevice:(BCDevice *)device
{
    // TODO: Replace ditinguishing devices by its names with distinguishing by uinqueId's
    // (sending handshake command during observing needs to be implemented for this)
    self.connectedDevice = device;
    self.privateConnectedDevice = [self.observedDevicesInternal objectForKey:device.name];
    self.addressesToConnect = [self.privateConnectedDevice.addresses mutableCopy];

    if (self.privateConnectedDevice == nil) {
        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didFailToConnectToDevice:withError:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate bonjourConnectivityService:self didFailToConnectToDevice:self.connectedDevice withError:BCServiceFailUnknownDevice];
                self.connectedDevice = nil;
                self.addressesToConnect = nil;
            });
        }
        return;
    }

    self.remoteSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    [self connectToNextDeviceAddress];
}

- (void)disconnectFromConnectedDevice
{
    [self.remoteSocket disconnect];
}

- (void)shareString:(NSString *)string
{
    BCMsgContent* content = [BCMsgContent messageContentWithString:string];
    [self sendCommand:kBCMsgContentCommand withPayload:content];
//    if (self.remoteSocket != nil) {
//        // Data transfer is currently in progress, refuse an incoming connection to let this data
//        // tranfer to complete
//        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didShareWithDevice:withResult:)]) {
//            dispatch_async(dispatch_get_main_queue(), ^{
//                [self.delegate bonjourConnectivityService:self didShareWithDevice:self.connectedDevice withResult:BCServiceFailDataTransferInProgress];
//            });
//        }
//        return;
//    }
}

- (void)startObserving
{
    [self startNetServiceBrowser];
}

- (void)stopObserving
{
    [self stopNetServiceBrowser];
}

- (void)dealloc
{
    [self deallocNetServiceBrowser];
    self.netService.delegate = nil;
    self.localSocket.delegate = nil;
    self.remoteSocket.delegate = nil;
    [self.localSocket disconnect];
    [self.remoteSocket disconnect];
}

#pragma mark Private methods
- (void)prepareIncomingConnection
{
    self.localSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *err = nil;
	if ([self.localSocket acceptOnPort:0 error:&err])
	{
		// Create and publish the bonjour service only if we are able to accept incoming connections
        
		// Obtain a port assigned by the system (we passed 0 into AsyncSocket's acceptOnPort:error:
        // which means we ask the system to assign port automatically to the listening socket
        self.netServicePort = self.localSocket.localPort;

        const struct sockaddr_in* socketaddr = (const struct sockaddr_in *)self.localSocket.localAddress.bytes;
        DebugLog(@"Listening address %s:%d", inet_ntoa(socketaddr->sin_addr), socketaddr->sin_port);

        self.netService = [[NSNetService alloc] initWithDomain:@"local."
                                                          type:kNetServiceType
                                                          name:self.hostingDevice.name
                                                          port:self.netServicePort];
        
        if (nil == self.netService)
        {
            DebugLog(@"!!! ERROR! Could not create network service");
            self.localSocket = nil;
            if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didFailToPublishWithError:)]) {
                [self.delegate bonjourConnectivityService:self didFailToPublishWithError:NSNetServicesUnknownError];
            }
            return;
        }
        
        self.netService.delegate = self;
        [self.netService publish];
	}
	else
	{
		DebugLog(@"Error in acceptOnPort:error: -> %@", err);
        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didFailToPublishWithError:)]) {
            [self.delegate bonjourConnectivityService:self didFailToPublishWithError:NSNetServicesUnknownError];
        }
	}
}

- (void)startNetServiceBrowser
{
    if (self.netServiceBrowser == nil) {
        self.netServiceBrowser = [[NSNetServiceBrowser alloc] init];
        self.netServiceBrowser.delegate = self;
    }
    self.observedDevicesInternal = [[NSMutableDictionary alloc] init];
	[self.netServiceBrowser searchForServicesOfType:kNetServiceType inDomain:@"local."];
}

- (void)stopNetServiceBrowser
{
    [self.netServiceBrowser stop];
}

- (void)deallocNetServiceBrowser
{
    self.netServiceBrowser.delegate = nil;
    [self stopNetServiceBrowser];
    self.netServiceBrowser = nil;
}

- (void)connectToNextDeviceAddress
{
	BOOL done = NO;
    
	while (!done && (self.privateConnectedDevice.addresses.count > 0))
	{
		NSData *addr;
		
		// Note: The serverAddresses array probably contains both IPv4 and IPv6 addresses.
		//
		// If your server is also using GCDAsyncSocket then you don't have to worry about it,
		// as the socket automatically handles both protocols for you transparently.
		
		if (YES) // Iterate forwards
		{
			addr = [self.addressesToConnect objectAtIndex:0];
			[self.addressesToConnect removeObjectAtIndex:0];
		}
		else // Iterate backwards
		{
			addr = [self.addressesToConnect lastObject];
			[self.addressesToConnect removeLastObject];
		}

        const struct sockaddr_in* socketaddr = (const struct sockaddr_in *)addr.bytes;
		DebugLog(@"Attempting connection to %s:%d (family: %d)", inet_ntoa(socketaddr->sin_addr), socketaddr->sin_port, socketaddr->sin_family);
		
		NSError *err = nil;
		if ([self.remoteSocket connectToAddress:addr error:&err])
		{
			done = YES;
		}
		else
		{
			DebugLog(@"Unable to connect: %@", err);
		}
	}
	
	if (!done)
	{
		DebugLog(@"Unable to connect to any resolved address");
        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didFailToConnectToDevice:withError:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate bonjourConnectivityService:self didFailToConnectToDevice:self.connectedDevice withError:BCServiceFailCantConnect];
                self.connectedDevice = nil;
                self.privateConnectedDevice = nil;
                self.remoteSocket = nil;
                self.addressesToConnect = nil;
            });
        }
	}
}

- (void)storedDevicesUpdated
{
    [self.storedDevices writeToFile:self.deviceInfoFileName atomically:YES];
}

- (NSArray*)inetAddressesFromArray:(NSArray*)addresses
{
    NSMutableArray* inetAddresses = [NSMutableArray arrayWithCapacity:self.netService.addresses.count];
    for (NSData* addr in addresses) {
        const struct sockaddr_in* socketaddr = (const struct sockaddr_in *)addr.bytes;
        if (AF_INET == socketaddr->sin_family) {
            [inetAddresses addObject:addr];
        }
    }

    return [NSArray arrayWithArray:inetAddresses];
}

#pragma mark Methods for BCMessage
- (void)sendCommand:(NSString*)command withPayload:(BCMessagePayload*)payload
{
    BCMessage* message = [[BCMessage alloc] init];
    message.command = command;
    message.payload = payload;
    NSString* encodedMessage = [JSONEncoder JSONValueOfObject:message];
    NSData* jsonData = [encodedMessage dataUsingEncoding:NSUTF8StringEncoding];
    
    [self.remoteSocket writeData:jsonData withTimeout:kDefaultSocketTimeout tag:0];
}

- (void)parseHandshakeCommand:(BCHandshake*)handshakeData
{
    // Initialize or refresh the rest of connectedDevice fields
    self.privateConnectedDevice.uniqueId = handshakeData.deviceUniqueId;
}

- (void)parseContentCommand:(BCMsgContent*)content
{
//    if ((self.privateConnectedDevice.name == nil) || (self.privateConnectedDevice.uniqueId == nil)) {
//        BCError* errorMsgPayload = [BCError errorWithCode:BCServiceFailNoHandshake];
//        [self sendCommand:kBCMsgErrorReceivingCommand withPayload:errorMsgPayload];
//        
//        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:failedToReceiveFromDevice:withError:)]) {
//            [self.delegate bonjourConnectivityService:self
//                        failedToReceiveFromDevice:self.connectedDevice
//                                        withError:BCServiceFailNoHandshake];
//        }
//        
//        return;
//    }

    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didReceiveString:fromDevice:)]) {
        [self.delegate bonjourConnectivityService:self
                             didReceiveString:content.contentString
                                   fromDevice:self.connectedDevice];
    }
    
    [self sendCommand:kBCMsgReceivedSuccessfullyCommand withPayload:[BCSuccess success]];
}

- (void)parseErrorReceivingCommand:(BCError*)errorData
{
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didShareWithDevice:withResult:)]) {
        [self.delegate bonjourConnectivityService:self didShareWithDevice:self.connectedDevice withResult:errorData.errorCode];
    }
}

- (void)parseReceivedSuccessfullyCommand
{
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didShareWithDevice:withResult:)]) {
        [self.delegate bonjourConnectivityService:self didShareWithDevice:self.connectedDevice withResult:BCServiceSuccess];
    }
}

#pragma mark NSNetServiceDelegate methods
- (void)netServiceWillPublish:(NSNetService *)netService
{
    DebugLog(@"Publishing network service...");
}

- (void)netServiceDidPublish:(NSNetService *)netService
{
    self.hostingDevice.addresses = [self inetAddressesFromArray:self.netService.addresses];

    DebugLog(@"Network service published.");
    if (![self.hostingDevice.name isEqualToString:self.netService.name]) {
        self.hostingDevice.name = self.netService.name;
        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didChangeHostingDeviceName:)]) {
            [self.delegate bonjourConnectivityService:self didChangeHostingDeviceName:self.hostingDevice.name];
        }
    }

    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityServiceDidPublish:)]) {
        [self.delegate bonjourConnectivityServiceDidPublish:self];
    }
}

- (void)netService:(NSNetService *)netService didNotPublish:(NSDictionary *)errorDict
{
    DebugLog(@"!!! ERROR! Network service failed to publish! Error: %@", errorDict);
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didFailToPublishWithError:)]) {
        [self.delegate bonjourConnectivityService:self didFailToPublishWithError:[[errorDict objectForKey:NSNetServicesErrorCode] intValue]];
    }
}

- (void)netServiceDidStop:(NSNetService *)netService
{
    DebugLog(@"Network service stopped.");
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityServiceDidStop:)]) {
        [self.delegate bonjourConnectivityServiceDidStop:self];
    }
}

- (void)netService:(NSNetService *)netService didNotResolve:(NSDictionary *)errorDict
{
    DebugLog(@"!!! ERROR! Network service %@ failed to resolve! Error: %@", netService.name, errorDict);
    
    [self.addedServicesPendingNotification removeObject:netService];
}

- (void)netService:(NSNetService *)netService didUpdateTXTRecordData:(NSData *)data
{
    DebugLog(@"Network service updated TXT record. Data: %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)netServiceDidResolveAddress:(NSNetService *)netService
{
    DebugLog(@"Resolved network address for service %@", netService.name);
    BCDevicePrivate* observedDevice = [self.storedDevices objectForKey:netService.name];
    NSArray* deviceInetAddresses = [self inetAddressesFromArray:netService.addresses];
    if (observedDevice == nil) {
        observedDevice = [[BCDevicePrivate alloc] initWithName:netService.name andAddresses:deviceInetAddresses];
        [self.storedDevices setObject:(BCDevice*)observedDevice forKey:netService.name];
        [self storedDevicesUpdated];
    } else {
        observedDevice.addresses = deviceInetAddresses;
    }

    [self.observedDevicesInternal setObject:observedDevice forKey:observedDevice.name];

    if (self.addedDevicesPendingNotification == nil) {
        self.addedDevicesPendingNotification = [[NSMutableArray alloc] init];
    }
    [self.addedDevicesPendingNotification addObject:observedDevice];
    
    [self.addedServicesPendingNotification removeObject:netService];
    
    if ((self.addedServicesPendingNotification.count == 0) && !self.moreObservedServicesComing) {
        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didObserveDevices:)]) {
            [self.delegate bonjourConnectivityService:self didObserveDevices:self.addedDevicesPendingNotification];
        }
        self.addedDevicesPendingNotification = nil;
    }
    
    // TODO: Send Handshake command to receive newly added device's uniqueId
}

- (void)netServiceWillResolve:(NSNetService *)netService
{
    DebugLog(@"Resolving network address for service %@...", netService.name);
}

#pragma mark NSNetServiceBrowserDelegate methods
- (void)netServiceBrowserWillSearch:(NSNetServiceBrowser *)aNetServiceBrowser
{
    DebugLog(@"WillSearch");
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityServiceWillStartObserving:)]) {
        [self.delegate bonjourConnectivityServiceWillStartObserving:self];
    }
}

- (void)netServiceBrowserDidStopSearch:(NSNetServiceBrowser *)browser
{
    DebugLog(@"Network service browser has stopped");
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityServiceDidStopObserving:)]) {
        [self.delegate bonjourConnectivityServiceDidStopObserving:self];
    }
    [self stopNetServiceBrowser];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser didNotSearch:(NSDictionary *)errorInfo
{
    DebugLog(@"!!! ERROR! Network service browser failed to search! Error: %@", errorInfo);
    [self stopNetServiceBrowser];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
           didFindService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	DebugLog(@"DidFindService: %@, moreComing=%@", netService.name, moreServicesComing ? @"Yes" : @"No");
    
    if ([netService.name isEqualToString:self.netService.name]) {
        DebugLog(@"Observed host service %@, don't handle it", self.netService.name);
        return;
    }
    
    self.moreObservedServicesComing = moreServicesComing;
    
    if (self.addedServicesPendingNotification == nil) {
        self.addedServicesPendingNotification = [[NSMutableArray alloc] init];
    }
    [self.addedServicesPendingNotification addObject:netService];
    
    netService.delegate = self;
    DebugLog(@"Resolving...");
    [netService resolveWithTimeout:5.0];
}

- (void)netServiceBrowser:(NSNetServiceBrowser *)browser
         didRemoveService:(NSNetService *)netService
               moreComing:(BOOL)moreServicesComing
{
	DebugLog(@"DidRemoveService: %@, moreComing: %@", netService.name, moreServicesComing ? @"Yes" : @"No");
    BCDevicePrivate* removedDevice = [self.observedDevicesInternal objectForKey:netService.name];
    
    if (removedDevice != nil)
    {
        [self.observedDevicesInternal removeObjectForKey:removedDevice.name];
        
        if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didRemoveDevices:)]) {
            if (self.removedDevicesPendingNotification == nil)
            {
                self.removedDevicesPendingNotification = [[NSMutableArray alloc] init];
            }
            [self.removedDevicesPendingNotification addObject:removedDevice];
            if (!moreServicesComing) {
                [self.delegate bonjourConnectivityService:self didRemoveDevices:self.removedDevicesPendingNotification];
                self.removedDevicesPendingNotification = nil;
            }
        }
    }
}

#pragma mark GCDAsyncSocketDelegate methods
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    if (self.remoteSocket != nil) {
        // Data transfer is currently in progress, refuse an incoming connection to let this data
        // tranfer to complete
        [newSocket disconnect];
        return;
    }
    
	DebugLog(@"Accepted new socket from %@:%hu", [newSocket connectedHost], [newSocket connectedPort]);
    self.remoteSocket = newSocket;
    self.isConnected = YES;
    // For incoming connections, initialize only 'addresses' field of the connectedDevice; the rest of
    // fields will be initialized later during handling of incoming handshake command
    self.privateConnectedDevice = [[BCDevicePrivate alloc] initWithAddresses:@[self.remoteSocket.localAddress]];
    self.connectedDevice = self.privateConnectedDevice;
    [self.remoteSocket readDataWithTimeout:-1 tag:0];
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didConnectToDevice:)]) {
        [self.delegate bonjourConnectivityService:self didConnectToDevice:self.connectedDevice];
    }
}

- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	DebugLog(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);

    self.isConnected = YES;
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didConnectToDevice:)]) {
        [self.delegate bonjourConnectivityService:self didConnectToDevice:self.connectedDevice];
    }

    [self.remoteSocket readDataWithTimeout:-1 tag:1];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    if (sock == self.remoteSocket) {
        DebugLog(@"Remote socket disconnected, error: %@", [err localizedDescription]);
        self.remoteSocket = nil;
        if (!self.isConnected) {
            [self connectToNextDeviceAddress];
        } else if (self.connectedDevice != nil) {
            self.addressesToConnect = nil;
            if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didDisconnectFromDevice:)]) {
                [self.delegate bonjourConnectivityService:self didDisconnectFromDevice:self.connectedDevice];
            }
        }
        self.isConnected = NO;
    } else if (sock == self.localSocket) {
        DebugLog(@"Local socket disconnected, error: %@", [err localizedDescription]);
        self.localSocket = nil;
    }
    
    self.connectedDevice = nil;
    self.privateConnectedDevice = nil;
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    BCMessage* receivedMessage = [JSONDecoder decodeWithData:data];
    DebugLog(@"BCService received message: %@", receivedMessage);
    
    if ([kBCMsgHandshakeCommand isEqualToString:receivedMessage.command]) {
        BCHandshake* handshakeData = (BCHandshake*)receivedMessage.payload;
        [self parseHandshakeCommand:handshakeData];
    } else if ([kBCMsgContentCommand isEqualToString:receivedMessage.command]) {
        BCMsgContent* content = (BCMsgContent*)receivedMessage.payload;
        [self parseContentCommand:content];
    } else if ([kBCMsgReceivedSuccessfullyCommand isEqualToString:receivedMessage.command]) {
        [self parseReceivedSuccessfullyCommand];
    }

    [self.remoteSocket readDataWithTimeout:-1 tag:0];
}

- (NSTimeInterval)socket:(GCDAsyncSocket *)sock shouldTimeoutWriteWithTag:(long)tag
                 elapsed:(NSTimeInterval)elapsed
               bytesDone:(NSUInteger)length
{
    if ([self.delegate respondsToSelector:@selector(bonjourConnectivityService:didShareWithDevice:withResult:)]) {
        [self.delegate bonjourConnectivityService:self didShareWithDevice:self.connectedDevice withResult:BCServiceFailTimeout];
    }
    return -1;
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{

}

@end
