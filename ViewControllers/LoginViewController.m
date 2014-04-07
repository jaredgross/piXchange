//
//  LoginViewController.m
//  piXchange
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "LoginViewController.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface LoginViewController ()

@property (nonatomic, assign) UITextField *activeTextField;
@property (nonatomic, weak) IBOutlet UIButton *login;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) NSMutableArray *imagesArray;

- (IBAction)login:(id)sender;
- (IBAction)dismissKeyboard:(id)sender;
@end

@implementation LoginViewController 

// initialize the view controller
- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.navigationController.navigationBar.hidden =YES;
    self.tabBarController.tabBar.hidden =YES;
    
    self.usernameField.delegate = self;
    self.passwordField.delegate = self;

    // set up tap gesture recognizer for textFields
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                             name:UIKeyboardDidShowNotification
                                             object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillHide:)
                                             name:UIKeyboardWillHideNotification
                                             object:nil];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                           action:@selector(dismissKeyboard)];
    [self.view addGestureRecognizer:tap];
    
    self.imagesArray = [[NSMutableArray alloc]initWithObjects:
              [UIImage imageNamed:@"image1.png"],
              [UIImage imageNamed:@"image3.png"],
              [UIImage imageNamed:@"image4.png"],
              [UIImage imageNamed:@"image5.png"],
              nil];
    self.imageView.image = [self getRandomImage];
}
- (UIImage *)getRandomImage {
    return [self imagesArray][arc4random_uniform((uint32_t)[self imagesArray].count)];
}

#pragma mark - ACTIONS
// user tapped 'return' key on keyboard
- (IBAction)dismissKeyboard:(id)sender {
    [self.activeTextField resignFirstResponder];
}

// user tapped button to login
- (IBAction)login:(id)sender {
    
    [self.activeTextField resignFirstResponder];
    self.login.enabled = NO;

    // get the values for the username & password fields
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = [self.passwordField.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    // check the length of the username & password
    if ([username length] == 0 || [password length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:@"Make sure you enter a username and password!"
                                                            delegate:nil
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
        [alertView show];
        self.login.enabled = YES;
    }else{ // login the user
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Logging in...";
        [hud show:YES];

        
        [PFUser logInWithUsernameInBackground:username
                                     password:password block:^(PFUser *user, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry, we couldn't log you in! Please try again!"
                                                                    message:[error.userInfo objectForKey:@"error"]
                                                                    delegate:nil
                                                                    cancelButtonTitle:@"OK"
                                                                    otherButtonTitles:nil];
                [alertView show];
                self.login.enabled = YES;
            }else{
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
                 UIRemoteNotificationTypeBadge |
                 UIRemoteNotificationTypeAlert |
                 UIRemoteNotificationTypeSound];
                
                [self performSegueWithIdentifier:@"showMain" sender:self];
            }
                                         
            [hud hide:YES];
        }];
    }
}

#pragma mark - KEYBOARD HELPERS
// scrolls selected textview out of the way of the keyboard
- (void)keyboardWasShown:(NSNotification *)notification {
    
    // get the size of the keyboard
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // adjust the bottom content inset of the scroll view by the keyboard height
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, keyboardSize.height, 0.0);
    theScrollView.contentInset = contentInsets;
    theScrollView.scrollIndicatorInsets = contentInsets;
    
    // scroll the target text field into view
    CGRect aRect = self.view.frame;
    aRect.size.height -= keyboardSize.height;
    if (!CGRectContainsPoint(aRect, self.activeTextField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, self.activeTextField.frame.origin.y - (keyboardSize.height-15));
        [theScrollView setContentOffset:scrollPoint animated:YES];
    }
}

// hides the keyboard and returns the view to normal
- (void) keyboardWillHide:(NSNotification *)notification {
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    theScrollView.contentInset = contentInsets;
    theScrollView.scrollIndicatorInsets = contentInsets;
}

// set activeTextField to the current active textfield
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

// set activeTextField to nil
- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
}

// dismiss the keyboard
- (void)dismissKeyboard {
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
}

@end
