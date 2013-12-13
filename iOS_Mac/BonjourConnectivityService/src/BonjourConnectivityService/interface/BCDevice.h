//
//  BCDevice.h
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/1/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCDevice : NSObject <NSCoding>

@property (nonatomic, strong) NSString* name;
@property (nonatomic) BOOL isTrusted; // For phase 1, it's always YES

- (id)init;
- (id)initWithName:(NSString*)name;

// This method compares all device metadata fields (like name, uniqueId, isTrusted, etc)
// Note:
// Unlike isDeviceMetadataEqual:, the 'standard' isEqual: method compares uniqueId only.
- (BOOL)isDeviceMetadataEqual:(BCDevice*)anotherDevice;

@end
