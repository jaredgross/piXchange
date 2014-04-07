//
//  SignupViewController.h
//  piXchange
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SignupViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UIScrollView *theScrollView;
}

@property (nonatomic, assign) IBOutlet UITextField *usernameField;
@property (nonatomic, assign) IBOutlet UITextField *passwordField;
@property (nonatomic, assign) IBOutlet UITextField *emailField;

@end
