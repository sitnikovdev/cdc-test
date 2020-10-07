//
//  NNSynchronizationSessionService.m
//  NorNickel
//
//  Created by Privezentsev Yury on 17.11.2017.
//  Copyright © 2017 baccasoft. All rights reserved.
//

#import <ru.cdc.optimum/FMDatabase.h>
#import <ru.cdc.optimum/CDCPlatformVariables.h>
#import <ru.cdc.optimum/FMDatabaseQueue.h>
#import "NNSynchronizationSessionService.h"
#import "NNSynchronizationSessionStatusService.h"
#import "NNCDCConstants.h"
#import "NNSynchronizationSession.h"
#import "NNGroupSessionStorage.h"

static NSString * const CDCSessionIdentifierPlatformVariable = @"@sessionId";

@interface NNSynchronizationSessionService () <NNSynchronizationSessionStatusServiceDelegate>

@property (strong, nonatomic) NSMutableDictionary *synchronizationSessions;
@property (strong, nonatomic) NNSynchronizationSessionStatusService *statusService;
@property (weak, nonatomic) FMDatabaseQueue *databaseQueue;
@property (strong, nonatomic) NNGroupSessionStorage *groupSessionStorage;

@end

@implementation NNSynchronizationSessionService

#pragma mark - Initialization

- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue {

    self = [super init];
    if (self) {
        _statusService = nil;
        _synchronizationSessions = [[NSMutableDictionary alloc] init];
        _databaseQueue = databaseQueue;
        self.groupSessionStorage = [[NNGroupSessionStorage alloc] init];
    }
    return self;
}

#pragma mark - Public

- (void)handleSessionForSynchronizationGroupName:(NSString *)synchronizationGroupName {
    
    if ([synchronizationGroupName isEqualToString:CDC_syncGroup_TaskUpdate]) {

           NSArray * groupNames = @[CDC_syncGroup_TaskUpdate, CDC_syncGroup_WaitingForUpdate];
           [self registerSessionForGroupNames:groupNames type:NNSessionTypeTasks];

       } else {
           
           [self.groupSessionStorage addGroupToMap:synchronizationGroupName];
           
       }

    NNSynchronizationSession *session = self.synchronizationSessions[synchronizationGroupName];

    if ([synchronizationGroupName isEqualToString:CDC_syncGroup_ExecutionStartSync] || [synchronizationGroupName isEqualToString:CDC_syncGroup_ExecutionWaitForSync]) {
        NSString *sessionId = [self.groupSessionStorage readGuidForGroup:CDC_syncGroup_ExecutionStartSync];
        if (sessionId) {
            [self setSessionIdPlatformVariable:[self.groupSessionStorage readGuidForGroup:CDC_syncGroup_ExecutionStartSync]];
        } else {
            [self setSessionIdPlatformVariable:@""];
        }
        
    } else {
        if (session) {
            [self setSessionIdPlatformVariable:session.guid];
            
            self.statusService = [[NNSynchronizationSessionStatusService alloc] initWithSession:session];
            self.statusService.delegate = self;
            [self.statusService startObservingSynchronizationNotifications];
        } else {
            [self setSessionIdPlatformVariable:@""];
        }
    }
    
}

#pragma mark - Private

- (void)registerSessionForGroupNames:(NSArray *)groupNames type:(NNSessionType)type {

    NNSynchronizationSession *session = [[NNSynchronizationSession alloc] initWithGroupName:groupNames type:type];

    for (NSString *groupName in groupNames) {
        self.synchronizationSessions[groupName] = session;
        [self.groupSessionStorage forceAddGroupToMap:groupName withGUID:session.guid ];
    }
}

- (void)setSessionIdPlatformVariable:(NSString *)sessionIdentifier {
    [self.databaseQueue inDatabase:^(FMDatabase *db) {
        CDCPlatformVariables *platformVariables = [CDCPlatformVariables platformVariables:db];
        [platformVariables setString:CDCSessionIdentifierPlatformVariable stringValue:sessionIdentifier];
        [platformVariables commit:db];
    }];
}

#pragma mark - NNSynchronizationSessionStatusServiceDelegate

- (void)synchronizationSessionStatusService:(NNSynchronizationSessionStatusService *)service didCatchSynchronizationErrorForSession:(NNSynchronizationSession *)session {

    [self.delegate synchronizationSessionService:self didCatchErrorForSession:session];
}

- (void)synchronizationSessionStatusService:(NNSynchronizationSessionStatusService *)service didCatchSynchronizationSuccessForSession:(NNSynchronizationSession *)session {

    [self.delegate synchronizationSessionService:self didCatchSuccessForSession:session];

}

@end
