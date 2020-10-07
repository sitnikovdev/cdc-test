//
//  NNCDCSynchronizationManager.m
//  NorNickel
//
//  Created by Privezentsev Yury on 26.09.16.
//  Copyright © 2016 baccasoft. All rights reserved.
//

#import "NNCDCSynchronizationManager.h"

#import "NNReachabilityService.h"
#import "NNCDCConstants.h"
#import "NNWaitingSynchState.h"

#import "NNAccountSettingsHelper.h"
#import "NNSynchronizationTimer.h"

#import "NNDBManager.h"
#import "NNDBManager+Executions.h"

#import "Reachability.h"
#import "NNSynchronizationLogger.h"
#import "NNDBManager+Logging.h"
#import "NSString+NNString.h"

#import "NNAlertConstants.h"
#import "NNCDCSynchronizationQueue.h"
#import "NNSynchronizationSessionService.h"
#import "NNSegmentationIdentifiersStorage.h"

#import "NNApplicationSettings.h"
#import "NNWaitingSynchServerResponseMessage.h"
#import "NNMessageStatusFromServerService.h"

static NSString *const CDC_dataBaseFileName = @"cdc_nornikel_db.sqlite";

static NSString *const CDCLoginPlatformVariable = @"@login";
static NSString *const CDCUserIdPlatformVariable = @"@userId";
static NSString *const CDCTreeLevelPlatformVariable = @"@treeLevelId";
static NSString *const CDCDocumentTreeLevelPlatformVariable = @"@documentIds";
static NSString *const CDCUserIdForExchangePlatformVariable = @"@userIdForExchange";
static NSString *const CDCUserIdsForSegmentationPlatformVariable = @"@userIdsForSegmentation";

static NSNotification *noInternetConnectionNotification = nil;
static NSNotification *serverUnreachableNotification = nil;

static dispatch_queue_t databaseQueue;

@interface NNCDCSynchronizationManager () <NNSynchronizationSessionServiceDelegate>
    @property (assign, atomic) BOOL logoutOnFail;
    @property (strong, atomic) FMDatabase *dataBase;
    @property (strong, atomic) FMDatabaseQueue *databaseQueue;
    //@property (strong, atomic) Reachability *reachability; //TODO: перенести все в ReachabilityService сервис
    @property (strong, atomic) NNCDCSynchronizationQueue *synchronizationQueue;
    @property (assign, atomic) BOOL ignoreNetworkConditionMessages;
    @property (strong, nonatomic) NNSynchronizationSessionService *sessionService;
    @property (strong, nonatomic) NNMessageStatusFromServerService *messageStatusFromServerService;

    @property (strong, nonatomic) NSTimer *executionWaitingTimer; // таймер для повторения @"ExecutionWaitForSync"
@end


@implementation NNCDCSynchronizationManager

+(instancetype)sharedManager {
    static NNCDCSynchronizationManager *sharedManager = nil;
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedManager = [[NNCDCSynchronizationManager alloc] init];
        databaseQueue = dispatch_queue_create("ru.baccasoft.NorNickel.database", 0);
    });
    
    return sharedManager;
}

- (instancetype)init {
    self = [super init];
    
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDatabaseRemovedOnLogoutNotification) name:NNSynchronizationManagerDidRemoveDataBaseNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleDidEndSynchronizationsOnLogout) name:NNSynchronizationManagerDidEndSynchronizationsBeforeLogoutNotification object:nil];

        self.databaseCreated = NO;
        self.hasPendingInstructions = NO;
        self.currentSynchronizationGroup = [[NSString alloc] init];
        self.messageStatusFromServerService = [[NNMessageStatusFromServerService alloc] init];

        [self setupReachability];
        [self setupNotifications];
    }
    
    return self;
}

#pragma mark - Setup

- (void)setupReachability {
    __weak typeof(self) weakSelf = self;
    NNReachabilityService.instance.obtainReachability.reachabilityBlock = ^(Reachability *reachability, SCNetworkConnectionFlags flags) {
                        if (reachability.isReachable && weakSelf.ignoreNetworkConditionMessages) {
                            weakSelf.ignoreNetworkConditionMessages = NO;
                        } };
}

- (void)setupNotifications {
    noInternetConnectionNotification = [NSNotification notificationWithName:NNNoInternetConnectionNotification object:nil userInfo:@{
            NNAlertNotificationTypeKey: NNAlertNotificationTypeNoInternetConnection,
            NNAlertNotificationMessageKey: NNAlertNotificationNoInternetConnectionMessage
    }];
    serverUnreachableNotification = [NSNotification notificationWithName:NNServerUnreachableNotification object:nil userInfo:@{
            NNAlertNotificationTypeKey: NNAlertNotificationTypeServerUnreachable,
            NNAlertNotificationMessageKey: NNAlertNotificationServerUnreachableMessage
    }];
}

