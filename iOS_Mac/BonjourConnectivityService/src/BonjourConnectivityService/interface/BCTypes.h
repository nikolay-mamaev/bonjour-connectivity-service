//
//  BCTypes.h
//  BonjourConnectivityService
//
//  Created by Nikolay Mamaev on 6/1/13.
//  Copyright (c) 2013 Nikolay Mamaev. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    BCServiceSuccess = 0,
    BCServiceFailUnknownDevice,
    BCServiceFailCantConnect,
    BCServiceFailNoHandshake,
    BCServiceFailTimeout
} BCServiceResult;
