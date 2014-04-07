//
//  Utilities.h
//  piXchange
//
//  Created by Jared Gross on 12/17/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utilities : NSObject
+ (NSData *)sha256:(NSString *)string;
+(NSString*) removeSpecialCharsFromString:(NSString*) origString;
@end