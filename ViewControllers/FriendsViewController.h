//
//  FriendsViewController.h
//  Flashback
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@class PFUser;
@class PFRelation;

@interface FriendsViewController : UIViewController <UINavigationControllerDelegate, UITableViewDataSource, UITableViewDelegate, UIImagePickerControllerDelegate>


@property (nonatomic, copy) NSString *theTitle;
@property (nonatomic, strong) UIImage *image;
@property (nonatomic, strong) NSString *albumRef;
@property (nonatomic, copy) NSString *objId;
@property (nonatomic, strong) NSMutableArray *album;
@property (nonatomic, strong) NSDate *startDate;

#pragma mark - Image Picker Properties
@property (nonatomic, strong) UIViewController *actionSheet;

- (IBAction)showPreview:(id)sender;
- (IBAction)cancelButton:(id)sender;
- (IBAction)timedCapture:(id)sender;
- (IBAction)captureImage:(id)sender;
- (IBAction)flipCamera:(id)sender;
- (IBAction)toggleFlash:(id)sender;
- (IBAction)addFriends:(id)sender;
- (IBAction)showMessenger:(id)sender;

- (void)uploadAlbum;

-(IBAction)addOrInviteButtonTapped:(id)sender;
- (UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height;

@end

