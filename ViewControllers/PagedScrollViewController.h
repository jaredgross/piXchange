//
//  PagedScrollViewController.h
//  Flashback
//
//  Created by Matt Jared Gross on 11/17/2013.
//  Copyright (c) 2013 Kickin' Appz.. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PagedScrollViewController : UIViewController <UIScrollViewDelegate>

@property (nonatomic, strong) NSMutableArray *album;
@property (nonatomic) NSInteger page;
@property (nonatomic, retain) NSString *albumTitle;
@property (nonatomic, retain) NSString *albumRef;
@property (nonatomic, retain) NSString *objId;
@property (nonatomic) NSInteger albumCount;

@end
