//
//  CDCSynchronization.h
//  platform
//
//  Created by Demin Dmitriy on 17.02.14.
//  Copyright (c) 2014 CDC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import "CDCDatabase.h"
#import "CDCConnectionParameters.h"
#import "CDCCredentials.h"

#define CDC_PLATFORM_EVENT                   @"CDC_PLATFORM_EVENT"

#define CDC_PLATFORM_EVENT_INFO_TYPE         @"CDC_EVENT_INFO_TYPE"
#define CDC_PLATFORM_EVENT_INFO_ERROR        @"CDC_EVENT_INFO_ERROR"
#define CDC_PLATFORM_EVENT_INFO_GROUP         @"CDC_EVENT_INFO_GROUP"
#define CDC_PLATFORM_EVENT_INFO_STATUS         @"CDC_EVENT_INFO_STATUS"

#define CDC_PLATFORM_AUTH_RESULT             @"CDC_PLATFORM_AUTH_RESULT"
#define CDC_PLATFORM_USER_AUTH_RESULT        @"CDC_PLATFORM_USER_AUTH_RESULT"
#define CDC_PLATFORM_USER_AUTH_MESSAGE       @"CDC_PLATFORM_USER_AUTH_MESSAGE"

/**
 * Platrorm event codes
 */
typedef NS_ENUM(NSUInteger, CDCPlatformEvent) {
    /**
     * Synchronization start.
     */
    CDC_PLATFORM_SYNC_START,
    /**
     * Synchronization was successful.
     */
    CDC_PLATFORM_SYNC_SUCCESS,
    /**
     * Synchronization finished with error.
     */
    CDC_PLATFORM_SYNC_FAILED,
    /**
     * Error occured while synchronizing.
     */
    CDC_PLATFORM_ERROR,
    /**
     * Synchronization was finished for one group.
     */
    CDC_PLATFORM_SYNC_GROUP_FINISHED,
    /**
     * Exchange group error.
     */
    CDC_PLATFORM_SYNC_EXCH_GROUP_ERROR
};

/**
 * Authentication result codes
 */
typedef NS_ENUM(NSUInteger, CDCAuthenticateResult) {
    /**
     * Authentication was success.
     */
    SUCCESS,
    /**
     * Invalid credentials.
     */
    INVALID_CREDENTIALS,
    /**
     * Invalid server configuration.
     */
    INVALID_SERVER_CONFIGURATION,
    /**
     * Error occured while authenticating.
     */
    ERROR,
    /**
     * Cannot authenticate user.
     */
    FAIL,
    /**
     * Credentials hash does not exist.
     */
    OFFLINE_NOTEXISTS,
    /**
     * Cannot perform offline authentication.
     */
    OFFLINE_DENIED,
    /**
     * Credentials hash has expired.
     */
    OFFLINE_EXPIRED,
    /**
     * Authentication is disabled.
     */
    DISABLED
};

/**
<p>Synchronization class</p>
*/

@interface CDCSynchronization : NSObject

@property(nonatomic, strong) CDCConnectionParameters* connectionParameters;

/** Returns credentials instance used for authentication and synchronization. Default value is a credentials with empty strings for login and password
 */
@property(nonatomic, strong) CDCCredentials* credentials;

/** Returns shared instance.
 */
+(id)sharedSynchronization;

/** Starts synchronization session with provided <b>groups</b> one by one.
  Group names are case sensitive.
 
 <div><b>Example</b>
 <p>
 [[CDCSynchronization sharedSynchronization] execute:database forGroups:@[@"default"]];
 </p>
 </div>
 
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @param groups synchronization groups. May be empty, in that case method will attempt to synchonize <b>default</b> group
 
 */
-(void)execute:(FMDatabase*)database forGroups:(NSArray*)groups;

/** Performs authentication. Offline mode is also supported. If method cannot connect to the server, local credentials hash is verified.
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @param allowOffline offline mode

 <div><b>Example</b>
 <p>
 NSDictionary* result = [[CDCSynchronization sharedSynchronization] authenticate:database allowOffline:YES];
 </p>
 </div>
 
 */
-(NSDictionary*)authenticate:(FMDatabase*)database allowOffline:(BOOL)allowOffline;

/** Sets device token for Push notifications.
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @param pushDeviceId device token
 
 <div><b>Example</b>
 <p>
 [[CDCSynchronization sharedSynchronization] registerPushDeviceId:database devicePushId:deviceToken];
 </p>
 </div>
 
 */
-(void)registerPushDeviceId:(FMDatabase*)database devicePushId:(NSData*)pushDeviceId;

@end
