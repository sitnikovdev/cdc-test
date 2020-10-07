//
//  NNSynchronizationSession.h
//  NorNickel
//
//  Created by Privezentsev Yury on 17.11.2017.
//  Copyright © 2017 baccasoft. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, NNSessionType) {
    NNSessionTypeTasks = 0,
};

@interface NNSynchronizationSession : NSObject

@property (copy, nonatomic) NSString *guid;
@property (copy, nonatomic) NSArray *groupNamesArray;
@property (assign, nonatomic) NNSessionType sessionType;

- (instancetype)initWithGroupName:(NSArray *)groupNames type:(NNSessionType)type;

@end
