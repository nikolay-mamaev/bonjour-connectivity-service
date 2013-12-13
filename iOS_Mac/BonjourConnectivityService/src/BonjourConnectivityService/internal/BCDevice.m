//
//  BCDevice.m
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/1/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import "BCDevice.h"

@implementation BCDevice

@synthesize name = _name;
@synthesize isTrusted = _isTrusted;

- (id)init
{
    self = [super init];
    if (nil != self) {
        self.isTrusted = YES;
    }
    
    return self;
}

- (id)initWithName:(NSString*)name
{
    if (nil != [self init]) {
        self.name = name;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    if (nil != [self init]) {
        self.name = [coder decodeObjectForKey:@"name"];
        self.isTrusted = [[coder decodeObjectForKey:@"isTrusted"] boolValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.name forKey:@"name"];
    [coder encodeObject:[NSNumber numberWithBool:self.isTrusted] forKey:@"isTrusted"];
}

- (BOOL)isDeviceMetadataEqual:(BCDevice*)anotherDevice
{
    return ((self.name == anotherDevice.name) &&
            (self.isTrusted == self.isTrusted));
}

- (BOOL)isEqual:(id)object
{
    if ((nil == object) || ![object isKindOfClass:[BCDevice class]]) {
        return NO;
    }
    
    BCDevice* otherDevice = (BCDevice*)object;
    return (self.name == otherDevice.name);
}

@end
