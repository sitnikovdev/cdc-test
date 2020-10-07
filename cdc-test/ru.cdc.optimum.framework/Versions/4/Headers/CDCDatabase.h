//
//  CDCDatabase.h
//  csp
//
//  Created by Demin Dmitriy on 20.06.14.
//  Copyright (c) 2014 CDC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

/**
 <p>Database helper</p>
 */
@interface CDCDatabase : NSObject
/** Creates or opens previously created database with structure provided in xml file.
 
 @param xmlFile full name of xml file (with path)
 @param path full name of database file (with path)

 @return [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html)
 */
-(FMDatabase*)createOrOpenDatabaseByXml:(NSString*)xmlFile path:(NSString*)path;
/** Creates database with structure provided in xml file.
 
 @param xmlFile full name of xml file (with path)
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html)
 
 @return <b>YES</b> - success, <b>NO</b> otherwise
 */
-(BOOL)createStructureByXml:(NSString*)xmlFile database:(FMDatabase*)database;

@end
