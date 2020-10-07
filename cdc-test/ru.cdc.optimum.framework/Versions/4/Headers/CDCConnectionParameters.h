//
//  CDCConnectionParameters.h
//  csp
//
//  Created by Demin Dmitriy on 20.06.14.
//  Copyright (c) 2014 CDC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 <p>Server connection parameters</p>
 */
@interface CDCConnectionParameters : NSObject

/**
Allows to establish secure connection.
If <b>YES</b> - use TLS, default value is <b>NO</b>.
 */
@property(nonatomic, assign) BOOL useSecureConnection;

/**
 Read operation timeout in milliseconds. Default value is 60000 (1 minute).
 */
@property(nonatomic, assign) NSUInteger readTimeout;

/**
 Write operation timeout in milliseconds. Default value is 60000 (1 minute).
 */
@property(nonatomic, assign) NSUInteger writeTimeout;

/**
 Server name or IP address.
 */
@property(nonatomic, strong) NSString* hostName;

/**
 Server port.
 */
@property(nonatomic, assign) NSUInteger portNumber;

@end
