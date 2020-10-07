//
//  CDCSync.h
//  com.cdc.platformdemo
//
//  Created by Anatoliy Vetchinin on 14.08.14.
//  Copyright (c) 2014 CDC Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <ru.cdc.optimum/csp.h>

@interface CDCSync : NSObject

+(instancetype)sharedSync;

-(void)syncWithGroups:(NSArray *)groups inBackground:(BOOL)inBackground;
-(FMDatabase *)db;
-(void)recreateDb;
-(void)setConnectionParameters:(NSString *)address :(NSUInteger)port;
-(NSDictionary*)authenticate:(NSString*)login password:(NSString*)password allowOffline:(BOOL)allowOffline;

@property (nonatomic, readwrite) BOOL hasError;
@property (nonatomic, readwrite) BOOL isOnline;
@property (atomic, readwrite) BOOL isSync;

@end
