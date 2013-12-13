//
//  BCDevicePrivate.m
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/6/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import "BCDevicePrivate.h"

@implementation BCDevicePrivate

@synthesize addresses = _addresses;
@synthesize uniqueId = _uniqueId;

- (id)initWithName:(NSString*)name andAddresses:(NSArray*)addresses
{
    self = [super initWithName:name];
    if (nil != self) {
        self.addresses = addresses;
    }
    
    return self;
}

- (id)initWithAddresses:(NSArray*)addresses
{
    self = [super init];
    if (nil != self) {
        self.addresses = addresses;
    }
    
    return self;
}

- (void)generateUniqueId
{
    self.uniqueId = [NSUUID UUID];
}

- (BOOL)isEqual:(id)object
{
    return [super isEqual:object];
    // TODO: Uncomment when uniqueId usage (i.e. Handshake command) is implemented
//    if ((nil == object) || ![object isKindOfClass:[BCDevicePrivate class]]) {
//        return NO;
//    }
//    
//    BCDevicePrivate* otherDevice = (BCDevicePrivate*)object;
//    return [self.uniqueId.UUIDString isEqualToString:otherDevice.uniqueId.UUIDString];
}

@end
