//
//  DetailViewController.h
//  Flashback
//
//  Created by Jared Gross on 9/24/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface DetailViewController : UIViewController

@property (nonatomic, retain) UIImage *image;
@property (nonatomic, retain) NSMutableArray *album;
@property (nonatomic, retain) NSString *albumRef;
@property (nonatomic) NSInteger index;
@property (nonatomic, strong) NSString *albumTitle;
@property (nonatomic, strong) NSString *objId;
@property (nonatomic) NSInteger albumCount;

@end
