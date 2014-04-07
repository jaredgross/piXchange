//
//  CollectionViewController.h
//  Flashback
//
//  Created by Jared Gross on 10/11/13.
//  Copyright (c) 2013 Kickin' Apps. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Parse/Parse.h>

@interface CollectionViewController : UICollectionViewController

@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *albumRef;
@property (nonatomic, retain) NSString *objId;
@property (nonatomic) NSInteger albumCount;

@property (nonatomic, strong) NSMutableArray *album;

@end
