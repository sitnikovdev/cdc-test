//
//  CDCSync.m
//  com.cdc.platformdemo
//
//  Created by Anatoliy Vetchinin on 14.08.14.
//  Copyright (c) 2014 CDC Ltd. All rights reserved.
//


#import "CDCSync.h"

@interface CDCSync()

@property (nonatomic) FMDatabase *db;

@end

@implementation CDCSync

+(instancetype)sharedSync
{
    static CDCSync *sync;
    if (!sync){
        sync = [[self alloc] initPrivate];
    }
    return sync;
}

-(instancetype)init
{
    [NSException raise:@"Singleton" format:@"Use +[CDCSync sharedSync]"];
    return  nil;
}

-(void)recreateDb
{
    NSString *dbFile = [_db databasePath];
    NSLog(@"Db file: %@", dbFile);
    [_db close];
    [[NSFileManager defaultManager] removeItemAtPath:dbFile error:nil];
    [self createDb];
    NSLog(@"recreated");
}

-(void)createDb
{
    NSBundle *bundle = [NSBundle bundleForClass:[self class]];
    NSString *xmlFile = [bundle pathForResource:@"AdvWorksMobile_1" ofType:@"xml"];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"demo.db3"];
    
    CDCDatabase *database = [CDCDatabase new];
    _db = [database createOrOpenDatabaseByXml:xmlFile path:path];
}

-(instancetype)initPrivate
{
    self = [super init];
    if (self)
    {
        [self createDb];
        self.isOnline = NO;
        self.isSync = NO;
    }
    return self;
}

-(void) setConnectionParameters:(NSString *)address :(NSUInteger)port
{
    CDCConnectionParameters *cp = [CDCConnectionParameters new];
    cp.hostName = address;
    cp.portNumber = port;
    cp.writeTimeout = 60000;
    cp.readTimeout = 60000;
    [[CDCSynchronization sharedSynchronization] setConnectionParameters:cp];
}

-(NSDictionary*)authenticate:(NSString*)login password:(NSString*)password allowOffline:(BOOL)allowOffline
{
    self.hasError = NO;
    [[[CDCSynchronization sharedSynchronization] credentials] setLogin:login];
    [[[CDCSynchronization sharedSynchronization] credentials] setPassword:password];
    return [[CDCSynchronization sharedSynchronization] authenticate:self.db allowOffline:allowOffline];
}

-(void)syncWithGroups:(NSArray *)groups inBackground:(BOOL)inBackground
{
    self.isSync = YES;
    self.hasError = NO;
    if(!inBackground)
    {
    }
    [[CDCSynchronization sharedSynchronization] execute:_db forGroups:groups];
    self.isSync = NO;
}

-(FMDatabase *)db
{
    return _db;
}

@end

