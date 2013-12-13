//
//  BCMessage.h
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/6/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BCDevicePrivate.h"
#import "BCTypes.h"


extern NSString* const kBCMsgHandshakeCommand;
extern NSString* const kBCMsgContentCommand;
extern NSString* const kBCMsgErrorReceivingCommand;
extern NSString* const kBCMsgReceivedSuccessfullyCommand;


@interface BCMessagePayload : NSObject <NSCoding>

@end

@interface BCError : BCMessagePayload

@property (nonatomic) BCServiceResult errorCode;

+ (BCError*)errorWithCode:(BCServiceResult)code;

- (id)initWithCode:(BCServiceResult)code;

@end

@interface BCSuccess : BCMessagePayload

+ (BCSuccess*)success;

@end

@interface BCHandshake : BCMessagePayload

@property (nonatomic, strong) NSString* deviceName;
@property (nonatomic, strong) NSUUID* deviceUniqueId;

+ (BCHandshake*)handshakeWithDevice:(BCDevicePrivate*)device;

- (id)initWithDevice:(BCDevicePrivate*)device;

@end


@interface BCMsgContent : BCMessagePayload

@property (nonatomic, strong) NSString* contentString;

+ (BCMsgContent*)messageContentWithString:(NSString*)string;

- (id)initWithString:(NSString*)string;

@end


@interface BCMessage : NSObject <NSCoding>

@property (nonatomic, strong) NSString* command;
@property (nonatomic, strong) BCMessagePayload* payload;

@end