-(void)createDataBase {
    
    dispatch_async(databaseQueue, ^{
        
        NSString* pathForScheme = [[NSBundle mainBundle] pathForResource:[[NNApplicationSettings defaultSettings] XMLSchemeFileName] ofType:@"xml"];
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString* documentsPath = paths[0];
        NSLog(@"Database before initialization: %@", [self.dataBase description]);
        CDCDatabase *dataBase = [[CDCDatabase alloc] init];
        self.dataBase = [dataBase createOrOpenDatabaseByXml:pathForScheme
                                                       path:[documentsPath stringByAppendingPathComponent:CDC_dataBaseFileName]];

        NSLog(@"Initialized Database: %@", [self.dataBase description]);
        dispatch_sync(dispatch_get_main_queue(), ^{
            NSLog(@"DataBase created");
            self.databaseCreated = YES;
            self.sessionService = [[NNSynchronizationSessionService alloc] initWithDatabaseQueue:[self dbQueue]];
            self.sessionService.delegate = self;
            [[NSNotificationCenter defaultCenter] postNotificationName:NNSynchronizationManagerDidCreateDataBaseNotification object:nil];
        });
    });
}

-(void)removeDataBase {

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString* documentsPath = paths[0];
    NSString *dbFile = [documentsPath stringByAppendingPathComponent:CDC_dataBaseFileName];

    NSLog(@"Database: %@", [self.dataBase description]);
    if ([self.dataBase close]) {
        NSLog(@"Database closed with success");
    } else {
        NSLog(@"Database not closed");
    }

    self.databaseQueue = nil;
    self.dataBase = nil;
    self.synchronizationQueue = nil;

    [[NSFileManager defaultManager] removeItemAtPath:dbFile error:nil];

    if ([[NSFileManager defaultManager] fileExistsAtPath:dbFile]) {
        NSLog(@"Database file exists at path: %@", dbFile);
    } else {
        NSLog(@"No database file at path: %@", dbFile);
    }

    NSLog(@"DataBase removed");
    NSLog(@"Database: %@", [self.dataBase description]);
    self.databaseCreated = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:NNSynchronizationManagerDidRemoveDataBaseNotification object:nil];
}

-(void)setup {

    if ([[NSUserDefaults standardUserDefaults] boolForKey:NNUserDidLogoutAndThenDidExitApplicationKey]) {
        NSLog(@"start cleaning after logout and exit");
        [self removeDataBase];
    } else {
        [self createDataBase];
        [self setupConnectionParameters];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleSynchronizationNotification:) name:CDC_PLATFORM_EVENT object:nil];
    }
}

-(void)setupConnectionParameters {
    
    CDCConnectionParameters *cp = [[CDCConnectionParameters alloc] init];
    cp.hostName = [[NNApplicationSettings defaultSettings] serverAddress];
    cp.portNumber = [[NNApplicationSettings defaultSettings] serverSynchronizationPort];
    cp.writeTimeout = 6*60*1000;
    cp.readTimeout = 6*60*1000;
    
    cp.useSecureConnection = YES;

    [[CDCSynchronization sharedSynchronization] setConnectionParameters:cp];
}

-(void)clearOnLogOut {
    dispatch_async(databaseQueue, ^{
        [self.synchronizationQueue clear];
        if (!self.waitForSyncEndOnLogout && self.databaseQueue) {
            [self setLoginPlatformVariable:@""];
            [self setUserIdPlatformVariable:-1];
            self.synchronizationInProgress = NO;
            [[NSNotificationCenter defaultCenter] removeObserver:self name:CDC_PLATFORM_EVENT object:nil];
            [[NSUserDefaults standardUserDefaults] setObject:nil forKey:CDCLastUserGroupSynchronizationDateKey];
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:CDCFirstSynchronizationKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self removeDataBase];
        }
    });
}

#pragma mark - DataBase Getter

-(FMDatabaseQueue *)dbQueue {
    if (!_databaseQueue && self.databaseCreated) {
        _databaseQueue = [FMDatabaseQueue databaseQueueWithPath:[self.dataBase databasePath]];
    }
    return _databaseQueue;
}

#pragma mark - Notification Handlers

-(void)handleDatabaseRemovedOnLogoutNotification {
    [[NSUserDefaults standardUserDefaults] setBool:NO forKey:NNUserDidLogoutAndThenDidExitApplicationKey];
    [[NSUserDefaults standardUserDefaults] synchronize];
    NSLog(@"Set NO for key NNUserDidLogoutAndThenDidExitApplicationKey");
    [self setup];
}

-(void)handleDidEndSynchronizationsOnLogout {
    [self clearOnLogOut];
}

#pragma mark - Segmentation

