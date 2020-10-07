//
//  NSNumber+CDCDate.h
//  csp
//
//  Created by Demin Dmitriy on 29.08.14.
//  Copyright (c) 2014 CDC. All rights reserved.
//

#import <Foundation/Foundation.h>
/**
 * <p>NSNumber helper</p>
 */
@interface NSNumber(CDCDate)

/**
 Converts JulianDay NSNumber to NSDate.
 */
-(NSDate*)dateValue;
/**
 Converts NSDate to JulianDay NSNumber.
 @param value NSDate object to convert
 @return JulianDay NSNumber
 */
+(NSNumber*)numberWithDate:(NSDate *)value;

@end
