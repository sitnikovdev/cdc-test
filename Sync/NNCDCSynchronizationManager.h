//
//  NNDBManager.h
//  NorNickel
//
//  Created by Privezentsev Yury on 26.09.16.
//  Copyright © 2016 baccasoft. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ru.cdc.optimum/csp.h>
#import <ru.cdc.optimum/CDCPlatformVariables.h>
#import <ru.cdc.optimum/FMDatabaseQueue.h>
#import "NNCDCConstants.h"

@interface NNCDCSynchronizationManager : NSObject
    @property(assign, atomic, getter=isSynchronizationInProgress) BOOL synchronizationInProgress;
    @property(strong, atomic) NSString *currentSynchronizationGroup;
    @property (assign, atomic) BOOL hasPendingInstructions; // Need this to know if there are not synchronized created Instructions
    @property (assign, atomic) BOOL databaseCreated;
    @property (assign, atomic) BOOL waitForSyncEndOnLogout;

    + (instancetype)sharedManager;

    #pragma mark - Setup
    - (void)createDataBase;
    - (void)removeDataBase;
    - (void)setup;
    - (void)clearOnLogOut;


    #pragma mark - DataBase Getter
    - (FMDatabaseQueue *)dbQueue;


    #pragma mark - Util
    - (BOOL)connected;
    - (BOOL)checkConnection;
    - (BOOL)taskListGroupsSynchronizationInProgress;
    - (BOOL)waitingGroupsSynchronizationInProgress;
    - (BOOL)orderTreeGroupSynchronizationInProgress;
    - (BOOL)myCoadjutorSyncInProgress;
    - (BOOL)syncIsInProgressForGroup:(NSString *)group;


    #pragma mark - Platform Variables
    - (void)setLoginPlatformVariable:(NSString *)login;
    - (void)setUserIdPlatformVariable:(int)userId;
    - (void)setTreeLevelIdPlatformVariable:(NSInteger)treeLevelId;
    - (void)setDocumentTreeLevelIdPlatformVariable:(NSInteger)documentIdentifier;


    #pragma mark - Credentials
    - (void)setupCredentialsWithLogin:(NSString *)login password:(NSString *)password;


    #pragma mark - Authentication
    - (void)authenticateWithHashedLogin:(NSString *)hashedLogin;
    - (void)authenticateWithEncryptedLogin:(NSString *)encryptedLogin encryptedPassword:(NSString *)encryptedPassword logoutOnFail:(BOOL)logoutOnFail;


    #pragma mark - Sync
    - (void)syncWithTasksGroup;
    - (void)syncWithAuthGroup;
    - (void)syncWithTimerGroup;
    - (void)syncFirstTime;
    - (void)syncWithOrderTreeGroup;
    - (void)syncWithDocumentTreeGroup;
    - (void)syncWithExecutionGroup;
    - (void)syncWithExecutionStartSyncGroup;
    - (void)syncWithExecutionWaitForSyncGroup;
    - (void)syncWithWaitingForUpdateGroup;
    - (void)syncWithLogs;
    - (void)syncWithNotificationsUpdate;
    - (void)syncWithMyCoadjutorUpdate;
    - (void)syncWithTaskLocking;
    - (BOOL)waitingSyncForGroup:(NSString *)group;
    - (void)syncWithGroups:(NSArray *)groups;


    #pragma mark - Push notifications
    - (void)registerForRemoteNotifications:(NSData *)deviceToken;


    #pragma mark - Private
    - (void)startExecutionWaitingTimer;
    - (void)stopExecutionWaitingTimer;
    - (void)checkExecutionWaitingTimer;

@end