- (void)setupSegmentation {

//    NSLog(@"%s", __PRETTY_FUNCTION__);

    // Синхронизация по всем пользователям
    NSString *variableValue = NNEmptyString;

    [self saveInDatabasePushDeviceToken];
    [self setSegmentationId:variableValue];
    [self setVariable:CDCUserIdForExchangePlatformVariable value:variableValue];
}

- (void)setSegmentationId:(NSString *)segmentationId {

    NNSegmentationIdentifiersStorage *identifiersStorage = [[NNSegmentationIdentifiersStorage alloc] init];
    BOOL hasChanges;

    // Если передается пустой идентификатор, значит нужно стереть все идентификаторы
    if ([segmentationId length] > 0) {
        hasChanges = [identifiersStorage saveNewIdentifier:segmentationId];
    } else {
        hasChanges = [[identifiersStorage currentIdentifiers] length] > 0;
        [identifiersStorage clearAll];
    }

    if (hasChanges) {
        NSString *identifiers = [identifiersStorage currentIdentifiers];
        [self setVariable:CDCUserIdsForSegmentationPlatformVariable value:identifiers];
    }

}

#pragma mark - Notification Senders

- (void)postSynchronizationNotificationName:(NSString *)notificationName forGroup:(NSString *)groupName synchronizationStatus:(NNSynchronizationStatus)status errorType:(NSString *)errorType {

    errorType = (errorType) ?: NNEmptyString;
    groupName = (groupName) ?: NNEmptyString;

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:notificationName object:nil userInfo:@{
                NNSynchronizationManagerSynchronizationGroupUserInfoKey: groupName,
                NNSynchronizationManagerSynchronizationStatusUserInfoKey: @(status),
                NNSynchronizationManagerSynchronizationErrorTypeUserInfoKey: errorType
        }];
    });
}

- (void)postErrorNotificationsForErrorType:(NSString *)errorType {

    if (self.connected) {
        if (![errorType isEqualToString:NNSynchronizationManagerInvalidCredentialsError] &&
                ![errorType isEqualToString:NNSynchronizationManagerSessionTokenExpiredError]) {
//                [self postServerUnreachableNotification];
            [self postNoInternetConnectionNotification];
        }
    } else {
        [self postNoInternetConnectionNotification];
        [self.synchronizationQueue clear];
        self.synchronizationInProgress = NO;
        [NNSynchronizationLogger logDebugInfoForGroupName:self.currentSynchronizationGroup mesage:@"No internet connection"];
    }
}

- (void)postNoInternetConnectionNotification {
    if (!self.ignoreNetworkConditionMessages) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[NSNotificationCenter defaultCenter] postNotification:noInternetConnectionNotification];
        });
        self.ignoreNetworkConditionMessages = YES;
    }
}

- (void)postServerUnreachableNotification {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotification:serverUnreachableNotification];
    });
}


#pragma mark - Util

- (BOOL)connected {
    return [NNReachabilityService.instance isReachable];
}

-(BOOL)checkConnection {
    if (!self.connected) {
        [self postNoInternetConnectionNotification];
        [NNSynchronizationLogger logDebugInfoForGroupName:self.currentSynchronizationGroup mesage:@"No internet connection"];
    }
    return self.connected;
}

- (BOOL)taskListGroupsSynchronizationInProgress {
    if (self.synchronizationInProgress) {
        return ([self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_Execution]            ||
                [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_TaskUpdate]           ||
                [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_WaitingForUpdate]     ||
                [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_Logs]
               );
    } else {
        return NO;
    }
}

- (BOOL)waitingGroupsSynchronizationInProgress {
    NNWaitingSynchState currentWaitingSynchState = [[NSUserDefaults standardUserDefaults] integerForKey:NNExecutionWaitForSyncInAction];
    
    return [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_ExecutionStartSync]   ||
           [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_ExecutionWaitForSync]
           || (currentWaitingSynchState != NNWaitingSynchStateNone);
}

- (BOOL)orderTreeGroupSynchronizationInProgress {
    if (self.synchronizationInProgress) {
        return [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_OrderTree];
    } else {
        return NO;
    }
}

- (BOOL)authSyncInProgress {
    if (self.synchronizationInProgress) {
        return [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_Auth];
    }
    return NO;
}

- (BOOL)myCoadjutorSyncInProgress {
    return [self syncIsInProgressForGroup:CDC_syncGroup_MyCoadjutorUpdate];
}

- (BOOL)syncIsInProgressForGroup:(NSString *)group {
    if (self.synchronizationInProgress) {
        return [self.currentSynchronizationGroup isEqualToString:group] || ([self.synchronizationQueue.currentQueue containsObject:group]);
    } else {
        return NO;
    }
}

- (BOOL)waitingSyncForGroup:(NSString *)group {
    return [self.synchronizationQueue.currentQueue containsObject:group];
}

#pragma mark - Platform Variables

