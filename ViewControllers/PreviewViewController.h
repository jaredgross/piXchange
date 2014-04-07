//
//  PreviewViewController.h
//  Flashback
//
//  Created by Jared Gross on 12/9/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PreviewViewController : UIViewController
@property (nonatomic, retain) UIImage *image;
@property (nonatomic, strong) NSString *albumRef;
@property (nonatomic, retain) NSMutableArray *album;
@property (nonatomic, retain) NSString *vidCheck;
@property (nonatomic, retain) NSString *objID;
@property (nonatomic, retain) NSDate *startDate;

@end
