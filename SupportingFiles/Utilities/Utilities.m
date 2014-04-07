//
//  Utilities.m
//  piXchange
//
//  Created by Jared Gross on 12/17/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import "Utilities.h"
#import <CommonCrypto/CommonDigest.h>

@implementation Utilities

+(NSString*) removeSpecialCharsFromString:(NSString *)origString
{
    NSCharacterSet *notAllowedChars = [[NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890"] invertedSet];
    NSString *resultString = [[origString componentsSeparatedByCharactersInSet:notAllowedChars] componentsJoinedByString:@""];
    
    if (resultString.length > 10){
        resultString = [resultString substringFromIndex:1];
    }
    
    return resultString;
}

+ (NSData *)sha256:(NSString *)string
{
    if(!string)
        return nil;
    
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    unsigned char hash[CC_SHA256_DIGEST_LENGTH];
    if ( CC_SHA256([data bytes], (uint32_t)[data length], hash) ) {
        NSData *sha256 = [NSData dataWithBytes:hash length:CC_SHA256_DIGEST_LENGTH];
        return sha256;
    }
    return nil;
}


@end
