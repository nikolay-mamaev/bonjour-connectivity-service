//
//  BCMessage.m
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/6/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//


#import "BCMessage.h"


NSString* const kBCMsgHandshakeCommand = @"BCMsgHandshakeCommand";
NSString* const kBCMsgContentCommand = @"BCMsgContentCommand";
NSString* const kBCMsgErrorReceivingCommand = @"BCMsgErrorReceivingCommand";
NSString* const kBCMsgReceivedSuccessfullyCommand = @"BCMsgReceivedSuccessfullyCommand";


@implementation BCMessagePayload

- (id)initWithCoder:(NSCoder*)coder
{
    // This method must be implemented by descendants
    return [super init];
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    // This method must be implemented by descendants
}

@end


@implementation BCHandshake

@synthesize deviceName = _deviceName;
@synthesize deviceUniqueId = _deviceUniqueId;

+ (BCHandshake*)handshakeWithDevice:(BCDevicePrivate*)device
{
    return [[BCHandshake alloc] initWithDevice:device];
}

- (id)initWithDevice:(BCDevicePrivate*)device
{
    self = [super init];
    
    if (nil != self) {
        self.deviceName = device.name;
        self.deviceUniqueId = device.uniqueId;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    
    if (nil != self) {
        self.deviceName = [coder decodeObjectForKey:@"deviceName"];
        self.deviceUniqueId = [[NSUUID alloc] initWithUUIDString:[coder decodeObjectForKey:@"deviceUniqueId"]];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.deviceName forKey:@"deviceName"];
    [coder encodeObject:self.deviceUniqueId.UUIDString forKey:@"deviceUniqueId"];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"BCHandshake %p: deviceName='%@', deviceUniqueId='%@'", self, self.deviceName, [self.deviceUniqueId UUIDString]];
}

@end


@implementation BCMsgContent

@synthesize contentString = _contentString;

+ (BCMsgContent*)messageContentWithString:(NSString*)string
{
    return [[BCMsgContent alloc] initWithString:string];
}

- (id)initWithString:(NSString*)string
{
    self = [super init];
    
    if (nil != self) {
        self.contentString = string;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    
    if (nil != self) {
        self.contentString = [coder decodeObjectForKey:@"contentString"];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.contentString forKey:@"contentString"];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"BCMsgContent %p: content='%@'", self, self.contentString];
}

@end


@implementation BCError

@synthesize errorCode = _errorCode;

+ (BCError*)errorWithCode:(BCServiceResult)code
{
    return [[BCError alloc] initWithCode:code];
}

- (id)initWithCode:(BCServiceResult)code
{
    self = [super init];
    
    if (nil != self) {
        self.errorCode = code;
    }
    
    return self;
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    
    if (nil != self) {
        self.errorCode = [[coder decodeObjectForKey:@"errorCode"] intValue];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:[NSNumber numberWithInt:self.errorCode] forKey:@"errorCode"];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"BCError %p: errorCode='%d'", self, self.errorCode];
}

@end


@implementation BCSuccess

+ (BCSuccess*)success
{
    return [[BCSuccess alloc] init];
}

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super initWithCoder:coder];
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"BCSuccess %p", self];
}

@end

@implementation BCMessage

@synthesize command = _command;
@synthesize payload = _payload;

- (id)initWithCoder:(NSCoder*)coder
{
    self = [super init];
    
    if (nil != self) {
        self.command = [coder decodeObjectForKey:@"command"];
        self.payload = [coder decodeObjectForKey:@"payload"];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder*)coder
{
    [coder encodeObject:self.command forKey:@"command"];
    [coder encodeObject:self.payload forKey:@"payload"];
}

- (NSString*)description
{
    return [NSString stringWithFormat:@"BCMessage %p: command='%@', payload='%@'", self, self.command, self.payload];
}

@end
