//
//  contactDetails.m
//  piXchange
//
//  Created by Jared Gross on 12/18/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import "contactDetails.h"

@implementation contactDetails

-(id) init
{
    self = [super init];
    if(self)
    {
        self.firstName = nil;
        self.lastName = nil;
        self.flashbackUserName = nil;
        self.phoneNumber = nil;
        self.objectID = nil;
    }
    
    return self;
}

@end