-(void)setLoginPlatformVariable:(NSString*)login {
    [self setVariable:CDCLoginPlatformVariable value:login];
}

-(void)setUserIdPlatformVariable:(int)userId {
    [self setVariable:CDCUserIdPlatformVariable value:[NSString stringWithFormat:@"%i", userId]];
}

- (void)setTreeLevelIdPlatformVariable:(NSInteger)treeLevelId {
    [self setVariable:CDCTreeLevelPlatformVariable value:[NSString stringWithFormat:@"%ld", (long)treeLevelId]];
}

- (void)setDocumentTreeLevelIdPlatformVariable:(NSInteger)documentIdentifier {

    [self setVariable:CDCDocumentTreeLevelPlatformVariable value:[@(documentIdentifier) stringValue]];
}

- (void)setVariable:(NSString *)variableName value:(NSString *)value {

    [[self dbQueue] inDatabase:^(FMDatabase *db) {

        CDCPlatformVariables *pv = [CDCPlatformVariables platformVariables:db];
        [pv setString:variableName stringValue:value];
        [pv commit:db];

    }];

}

#pragma mark - Credentials

-(void)setupCredentialsWithLogin:(NSString *)login password:(NSString *)password {
    CDCCredentials *credentials = [[CDCCredentials alloc] init];
    credentials.login = login;
    credentials.password = password;
    [[CDCSynchronization sharedSynchronization] setCredentials:credentials];
}

-(BOOL)credentialsAreEmpty {
     return ([[[CDCSynchronization sharedSynchronization] credentials].login isEqualToString:NNEmptyString] && [[[CDCSynchronization sharedSynchronization] credentials].password isEqualToString:NNEmptyString]);
}

-(void)setupCredentialsWithEmptyLoginAndTokenIfCredentialsAreEmpty {
    if ([self credentialsAreEmpty]) {
        [self setupCredentialsWithLogin:NNEmptyString
                               password:[NNDBManager currentUserTokenFromLoginTable]];
    }
}

#pragma mark - Authentication

-(void)authenticateWithHashedLogin:(NSString *)hashedLogin {
    [self setLoginPlatformVariable:hashedLogin];
    [self authenticateWithEncryptedLogin:[NNAccountSettingsHelper currentUserName] encryptedPassword:[NNAccountSettingsHelper currentUserPassword] logoutOnFail:YES];
}

-(void)authenticateWithEncryptedLogin:(NSString *)encryptedLogin encryptedPassword:(NSString *)encryptedPassword logoutOnFail:(BOOL)logoutOnFail {
    _logoutOnFail = logoutOnFail;
    [self setupCredentialsWithLogin:encryptedLogin password:encryptedPassword];
    [self syncWithAuthGroup];
}

#pragma mark - SYNCHRONIZATION
#pragma mark - Groups Queue

-(void)syncWithPendingSynchronizationGroup {

    NSString *groupName = [self.synchronizationQueue dequeueNextSynchronizationGroup];
    if (groupName) {
        
        [self.sessionService handleSessionForSynchronizationGroupName:groupName];
        self.currentSynchronizationGroup = groupName;
        [self startSyncWithGroups:@[self.currentSynchronizationGroup]];
        self.synchronizationInProgress = YES;

    } else {
        self.synchronizationInProgress = NO;
    }

}

#pragma mark - Synchronization events handler

