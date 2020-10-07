//
//  NNSynchronizationSessionService.h
//  NorNickel
//
//  Created by Privezentsev Yury on 17.11.2017.
//  Copyright © 2017 baccasoft. All rights reserved.
//

#import <Foundation/Foundation.h>

@class NNSynchronizationSessionService;
@class NNSynchronizationSession;
@class FMDatabase;

@protocol NNSynchronizationSessionServiceDelegate <NSObject>

/**
 * Сообщщает делегату, о том, что произошла ошибка синхронизации в рамках сессии
 *
 * @param service NNSynchronizationSessionService Сервис сессий синхронизации
 * @param session NNSynchronizationSession Сессия, в рамках которой произошла ошибка
 */
- (void)synchronizationSessionService:(NNSynchronizationSessionService *)service didCatchErrorForSession:(NNSynchronizationSession *)session;

/**
 * Сообщщает делегату, о том, что синхронизации в рамках сессии прошла успешно
 *
 * @param service NNSynchronizationSessionService Сервис сессий синхронизации
 * @param session NNSynchronizationSession Сессия, которая завершилась успешно
 */
- (void)synchronizationSessionService:(NNSynchronizationSessionService *)service didCatchSuccessForSession:(NNSynchronizationSession *)session;

@end

// Обеспечивает работу с идентификаторами сессий
// Создает объекты Сессий для определнных групп синхронизации

@interface NNSynchronizationSessionService : NSObject

@property (weak, nonatomic) id<NNSynchronizationSessionServiceDelegate> delegate;

/**
 * Инициализирует сервис базой данных, в которой хранятся переменые платформы CDC
 *
 * @param databaseQueue FMDatabaseQueue Очередь работы с БД
 *
 * @return Сервис
 */
- (instancetype)initWithDatabaseQueue:(FMDatabaseQueue *)databaseQueue;

/**
 * В этом методе происходит обработка новой группы синхронизации перед началом синхронизации
 *
 * @param synchronizationGroupName NSString имя группы синхронизации
 */
- (void)handleSessionForSynchronizationGroupName:(NSString *)synchronizationGroupName;

@end
