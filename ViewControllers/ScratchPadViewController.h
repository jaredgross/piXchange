//
//  ScratchPadViewController.h
//  Flashback
//
//  Created by Jared Gross on 11/8/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ScratchPadViewController : UIViewController

@property (nonatomic, weak) UIImage *image;
@property (nonatomic, weak) UIImage *currentImage;
@property (nonatomic, retain) NSString *albumRef;
@property (nonatomic, retain) NSMutableArray *album;
@property (nonatomic, retain) NSString *albumTitle;
@property (nonatomic, retain) NSString *objId;
@property (nonatomic) NSInteger index;
@property (nonatomic) NSInteger albumCount;

@end
