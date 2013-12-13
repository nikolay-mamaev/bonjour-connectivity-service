//
//  BCDevicePrivate.h
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/6/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import "BCDevice.h"

@interface BCDevicePrivate : BCDevice

@property (nonatomic, strong) NSArray* addresses;
@property (nonatomic, strong) NSUUID* uniqueId;

- (id)initWithAddresses:(NSArray*)addresses;
- (id)initWithName:(NSString*)name andAddresses:(NSArray*)addresses;

- (void)generateUniqueId;

@end