-(void)handleSynchronizationNotification:(NSNotification *)notification {

    NSInteger result = [[notification.object objectForKey:CDC_PLATFORM_EVENT_INFO_TYPE] integerValue];

    switch (result) {
        case CDC_PLATFORM_SYNC_START: { // Synchronization start.
            NSLog(@"Synchronization start for group: %@", self.currentSynchronizationGroup);
            [NNSynchronizationLogger logStartForGroupName:self.currentSynchronizationGroup message:nil];
            [self postSynchronizationNotificationName:NNSynchronizationManagerSynchronizationNotification forGroup:[self.currentSynchronizationGroup copy] synchronizationStatus:NNSynchronizationStatusStarted errorType:nil];

            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NNTasksInDatabaseDidUpdateNotification object:nil];
            });
            
            break;
        }
        case CDC_PLATFORM_SYNC_SUCCESS: { // Synchronization was successful.
            NSLog(@"Synchronization success for group: %@", self.currentSynchronizationGroup);

            [NNSynchronizationLogger logSuccessForGroupName:self.currentSynchronizationGroup message:nil];
            
            if ([self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_TaskUpdate]) {
                [NNDBManager logDataIntegrityCheck];

                // Сохраняем просинхронизированные идентификаторы сегментации
                [self saveSynchronizedSegmentationIdentifiers];

            }
            
            if ([self taskListGroupsSynchronizationInProgress]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:NNTasksInDatabaseDidUpdateNotification object:nil];
                });
            }

            
            if ([self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_Execution]) {
                [self stopExecutionWaitingTimer];
                
                [NNDBManager deleteSyncedWithSuccessExecutions];
                if (self.connected) {
                    [NNDBManager checkSynchronizationsErrors];
                }
                
                // Принимаю решение о перезапуске ExecutionStartSync группы
                if ( [[NSUserDefaults standardUserDefaults] integerForKey:NNExecutionWaitForSyncInAction] == NNWaitingSynchStateNeedToRunAgain ) {
                    
                    [[NSUserDefaults standardUserDefaults] setInteger:NNWaitingSynchStateNone forKey:NNExecutionWaitForSyncInAction];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                    [self syncWithExecutionStartSyncGroup];
                    
                } else {
                    [[NSUserDefaults standardUserDefaults] setInteger:NNWaitingSynchStateNone forKey:NNExecutionWaitForSyncInAction];
                    [[NSUserDefaults standardUserDefaults] synchronize];
                }
            }

            
            if ([self authSyncInProgress]) {
                
                // Костыль, который устанавливает настройку сегментации списка задач
                // на синхронизацию только для определнных идентификторов пользователя
                NSInteger userID = [NNDBManager currentUserIDFromLoginTable];
                [NNAccountSettingsHelper setCurrentUserID:userID];
                if ([[[NNApplicationSettings defaultSettings] onlyCurrentUserTaskSynchronizationModeUsers] containsObject:@(userID)]) {
                    [NNAccountSettingsHelper setTaskSynchronizationMode:@(NNTaskSynchronizationModeOnlyCurrentUser)];
                }
                
                [self setupCredentialsWithLogin:NNEmptyString
                                       password:[NNDBManager currentUserTokenFromLoginTable]];
            }

            
            
            self.synchronizationInProgress = NO;

            
            __block NSString * blockCurrentSyncGroup = [self.currentSynchronizationGroup copy];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:NNCoadjutorTableDidUpdateNotification object:nil userInfo:@{NNSynchronizationGroupUserInfoKey: blockCurrentSyncGroup}];
            });
            
            
            if ( [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_ExecutionStartSync] ) {
                [self startExecutionWaitingTimer];
            }
            
            if ( [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_ExecutionWaitForSync] ) {
                switch ( [self.messageStatusFromServerService readMessageForGroup:(NSString *)CDC_syncGroup_ExecutionStartSync] ) {
                        case NNWaitingSynchServerResponseMessageWaiting:
                            [self startExecutionWaitingTimer];
                            break;

                        case NNWaitingSynchServerResponseMessageOk:
                            [self.messageStatusFromServerService removeGroupFromMap:CDC_syncGroup_ExecutionStartSync];
                            NSLog(@"Get respone with OK status from server");
                            NSLog(@"Remove ExecutionStartSync group from map");
                            [self startExecutionResponseTimer];
                            break;
                        case NNWaitingSynchServerResponseMessageError:
                        case NNWaitingSynchServerResponseMessageEmpty:
                            NSLog(@"Get respone with Error status from server");
                            [self.messageStatusFromServerService removeGroupFromMap:CDC_syncGroup_ExecutionStartSync];
                            [self startExecutionResponseTimer];
                            break;
                }
            }
            
            [self postSynchronizationNotificationName:NNSynchronizationManagerSynchronizationNotification
                                             forGroup:[self.currentSynchronizationGroup copy]
                                synchronizationStatus:NNSynchronizationStatusEndedWithSuccess
                                            errorType:nil];
            
            // Временное решение для корректной синхронизации групп, которые не входят в список сессионыых групп
            if (![self taskListGroupsSynchronizationInProgress]) {
                [self syncWithPendingSynchronizationGroup];
            }

            if (self.waitForSyncEndOnLogout) {
                self.waitForSyncEndOnLogout = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:NNSynchronizationManagerDidEndSynchronizationsBeforeLogoutNotification object:nil userInfo:nil];
                });
            }
            [NNDBManager deleteAllLogs];
            
            break;
        }
        case CDC_PLATFORM_SYNC_FAILED: { // Synchronization finished with error.
            NSLog(@"Synchronization failed for group: %@", self.currentSynchronizationGroup);

        } // No need to "break;" for this case!!
        case CDC_PLATFORM_SYNC_EXCH_GROUP_ERROR: // непонятная ошибка
        case CDC_PLATFORM_ERROR: { // Error occured while synchronizing.
            NSLog(@"Synchronization error for group: %@", self.currentSynchronizationGroup);
            
            if ( [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_Execution] || [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_ExecutionStartSync] || [self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_ExecutionWaitForSync])
            {
                [[NSUserDefaults standardUserDefaults] setInteger:NNWaitingSynchStateNone forKey:NNExecutionWaitForSyncInAction];
                [[NSUserDefaults standardUserDefaults] synchronize];
                
                [self stopExecutionWaitingTimer];
            }
            
            if ([self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_Logs]) {
                self.synchronizationInProgress = NO;
                break;
            }
            
            dispatch_async(databaseQueue, ^{
                [NNSynchronizationLogger logFailForGroupName:self.currentSynchronizationGroup message:[notification.object[CDC_PLATFORM_EVENT_INFO_ERROR] description]];
            });
            
            if ([self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_TaskUpdate]) {
                [NNDBManager logDataIntegrityCheck];
                // Сохраняем просинхронизированные идентификаторы сегментации
                [self saveSynchronizedSegmentationIdentifiers];
            }
            NSString *errorType = [self handleErrorInfo:notification.object[CDC_PLATFORM_EVENT_INFO_ERROR]];
            [self handleSynchronizationError:errorType];

            if (self.waitForSyncEndOnLogout) {
                self.waitForSyncEndOnLogout = NO;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:NNSynchronizationManagerDidEndSynchronizationsBeforeLogoutNotification object:nil userInfo:nil];
                });
            }

            break;
        }
        case CDC_PLATFORM_SYNC_GROUP_FINISHED: { // Synchronization was finished for one group.
            NSLog(@"Synchronization finished for group: %@", self.currentSynchronizationGroup);
            break;
        }
        default:
            break;
    }

}

