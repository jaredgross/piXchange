//
//  FindFriendsViewController.m
//  piXchange
//
//  Created by Jared Gross on 12/16/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "FindFriendsViewController.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

static NSString* const PFUserPhoneNumberKey=@"phoneNumber";

@interface FindFriendsViewController ()

@property (strong, nonatomic) IBOutlet UITextField *phoneNumberField;
- (IBAction)nextButton:(id)sender;


@end

@implementation FindFriendsViewController


- (void)viewDidLoad{
    [super viewDidLoad];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
}

- (IBAction)nextButton:(id)sender {
    
    [self dismissKeyboard];
    
    if(!self.phoneNumberField.text || self.phoneNumberField.text.length != 10)
    {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Please try again"
                                                            message:@"Use a 10 digit number in the form XXX-XXX-XXXX"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];

        return;
    }
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Loading...";
    [hud show:YES];
    
    PFUser *newUser = [PFUser  currentUser];
    NSData* phoneData = [Utilities sha256:self.phoneNumberField.text];
    NSString* excryptedNumber = [phoneData base64EncodedStringWithOptions:0];
    if(phoneData)
    {
        newUser[PFUserPhoneNumberKey] = excryptedNumber;
        [newUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            
            if(!error)
            {
                //fetch the matching contacts list
                [[userContactsList getInstance] refreshContactsList];
                
                [self performSegueWithIdentifier:@"home" sender:self];
                [hud hide:YES];
            }
            else
            {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry, we couldn't update your phone number at this time! Please try again!"
                                                                    message:[error.userInfo objectForKey:@"error"]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];

                return;
                [hud hide:YES];
            }
        }];
    }
}

// dismisses the keybaord
-(void)dismissKeyboard {
    [self.phoneNumberField resignFirstResponder];
}

@end
