//
//  userContactsList.h
//  Flashback
//
//  Created by Jared Gross on 12/18/13.
//  Copyright (c) 2013 piXchange, LLC.. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface userContactsList : NSObject
@property (nonatomic, strong) NSArray* allContactsDetailsList;

+(userContactsList*) getInstance;
-(void) refreshContactsList;
@end
