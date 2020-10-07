//
//  CDCPlatformVariables.h
//  csp
//
//  Created by Demin Dmitriy on 28.07.14.
//  Copyright (c) 2014 CDC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "FMDatabase.h"

/**
 * <p>Platform variables class</p>
 */
@interface CDCPlatformVariables : NSObject

/**
 Returns shared instance with provided database.
 
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @see CDCDatabase
 */
+(id)platformVariables:(FMDatabase*)database;

/**
 Saves all platform values to database by one transaction.
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @see CDCDatabase
 */
-(void)commit:(FMDatabase*)database;

/**
 Sets string value for platform variable.
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @param name platform variable name
 @param value platform variable value
 
 <div><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var put:@"test_1" textValue:@"test_1"];
 <br>[var put:@"test_2" textValue:@"test_1"];
 <br>[var commit];</p></div>
 */
+(void)putToDatabase:(FMDatabase*)database name:(NSString*)name stringValue:(NSString*)value;
/**
 Sets int value for platform variable.
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @param name platform variable name
 @param value platform variable value
 
 <div><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var put:@"test_1" intValue:1];
 <br>[var put:@"test_2" intValue:2];
 <br>[var commit];</p></div>
 */
+(void)putToDatabase:(FMDatabase*)database name:(NSString*)name intValue:(int)value;
/**
 Returns string value of platrorm variable.
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @param name platform variable name
 @return string value of platrorm variable
 <p><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var getString:@"test"];</p></p>
 */
+(NSString*)getStringFromDatabase:(FMDatabase*)database name:(NSString*)name;
/**
 Returns int value of platrorm variable.
 @param database [FMDatabase](http://ccgus.github.io/fmdb/html/Classes/FMDatabase.html) database object
 @param name platform variable name
 @return int value of platrorm variable
 <div><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var getInt:@"test"];</p></div>
 */
+(int)getIntFromDatabase:(FMDatabase*)database name:(NSString*)name;

/**
 Sets string value for platform variable.
 @param name platform variable name
 @param value platform variable value
 
 <div><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var put:@"test_1" textValue:@"test_1"];
 <br>[var put:@"test_2" textValue:@"test_1"];
 <br>[var commit];</p></div>
 */
-(void)setString:(NSString*)name stringValue:(NSString*)value;

/**
 Sets int value for platform variable.
 @param name platform variable name
 @param value platform variable value
 
 <div><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var put:@"test_1" intValue:1];
 <br>[var put:@"test_2" intValue:2];
 <br>[var commit];</p></div>
 */
-(void)setInt:(NSString*)name intValue:(int)value;
/**
 Returns string value of platrorm variable.
 @param name platform variable name
 @return string value of platform variable
 <p><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var getString:@"test"];</p></p>
 */
-(NSString*)getString:(NSString*)name;
/**
 Returns int value of platrorm variable.
 @param name platform variable name
 @return int value of platform variable
 <div><b>Example</b>
 <p>CDCPlatformVariables* var = [CDCPlatformVariables platformVariables:database];
 <br>[var getInt:@"test"];</p></div>
 */
-(int)getInt:(NSString*)name;


@end
