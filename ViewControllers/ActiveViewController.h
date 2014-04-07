//
//  ActiveViewController.h
//  piXchange
//
//  Created by Jared Gross on 1/25/14.
//  Copyright (c) 2014 piXchange, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>
#import <AVFoundation/AVFoundation.h>

@interface ActiveViewController : UIViewController <UIApplicationDelegate>

@property (nonatomic) BOOL eventCreator;
-(void)refresh;
@end