- (void)saveSynchronizedSegmentationIdentifiers {

    __block NSString *identifiers = [[NSString alloc] init];
    [[self dbQueue] inDatabase:^(FMDatabase *db) {

        CDCPlatformVariables *pv = [CDCPlatformVariables platformVariables:db];
        identifiers = [pv getString:CDCUserIdsForSegmentationPlatformVariable];

    }];

    NNSegmentationIdentifiersStorage *identifiersStorage = [[NNSegmentationIdentifiersStorage alloc] init];
    [identifiersStorage saveSynchronizedIdentifiers:identifiers];
}

-(NSString *)handleErrorInfo:(id)error {
    if ([error isKindOfClass:[NSError class]]) {
        NSError *syncError = (NSError *)error;
        
        if ([syncError.domain isEqualToString:@"CDCPlatform"]) {
            NSDictionary *info = syncError.userInfo;
            
            NSNumber *authResult = [info valueForKey:CDC_PLATFORM_AUTH_RESULT];
            NSNumber *authErrorCode = [info valueForKey:CDC_PLATFORM_USER_AUTH_RESULT];
            BOOL isTokenSession = [[[CDCSynchronization sharedSynchronization] credentials].login isEqualToString:@""];

            if (([authResult intValue] == INVALID_CREDENTIALS || [authResult intValue] == ERROR) && [authErrorCode intValue] == 1) {
                return isTokenSession ? NNSynchronizationManagerSessionTokenExpiredError : NNSynchronizationManagerInvalidCredentialsError;
            }
        }
        return NNEmptyString;

    } else {
        return NNEmptyString;
    }
}

- (void)handleSynchronizationError:(NSString *)errorType {

    [self postErrorNotificationsForErrorType:errorType];

    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NNTasksInDatabaseDidUpdateNotification object:nil];
    });

    self.synchronizationInProgress = NO;

    if ([errorType isEqualToString:NNSynchronizationManagerSessionTokenExpiredError] && ![self authSyncInProgress]) {
        [self authenticateWithHashedLogin:[NNDBManager currentLoginHashFromLoginTable]];
        [NNSynchronizationLogger logDebugInfoForGroupName:self.currentSynchronizationGroup mesage:NNSynchronizationManagerSessionTokenExpiredError];
    } else if ([errorType isEqualToString:NNSynchronizationManagerInvalidCredentialsError] && [NNAccountSettingsHelper pinCodeIsSet]) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (self.logoutOnFail || ![self.currentSynchronizationGroup isEqualToString:CDC_syncGroup_Auth]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:NNForceLogoutNotification object:nil userInfo:nil];
            } else {
                [self postSynchronizationNotificationName:NNSynchronizationManagerSynchronizationNotification
                                                 forGroup:self.currentSynchronizationGroup
                                    synchronizationStatus:NNSynchronizationStatusFailed
                                                errorType:errorType];
                self.logoutOnFail = YES;
            }
        });
        [NNSynchronizationLogger logDebugInfoForGroupName:self.currentSynchronizationGroup mesage:NNSynchronizationManagerInvalidCredentialsError];

    } else {

        [self.synchronizationQueue clear];
        [self postSynchronizationNotificationName:NNSynchronizationManagerSynchronizationNotification
                                         forGroup:[self.currentSynchronizationGroup copy]
                            synchronizationStatus:NNSynchronizationStatusFailed
                                        errorType:errorType];
    }
}

#pragma mark - Synchronizations

