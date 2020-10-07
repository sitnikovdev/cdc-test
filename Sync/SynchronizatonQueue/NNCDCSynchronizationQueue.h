//
//  NNCDCSynchronizationQueue.h
//  NorNickel
//
//  Created by Privezentsev Yury on 15.11.2017.
//  Copyright © 2017 baccasoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NNCDCSynchronizationQueue : NSObject

/**
 * Список групп синхронизации, которые сейчас находятся в очереди
 */
@property (strong, nonatomic, readonly) NSArray *currentQueue;

/**
 * Инициализирует очередь синхронизации
 *
 * @return Новая очередь синхронизации
 */
- (instancetype)init;

/**
 * Добавляет список групп синхронизации в очередь
 *
 * Реализует логику добавления группы в начало или конец очереди в зависимости от от ее имени,
 * вызывая метод -enqueueSynchronizationGroupName:forceToFirstPlace: с соответвующим параметром
 * 
 * @param synchronizationGroupNames NSArray
 */
- (void)enqueueSynchronizationGroupNames:(NSArray *)synchronizationGroupNames;

/**
 * Добавляет новую группу синхронизации в очередь
 *
 * @param groupName NSString Имя грууппы синхронизации
 * @param forceToFirstPlace BOOL параметр, который указыват добавлять группу в начала списка или в конец
 */
- (void)enqueueSynchronizationGroupName:(NSString *)groupName forceToFirstPlace:(BOOL)forceToFirstPlace;

/**
 * Достает из очереди следущую группу синхронизации, при этом удаляя ее из очереди
 *
 * @return NSString Имя группы синхронизации, nil если следующей группы нет
 */
- (NSString *)dequeueNextSynchronizationGroup;

/**
 * Удаляет группу синхронизации из очереди
 *
 * @param groupNameToRemove NSString имя группы синхронизации, которое нужно принуддительно удалить
 *
 * @return BOOL Если группа была удалена - YES, иначе (если ее не было) - NO
 */
- (BOOL)removeSynchronizationGroupNameFromQueue:(NSString *)groupNameToRemove;

/**
 * Очищает очерь синхронизации
 */
- (void)clear;

@end
