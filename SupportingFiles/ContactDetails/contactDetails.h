//
//  contactDetails.h
//  piXchange
//
//  Created by Jared Gross on 12/18/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface contactDetails : NSObject
@property (nonatomic, copy) NSString* firstName;
@property (nonatomic, copy) NSString* lastName;
@property (nonatomic, copy) NSString* flashbackUserName;
@property (nonatomic, copy) NSString* phoneNumber;
@property (nonatomic, copy) NSString* encryptedPhoneNumber;
@property (nonatomic, copy) NSString* objectID;
@end