- (void)startSyncWithGroups:(NSArray *)groups {
    if (![self isLogsSync:groups]) {
        [self checkConnection];
    }

    UIApplication *application = [UIApplication sharedApplication];
    __block UIBackgroundTaskIdentifier backgroundTaskIdentifier = [application beginBackgroundTaskWithExpirationHandler:^{

        [application endBackgroundTask:backgroundTaskIdentifier];
        backgroundTaskIdentifier = UIBackgroundTaskInvalid;

    }];
    
    dispatch_async(databaseQueue, ^{
        [self setupCredentialsWithEmptyLoginAndTokenIfCredentialsAreEmpty];
        @try {
            if (self.synchronizationQueue) {
                [[CDCSynchronization sharedSynchronization] execute:self.dataBase forGroups:groups];
            }
        } @catch(NSException *exception) {
            NSLog(@"EXCEPTION CAUGHT ON [[CDCSynchronization sharedSynchronization] execute: forGroups:] -> %@", [exception description]);
            [NNSynchronizationLogger logDebugInfoForGroupName:self.currentSynchronizationGroup mesage:[exception description]];
        } @finally {
            NSLog(@"Executing finally block");
            [application endBackgroundTask:backgroundTaskIdentifier];
        }

    });
}

-(void)syncWithAuthGroup {
    self.ignoreNetworkConditionMessages = NO;
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_Auth]];
}

-(void)syncWithTasksGroup {

    [self setupSegmentation];

    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_TaskUpdate]];
}

-(void)syncWithTimerGroup {

    [self setupSegmentation];

    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_TaskUpdate, CDC_syncGroup_Execution]];
}

-(void)syncFirstTime {

    [self setupSegmentation];

    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_Logs, CDC_syncGroup_TaskUpdate, CDC_syncGroup_ExecutionStartSync]];
}

- (void)syncWithOrderTreeGroup {
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_OrderTree]];
}

- (void)syncWithDocumentTreeGroup {
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_DocumentTree]];
}

- (void)syncWithExecutionGroup {
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_Execution]];
}

- (void)syncWithExecutionStartSyncGroup {
    
    if ( [self.synchronizationQueue.currentQueue containsObject:CDC_syncGroup_ExecutionStartSync] ) {
        return;
    }
    
    NNWaitingSynchState currentWaitingSynchState = [[NSUserDefaults standardUserDefaults] integerForKey:NNExecutionWaitForSyncInAction];
    switch (currentWaitingSynchState) {
        case NNWaitingSynchStateNone:
            [[NSUserDefaults standardUserDefaults] setInteger:NNWaitingSynchStateRunning forKey:NNExecutionWaitForSyncInAction];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_ExecutionStartSync]];
            break;
            
        case NNWaitingSynchStateRunning:
            [[NSUserDefaults standardUserDefaults] setInteger:NNWaitingSynchStateNeedToRunAgain forKey:NNExecutionWaitForSyncInAction];
            [[NSUserDefaults standardUserDefaults] synchronize];
            break;
            
        case NNWaitingSynchStateNeedToRunAgain:
            break;
    }
    
}

- (void)syncWithExecutionWaitForSyncGroup {
    
    if ( [self.synchronizationQueue.currentQueue containsObject:CDC_syncGroup_ExecutionStartSync] || [self.synchronizationQueue.currentQueue containsObject:CDC_syncGroup_ExecutionWaitForSync] ) {
        return;
    } else {
        [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_ExecutionWaitForSync]];
    }
    
}

- (void)syncWithWaitingForUpdateGroup {
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_WaitingForUpdate]];
}

- (void)syncWithLogs {
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_Logs]];
}

- (void)syncWithNotificationsUpdate {
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_NotificationsUpdate]];
}

- (void)syncWithMyCoadjutorUpdate {
    
    if ([self.synchronizationQueue.currentQueue containsObject:CDC_syncGroup_MyCoadjutorUpdate]) {
        return;
    }
    
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_MyCoadjutorUpdate]];
}

- (void)syncWithTaskLocking {
    
    [self addSynchronizationGroupNamesToQueue:@[CDC_syncGroup_TaskLocking]];
}

- (void)syncWithGroups:(NSArray *)groups {
    [self addSynchronizationGroupNamesToQueue:groups];
}

- (BOOL)isLogsSync:(NSArray *)groups {
    return (groups.count == 1 && [groups.firstObject isEqualToString:CDC_syncGroup_Logs]);
}

- (void)addSynchronizationGroupNamesToQueue:(NSArray *)synchronizationGroupNames {

    if (self.synchronizationQueue == nil) {
        self.synchronizationQueue = [[NNCDCSynchronizationQueue alloc] init];
    }
    
    [self.synchronizationQueue enqueueSynchronizationGroupNames:synchronizationGroupNames];
    
    dispatch_async(databaseQueue, ^{
        if (!self.synchronizationInProgress) {
            [self syncWithPendingSynchronizationGroup];
        }
    });

}

