//
//  SignupViewController.m
//  piXchange
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "SignupViewController.h"
#import <Parse/Parse.h>
#import "MBProgressHUD.h"

@interface SignupViewController ()

@property (strong, nonatomic) IBOutlet UIButton *signup;
@property (nonatomic, assign) UITextField *activeTextField;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, retain) NSMutableArray *imagesArray;

- (IBAction)signup:(id)sender;
- (IBAction)dismissKeyboard:(id)sender;
@end

@implementation SignupViewController 

// initialize the view controller
- (void)viewDidLoad {
    [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    self.navigationController.navigationBar.hidden =YES;
    self.tabBarController.tabBar.hidden =YES;
    
    self.emailField.delegate = self;
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
// user tapped button to signup
- (IBAction)signup:(id)sender {
    
    [self.activeTextField resignFirstResponder];
    self.signup.enabled = NO;

    // get the values for each textField
    NSString *username = [self.usernameField.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *password = [self.passwordField.text stringByTrimmingCharactersInSet:
                          [NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    NSString *email = [self.emailField.text stringByTrimmingCharactersInSet:
                       [NSCharacterSet whitespaceAndNewlineCharacterSet]];;
    
    // check the values to make sure they arenet empty
    if ([username length] == 0 || [password length] == 0 || [email length] == 0) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                  message:@"Please enter a username, password, and email address!"
                                                  delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        self.signup.enabled = YES;
        
    }else if ([password length] <= 5){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:@"Please choose a password with more than 5 characters!"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        self.signup.enabled = YES;
    }
    else{ // sign up the new user
        
        MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
        hud.mode = MBProgressHUDModeIndeterminate;
        hud.labelText = @"Registering...";
        [hud show:YES];
        
        self.signup.enabled = NO;
        
        PFUser *newUser = [PFUser  user];
        newUser.username = username;
        newUser.password = password;
        newUser.email = email;
        [newUser signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Sorry!"
                                                                    message:[error.userInfo
                                                               objectForKey:@"error"]
                                                                   delegate:nil
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
                self.signup.enabled = YES;
            }else{ // show the home view tab bar controller
                [[UIApplication sharedApplication] registerForRemoteNotificationTypes:
                 UIRemoteNotificationTypeBadge |
                 UIRemoteNotificationTypeAlert |
                 UIRemoteNotificationTypeSound];

                [self performSegueWithIdentifier:@"findFriends" sender:self];
            }
            [hud hide:YES];
        }];
    }
}

// dismiss the keyboard
- (IBAction)dismissKeyboard:(id)sender {
    [self.activeTextField resignFirstResponder];
}

#pragma mark - KEYBOARD HELPERS
// scrolls selected textview out of the way of the keyboard
- (void)keyboardWasShown:(NSNotification *)notification {
    
    // get the size of the keyboard
    CGSize keyboardSize = [[[notification userInfo] objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    // adjust the bottom content inset of your scroll view by the keyboard height
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

// Set activeTextField to the current active textfield
- (void)textFieldDidBeginEditing:(UITextField *)textField {
    self.activeTextField = textField;
}

// set activeTextField to nil
- (void)textFieldDidEndEditing:(UITextField *)textField {
    self.activeTextField = nil;
}


// dismisses the keybaord
-(void)dismissKeyboard {
    [self.usernameField resignFirstResponder];
    [self.passwordField resignFirstResponder];
    [self.emailField resignFirstResponder];
}

@end
