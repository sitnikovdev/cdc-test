//
//  NNSynchronizationSession.m
//  NorNickel
//
//  Created by Privezentsev Yury on 17.11.2017.
//  Copyright © 2017 baccasoft. All rights reserved.
//

#import "NNSynchronizationSession.h"

@implementation NNSynchronizationSession

- (instancetype)initWithGroupName:(NSArray *)groupNames type:(NNSessionType)type {

    self = [super init];
    if (self) {
        _guid = [[NSUUID UUID] UUIDString];
        _groupNamesArray = [groupNames copy];
        _sessionType = type;
    }
    return self;
}

@end
