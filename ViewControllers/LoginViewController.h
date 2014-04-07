//
//  LoginViewController.h
//  piXchange
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LoginViewController : UIViewController <UITextFieldDelegate> {
    IBOutlet UIScrollView *theScrollView;
}

@property (weak, nonatomic) IBOutlet UITextField *usernameField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;

@end
