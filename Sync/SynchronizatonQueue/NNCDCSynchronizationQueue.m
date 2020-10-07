//
//  NNCDCSynchronizationQueue.m
//  NorNickel
//
//  Created by Privezentsev Yury on 15.11.2017.
//  Copyright © 2017 baccasoft. All rights reserved.
//

#import "NNCDCSynchronizationQueue.h"
#import "NNCDCConstants.h"

@interface NNCDCSynchronizationQueue ()

@property (strong, nonatomic) NSMutableArray *queue;

@end

@implementation NNCDCSynchronizationQueue

#pragma mark - Accessors

- (NSArray *)currentQueue {

    return [self.queue copy];
}

#pragma mark - Initializer

- (instancetype)init {

    self = [super init];
    if (self) {
        _queue = [[NSMutableArray alloc] init];
    }
    return self;
}

#pragma mark - Public

- (void)enqueueSynchronizationGroupNames:(NSArray *)synchronizationGroupNames {

    for (NSString *synchronizationGroupName in synchronizationGroupNames) {

        if ([synchronizationGroupName isEqualToString:CDC_syncGroup_Auth]) {

            [self enqueueSynchronizationGroupName:synchronizationGroupName forceToFirstPlace:YES];

        } else if (!([synchronizationGroupName isEqualToString:CDC_syncGroup_Logs] && [self.queue containsObject:CDC_syncGroup_Logs])) {

            [self enqueueSynchronizationGroupName:synchronizationGroupName forceToFirstPlace:NO];
            
        }

    }

}

- (void)enqueueSynchronizationGroupName:(NSString *)groupName forceToFirstPlace:(BOOL)forceToFirstPlace {

    if (forceToFirstPlace) {

        [self.queue insertObject:groupName atIndex:0];

    } else {

        [self.queue addObject:groupName];

    }
}

- (NSString *)dequeueNextSynchronizationGroup {

    NSString *nextGroup = [self.queue firstObject]; // Возвращает nill если массив пустой

    if (nextGroup) { // Если первый объект существует, удаляем его из очереди
        [self.queue removeObjectAtIndex:0];
    }

    return nextGroup;
}

- (BOOL)removeSynchronizationGroupNameFromQueue:(NSString *)groupNameToRemove {

    if ([self.queue containsObject:groupNameToRemove]) {
        [self.queue removeObject:groupNameToRemove];
        return YES;
    }

    return NO;
}

- (void)clear {

    self.queue = [[NSMutableArray alloc] init];
}


#pragma mark - Private

@end
