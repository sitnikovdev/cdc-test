//
//  CDCCredentials.h
//  csp
//
//  Created by Александр Головков on 26.11.16.
//  Copyright © 2016 CDC. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 <p>Credentials used for authentication and synchronization</p>
 */
@interface CDCCredentials : NSObject

/**
 Login, default value is an empty string.
 */
@property (nonatomic, strong) NSString *login;

/**
 Password, default value is an empty string.
 */
@property (nonatomic, strong) NSString *password;

@end