-(void)setLastSynchronizationTimestamp {
        [NNAccountSettingsHelper setLastSynchronizationTimestamp:[NSDate date]];
        [[NNSynchronizationTimer sharedTimer] restartTimer];
}

#pragma mark - Push notifications

- (void)registerForRemoteNotifications:(NSData *)deviceToken {

    [self checkConnection];

    if ([NNAccountSettingsHelper pushTokenChanged:deviceToken]) {
        [NNAccountSettingsHelper savePushToken:deviceToken];

        //сохранение девайс токена временно перенесено в момент непосредственно перед синхронизацией
        //т.к. из за одновременного сохранения и синхронизации токен в базу не записывается
        [self saveInDatabasePushDeviceToken];

    }
}

- (void)saveInDatabasePushDeviceToken {
    
    NSData *deviceToken = [NNAccountSettingsHelper pushToken];
    if (!deviceToken) {
        deviceToken = [NSData data];
    }
    
    @try {
        
        [[self dbQueue] inDatabase:^(FMDatabase *db) {
            [[CDCSynchronization sharedSynchronization] registerPushDeviceId:db devicePushId:deviceToken];
            NSLog(@"save registerPushDeviceId %@", deviceToken);
        }];
        
    } @catch(NSException *exception) {
        NSLog(@"EXCEPTION CAUGHT ON [[CDCSynchronization sharedSynchronization] registerForRemoteNotifications:] -> %@", [exception description]);
    }
}

#pragma mark - NNSynchronizationSessionServiceDelegate

- (void)synchronizationSessionService:(NNSynchronizationSessionService *)service didCatchErrorForSession:(NNSynchronizationSession *)session {

    [self postSynchronizationNotificationName:NNSynchronizationManagerSynchronizationNotification
                                     forGroup:[self.currentSynchronizationGroup copy]
                        synchronizationStatus:NNSynchronizationStatusEndedWithSessionError
                                    errorType:nil];
    
    [self.synchronizationQueue clear];
    
    [self checkExecutionWaitingTimer];
    [self syncWithPendingSynchronizationGroup];
    
}

- (void)synchronizationSessionService:(NNSynchronizationSessionService *)service didCatchSuccessForSession:(NNSynchronizationSession *)session {
    [self syncWithPendingSynchronizationGroup];
}


#pragma mark - Private
- (void)startExecutionWaitingTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.executionWaitingTimer) {
            [self.executionWaitingTimer invalidate];
            self.executionWaitingTimer = nil;
        }
        
        self.executionWaitingTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                                      target:self
                                                                    selector:@selector(executionWaitingTimerFunc)
                                                                    userInfo:nil
                                                                     repeats:NO];
    });
}


- (void)startExecutionResponseTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.executionWaitingTimer) {
            [self.executionWaitingTimer invalidate];
            self.executionWaitingTimer = nil;
        }
        
        self.executionWaitingTimer = [NSTimer scheduledTimerWithTimeInterval:10
                                                                      target:self
                                                                    selector:@selector(executionResponseTimerFunc)
                                                                    userInfo:nil
                                                                     repeats:NO];
    });
}

- (void)stopExecutionWaitingTimer {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.executionWaitingTimer) {
            [self.executionWaitingTimer invalidate];
            self.executionWaitingTimer = nil;
        }
    });
}

- (void)executionWaitingTimerFunc {
    // Защита от ложного срабатывания таймера
    if ( [[NSUserDefaults standardUserDefaults] integerForKey:NNExecutionWaitForSyncInAction] == NNWaitingSynchStateNone) { return; }
    [self syncWithExecutionWaitForSyncGroup];
}

- (void)executionResponseTimerFunc {
    [self syncWithExecutionGroup];
}

- (void)checkExecutionWaitingTimer {
    
    // Защита от повторного добавления
    if ( [self.synchronizationQueue.currentQueue containsObject:CDC_syncGroup_ExecutionWaitForSync] ||
         [self.synchronizationQueue.currentQueue containsObject:CDC_syncGroup_ExecutionStartSync] )
    {
        return;
    }
    
    NNWaitingSynchState currentWaitingSynchState = [[NSUserDefaults standardUserDefaults] integerForKey:NNExecutionWaitForSyncInAction];
    switch (currentWaitingSynchState) {
        case NNWaitingSynchStateNone:
            // Empty
            break;
            
        case NNWaitingSynchStateRunning:
        case NNWaitingSynchStateNeedToRunAgain:
            if ( ![self.synchronizationQueue.currentQueue containsObject:CDC_syncGroup_ExecutionWaitForSync] ) {
                [self stopExecutionWaitingTimer];
                [self syncWithExecutionWaitForSyncGroup];
            }
            
            break;
    }
    
}

@end
