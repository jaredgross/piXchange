//
//  userContactsList.m
//  piXchange
//
//  Created by Jared Gross on 12/18/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "userContactsList.h"
#import <AddressBook/ABPerson.h>
#import <AddressBook/AddressBook.h>
#import <Parse/Parse.h>
#import "contactDetails.h"

static userContactsList* contactsListSingleton;

@interface userContactsList()

@end

@implementation userContactsList

-(id) init
{
    self = [super init];
    if(self)
    {
        self.allContactsDetailsList = [[NSMutableArray alloc] init];
    }
    
    return self;
}

-(void) populateAddressBookArray
{
    CFErrorRef *error = NULL;
    ABAddressBookRef addressBook = ABAddressBookCreateWithOptions(NULL, error);
    ABAddressBookRequestAccessWithCompletion(addressBook, ^(bool granted, CFErrorRef error) {
        
        CFArrayRef allPeople = ABAddressBookCopyArrayOfAllPeople(addressBook);
        CFIndex numberOfPeople = ABAddressBookGetPersonCount(addressBook);
        
        NSMutableArray* tempContactsList = [[NSMutableArray alloc] init];
        
        for(int i = 0; i < numberOfPeople; i++)
        {
            ABRecordRef person = CFArrayGetValueAtIndex( allPeople, i );
            
            NSString *firstName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonFirstNameProperty));
            NSString *lastName = (__bridge NSString *)(ABRecordCopyValue(person, kABPersonLastNameProperty));
            
            ABMultiValueRef phoneNumbers = ABRecordCopyValue(person, kABPersonPhoneProperty);
            
            for (CFIndex i = 0; i < ABMultiValueGetCount(phoneNumbers); i++)
            {
                NSString *origPhoneNumber = (__bridge_transfer NSString *) ABMultiValueCopyValueAtIndex(phoneNumbers, i);
                NSString* phoneNumber = [Utilities removeSpecialCharsFromString:origPhoneNumber];
                if(phoneNumber)
                {
                    NSString* excryptedNumber = [[Utilities sha256:phoneNumber] base64EncodedStringWithOptions:0];
                    
                    if(excryptedNumber)
                    {
                        contactDetails* detail = [[contactDetails alloc] init];
                        detail.firstName = firstName;
                        detail.lastName = lastName;
                        detail.phoneNumber = origPhoneNumber;
                        detail.encryptedPhoneNumber = excryptedNumber;
                        
                        [tempContactsList addObject:detail];
                    }
                }
            }
            
            self.allContactsDetailsList = [tempContactsList copy];
        }
        
        [self getMatchingUserNames];
        
    });
}

-(void) getMatchingUserNames
{
    
    PFQuery *query = [PFUser query];
    [query orderByAscending:@"username"];
    
    NSMutableArray* allPhoneNumber = [[NSMutableArray alloc] init];
    for (contactDetails* detail in self.allContactsDetailsList)
    {
        [allPhoneNumber addObject:detail.encryptedPhoneNumber];
    }
    
    if(allPhoneNumber.count > 0)
    {
        [query whereKey:@"phoneNumber" containedIn:allPhoneNumber];
        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error)
         {
             for (PFUser* user in objects)
             {
                 for (contactDetails* detail in self.allContactsDetailsList)
                 {
                     if([detail.encryptedPhoneNumber isEqualToString:user[@"phoneNumber"]])
                     {
                         detail.flashbackUserName = user[@"username"];
                         detail.objectID = user.objectId;
                     }
                 }
                 
             }
             
             [[NSNotificationCenter defaultCenter] postNotificationName:kContactsListRefreshNotification object:nil];

         }];
    }
}


-(void) refreshContactsList
{
    [self populateAddressBookArray];
}

+(void) initialize
{
    if(self == [userContactsList class])
    {
        contactsListSingleton = [[userContactsList alloc] init];
    }
}

+(userContactsList*) getInstance
{
    return contactsListSingleton;
}

@end
