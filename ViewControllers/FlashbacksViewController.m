//
//  FlashbacksViewController.m
//  piXchange
//
//  Created by Jared Gross on 11/5/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "FlashbacksViewController.h"
#import "UIImage+ImageEffects.h"
#import "QuartzCore/QuartzCore.h"
#import "CollectionViewController.h"
#import "MBProgressHUD.h"

#define DELETE_ALERT 1

@interface FlashbacksViewController () <UIPickerViewDataSource, UIPickerViewDelegate>{
    BOOL        albumRemoved;
    NSInteger    albumIndex;
}

@property (nonatomic, weak) IBOutlet UIImageView *tiltImageView;
@property (nonatomic, weak) IBOutlet UIImageView *blurImageView;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;
@property (nonatomic, weak) IBOutlet UILabel *locationLabel;

@property (nonatomic, retain) NSDateFormatter *dateFormatter;
@property (nonatomic, retain) NSDate *eventDate;

@property (nonatomic, strong) NSMutableArray *titlesArray;
@property (nonatomic, strong) NSMutableArray *datesArray;
@property (nonatomic, retain) NSMutableArray *albumsArray;
@property (nonatomic, retain) NSMutableArray *userIdsArray;
@property (nonatomic, retain) NSMutableArray *objsIdArray;
@property (nonatomic, strong) NSMutableArray *locationsArray;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (nonatomic, retain) NSString *albumTitle;
@property (nonatomic, retain) NSString *location;
@property (nonatomic, retain) NSString *objId;

@property (nonatomic, strong) NSDateFormatter *df;
- (IBAction)deleteButton:(id)sender;

- (IBAction)toggleOptions:(id)sender;
- (IBAction)showAlbum:(id)sender;

@end

@implementation FlashbacksViewController


#pragma mark - VIEW CONTROLLER LIFE CYCLE
- (void)viewDidLoad {
    [super viewDidLoad];

    self.dateFormatter = [[NSDateFormatter alloc]init];
    [self.dateFormatter setDateStyle:NSDateFormatterLongStyle];
    [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
    
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    albumRemoved = NO;
    
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [self.df setTimeZone:[NSTimeZone systemTimeZone]];
    [self.df setFormatterBehavior:NSDateFormatterBehaviorDefault];

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    self.navigationController.navigationBar.hidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    
}

-(void)viewWillAppear:(BOOL)animated{
    
    [self registerEffectForView:self.tiltImageView depth:17];
    self.tiltImageView.clipsToBounds = YES;
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    // load the UserDefaults background image
    if ([NSUD valueForKey:@"sharedBGImage"]){
        UIImage *image = [UIImage imageWithData:[NSUD valueForKey:@"sharedBGImage"]];
        self.tiltImageView.image = image;
    }
    else if (self.tiltImageView.image == nil){
        self.albumsArray = [[NSMutableArray alloc]initWithObjects:
                               [UIImage imageNamed:@"image1.png"],
                               [UIImage imageNamed:@"image2.png"],
                               [UIImage imageNamed:@"image3.png"],
                               [UIImage imageNamed:@"image4.png"],
                               [UIImage imageNamed:@"image5.png"],
                               nil];
        self.tiltImageView.image = [self getRandomImage];
        self.albumsArray = nil;
    }
    [self setBackgroundImage];
    
    if([NSUD arrayForKey:@"oldIDsReference"] != nil){
        
        NSArray *IDs = [NSUD arrayForKey:@"oldIDsReference"];
        self.objsIdArray = [[NSMutableArray alloc]initWithArray:IDs];
        
        if (self.objsIdArray.count == 0){

        }
        
        [self setPicker];
    }
    else{
        
        if (![NSUD objectForKey:@"defaults"]){
            [self queryParse];
            [self setPicker];
        }
        else{
            [self setDefaultDataSource];
        }
        [self setPicker];
    }
}

-(void)queryParse {
    
    NSMutableArray *titles = [[NSMutableArray alloc]init];
    NSMutableArray *dates = [[NSMutableArray alloc]init];
    NSMutableArray *locations = [[NSMutableArray alloc]init];
    NSMutableArray *albums = [[NSMutableArray alloc]init];
    NSMutableArray *IDs = [[NSMutableArray alloc]init];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Loading...";
    [hud show:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Events"];
    [query whereKey:@"recipientIds" equalTo:[[PFUser currentUser] objectId]];
    [query orderByAscending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if (error){
            NSLog(@"Error: %@ %@", error, [error userInfo]);
            [hud hide:YES];
        }
        else{
            if ([objects count] == 0){
                [hud hide:YES];
            }
            else{
                for (id obj in objects){ // Get the values for the objects
                    PFObject *location = [obj valueForKey:@"location"];
                    PFObject *title = [obj valueForKey:@"title"];
                    NSDate *date = [obj valueForKey:@"createdAt"];
                    NSDate *camDeadline = [obj valueForKey:@"deadline"];
                    NSDate *releaseDate = [obj valueForKey:@"releaseDate"];
                    NSString *eventID = [obj valueForKey:@"objectId"];
                    
                    // compare the dates
                    NSString *dateRef = [self.df stringFromDate:[NSDate date]];
                    NSDate *today = [self.df dateFromString:dateRef];
                    NSDate *earlierDate1 = [today earlierDate:releaseDate];
                    NSDate *earlierDate2 = [today earlierDate:camDeadline];
                    
                    if (([earlierDate1 isEqual:releaseDate]) || (releaseDate == nil && [earlierDate2 isEqual:camDeadline])){
                     // the album has been released
                        
                        NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
                        [titles addObject:title];
                        [dates addObject:date];
                        if (location != nil){
                            [locations addObject:location];
                        }else{
                            [locations addObject:@""];
                        }
                        [IDs addObject:eventID];
                        self.objsIdArray = IDs;
                        self.titlesArray = titles;
                        self.locationsArray = locations;
                        self.datesArray = dates;
                        [NSUD setObject:locations forKey:@"oldLocationsReference"];
                        [NSUD setObject:titles forKey:@"oldTitlesReference"];
                        [NSUD setObject:dates forKey:@"oldDatesReference"];
                        [NSUD setObject:IDs forKey:@"oldIDsReference"];
                        [NSUD synchronize];
                        
                        PFQuery *query = [PFQuery queryWithClassName:@"Images"];
                        [query whereKey:@"parent" equalTo:eventID];
                        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            
                            for (NSObject *obj in objects){
                                PFFile *file = [obj valueForKey:@"content"];
                                if (file != nil){
                                    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                        
                                        NSArray *images = nil;
                                        images = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                        
                                        if (images != nil){
                                            
                                            if (albums.count == 0) {
                                                [albums addObject:images];
                                                return;
                                            }
                                            else if (albums.count > 0){
                                                for (NSMutableArray *album in albums){
                                                    if (album.count > 0){
                                                        NSObject *obj = [album objectAtIndex:0];
                                                        NSString *ID = [obj valueForKey:@"objID"];
                                                        if ([eventID isEqual:ID]){
                                                            
                                                            NSInteger count = album.count + images.count;
                                                            NSInteger i = [albums indexOfObject:album];
                                                            NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:count];
                                                            temp = [[NSMutableArray alloc] initWithArray:album];
                                                            [temp addObjectsFromArray:images];
                                                            [albums removeObjectAtIndex:i];
                                                            [albums addObject:temp];
                                                            
                                                            return;
                                                            break;
                                                            
                                                        }
                                                    }
                                                }
                                            }
                                            else{
                                                [albums addObject:images];
                                            }
                                        }
                                        
                                        if ([[obj valueForKey:@"userID"] isEqual:[[PFUser currentUser] objectId]]){
                                            [IDs addObject:[obj valueForKey:@"objectId"]];
                                        }
                                        
                                        
                                        if (images != nil){
                                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                            NSString *name = [NSString stringWithFormat:@"%@/releasedAlbums.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:albums toFile:name];
                                            
                                            NSString *str = [NSString stringWithFormat:@"%@/releasedUserObjIDs.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:IDs toFile:str];
                                            
                                            
                                        }
                                        [self setPicker];
                                        [hud hide:YES];
        
                                    }];
                                }
                            }
                        }];
                    }
                }
                [self setPicker];
                [hud hide:YES];
            }
        }
    }];
}


#pragma mark - PICKER VIEW - DELEGATE
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.titlesArray count];
}

#pragma mark - PICKER VIEW - DATA SOURCE
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return [self.titlesArray objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {

    if (self.objsIdArray.count > 0){
        self.objId = [self.objsIdArray objectAtIndex:row];
        self.eventDate = [self.datesArray objectAtIndex:row];
        self.location = [self.locationsArray objectAtIndex:row];
        self.albumTitle = [self.titlesArray objectAtIndex:row];
        [self refreshLabels];
    }
}

#pragma mark - ACTIONS
- (IBAction)deleteButton:(id)sender {

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                    message:@"This will delete all of your photos for the event"
                                                   delegate:self
                                          cancelButtonTitle:@"NO"
                                          otherButtonTitles:@"YES", nil];
    alert.tag = DELETE_ALERT;
    [alert show];
}
    
-(void)deleteTheAlbum{
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    
    hud.labelText = @"Deleting your images...";
    
    [hud show:YES];
    
    // query Parse to get the event album
    PFQuery *query = [PFQuery queryWithClassName:@"Events"];
    [query getObjectInBackgroundWithId:self.objId block:^(PFObject *events, NSError *error){
        
        if (error){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                message:@"Please try the action again."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            [hud hide:YES];
        }
        else{
            
            
            // get a string reference to the current users ID to delete it from parse recipients array
            NSString *IDref = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectId]];
            NSArray *ids  = [events valueForKey:@"recipientIds"];
            self.userIdsArray = [[NSMutableArray alloc]initWithArray:ids];
            
            for (NSString *idREF in self.userIdsArray){
                if ([idREF isEqual:IDref]){
                    [self.userIdsArray removeObject:idREF];
                    break;
                }
            }
            
            NSInteger i = [self.objsIdArray indexOfObject:self.objId];
            [self.titlesArray removeObjectAtIndex:i];
            [self.datesArray removeObjectAtIndex:i];
            [self.locationsArray removeObjectAtIndex:i];
            [self.objsIdArray removeObjectAtIndex:i];
            [self.pickerView reloadAllComponents];
            
            NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
            if (self.objsIdArray.count == 0){
                [NSUD setObject:nil forKey:@"oldLocationsReference"];
                [NSUD setObject:nil forKey:@"oldTitlesReference"];
                [NSUD setObject:nil forKey:@"oldDatesReference"];
                [NSUD setObject:nil forKey:@"oldIDsReference"];
            }else{
                [NSUD setObject:self.titlesArray forKey:@"oldTitlesReference"];
                [NSUD setObject:self.locationsArray forKey:@"oldLocationsReference"];
                [NSUD setObject:self.datesArray forKey:@"oldDatesReference"];
                [NSUD setObject:self.objsIdArray forKey:@"oldIDsReference"];
            }
            [NSUD synchronize];
            
            [events setObject:self.userIdsArray forKey:@"recipientIds"];
            [events saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                if (succeeded == YES){

                    PFQuery *query = [PFQuery queryWithClassName:@"Images"];
                    [query whereKey:@"parent" equalTo:self.objId];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {

                        if (error){
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                                message:@"Please try the action again."
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                            [alertView show];
                            
                            [self setPicker];
                            [self.pickerView reloadAllComponents];
                            [hud hide:YES];
                        }
                        else if (objects.count == 0){
                                [self setPicker];
                                [self.pickerView reloadAllComponents];
                                [hud hide:YES];
                                return;
                        }
                        else{
                            for (PFObject *obj in objects){
                                
                                if ([[obj valueForKey:@"userID"] isEqual:IDref]){
                                    [obj deleteInBackground];
                                }
                                
                            }
                            NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
                            if (self.objsIdArray.count == 0){
                                [NSUD setObject:nil forKey:@"oldLocationsReference"];
                                [NSUD setObject:nil forKey:@"oldTitlesReference"];
                                [NSUD setObject:nil forKey:@"oldDatesReference"];
                                [NSUD setObject:nil forKey:@"oldIDsReference"];
                            }else{
                                [NSUD setObject:self.titlesArray forKey:@"oldTitlesReference"];
                                [NSUD setObject:self.locationsArray forKey:@"oldLocationsReference"];
                                [NSUD setObject:self.datesArray forKey:@"oldDatesReference"];
                                [NSUD setObject:self.objsIdArray forKey:@"oldIDsReference"];
                            }
                            [NSUD synchronize];
                            
                            // get the album from archives
                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                            
                            NSString *albms = [NSString stringWithFormat:@"%@/releasedAlbums.txt", documentsDirectory];
                            NSString *strs = [NSString stringWithFormat:@"%@/releasedUserObjIDs.txt", documentsDirectory];
                            
                            NSArray *albums = [NSKeyedUnarchiver unarchiveObjectWithFile:albms];
                            NSArray *ids = [NSKeyedUnarchiver unarchiveObjectWithFile:strs];
                            
                            NSMutableArray *albumsMutable = [[NSMutableArray alloc]initWithArray:albums];
                            NSMutableArray *idsMutable = [[NSMutableArray alloc]initWithArray:ids];
                            
                            [albumsMutable removeObjectAtIndex:i];
                            [idsMutable removeObjectAtIndex:i];
                            
                            [NSKeyedArchiver archiveRootObject:albumsMutable toFile:albms];
                            [NSKeyedArchiver archiveRootObject:idsMutable toFile:strs];
                            
                            albumIndex = i;
                            albumRemoved = YES;
                            
                            [self setPicker];
                            [self.pickerView reloadAllComponents];
                            [hud hide:YES];
                        }
                    }];
                }
            }];
            
        }
    }];
    
}


- (IBAction)toggleOptions:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"OPTIONS"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"NEW EVENT", @"ACTIVE EVENTS", @"TIME CAPSULES", @"Logout", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    if (alertView.tag == DELETE_ALERT){
        if (buttonIndex == 1){
            [self deleteTheAlbum];
        }
    }
    
    else{
        if (buttonIndex == 1){ // New
            [self performSegueWithIdentifier:@"new" sender:self];
            self.navigationController.navigationBar.hidden = NO;
        }
        else if (buttonIndex == 2){ // Active
            
            NSArray *caps = [NSUD arrayForKey:@"activeEventIDs"];
            if (caps.count == 0){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [self performSegueWithIdentifier:@"active" sender:self];
        }
        else if (buttonIndex == 3){ // Unreleased
            
            NSArray *caps = [NSUD arrayForKey:@"objectIDReference"];
            NSString *query = [NSUD valueForKey:@"needNewQuery"];
            if (caps.count == 0 && ![query isEqual:@"yes"]){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [NSUD setObject:nil forKey:@"needNewQuery"];
            
            [self performSegueWithIdentifier:@"unreleased" sender:self];
        }
        else if (buttonIndex == 4){ // Logout
            [PFUser logOut];
            [self performSegueWithIdentifier:@"logout1" sender:self];
        }
        [NSUD setObject:nil forKey:@"needsNewQuery"];
        [NSUD synchronize];
    }
    
}


- (IBAction)showAlbum:(id)sender {
    
    if (self.objsIdArray.count > 0 ){
        [self performSegueWithIdentifier:@"showAlbum" sender:self];
        self.blurImageView.image = nil;
        self.tiltImageView.image = nil;
    }
}

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event
{    
    if (motion == UIEventSubtypeMotionShake){
        
        if (self.albumsArray == nil || self.albumsArray.count == 0){
            
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *str1 = [NSString stringWithFormat:@"%@/releasedAlbums.txt", documentsDirectory];
            self.albumsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str1];
        }
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake){
        
        NSMutableArray *groupAlb = [[NSMutableArray alloc]init];
        NSMutableArray *images = [[NSMutableArray alloc]init];
        
        for (NSArray *array in self.albumsArray){
            
            if (array.count > 0){
                NSObject *obj1 = [array objectAtIndex:0];
                
                if ([[obj1 valueForKey:@"objID"] isEqual:self.objId]){
                    
                    NSInteger i = [self.albumsArray indexOfObject:array];
                    groupAlb = [self.albumsArray objectAtIndex:i];
                    break;
                }
            }
        }
        self.albumsArray = nil;
        
        for(NSDictionary *obj in groupAlb){
            
            NSData *tempDat = [obj valueForKey:@"img"];
            UIImage *image = [UIImage imageWithData:tempDat];
            
            [images addObject:image];
        }
        
        if (images.count == 0 ){
            images = [[NSMutableArray alloc]initWithObjects:
                      [UIImage imageNamed:@"image1.png"],
                      [UIImage imageNamed:@"image2.png"],
                      [UIImage imageNamed:@"image3.png"],
                      [UIImage imageNamed:@"image4.png"],
                      [UIImage imageNamed:@"image5.png"],
                      nil];
        }
        
        self.albumsArray = images;
        
        // make sure to not repeat the same image in the view
        UIImage *randomImage;
        randomImage = [self getRandomImage];
        NSData *randomData = UIImageJPEGRepresentation(randomImage, 1.0f);
        
        UIImage *current = self.tiltImageView.image;
        NSData *currentData = UIImageJPEGRepresentation(current, 1.0f);
        
        if ([randomData isEqual:currentData]){
            randomImage = [self getRandomImage];
        }
        
        self.tiltImageView.image = randomImage;

        [self setBackgroundImage];
        
        self.albumsArray = nil;
        
        // save the image to UserDefaults to load next app launch
        NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
        NSData *imageData = UIImageJPEGRepresentation(self.tiltImageView.image, .8f);
        [NSUD setObject:imageData forKey:@"sharedBGImage"];
        [NSUD synchronize];
    }
}

- (UIImage *)getRandomImage {
    return [self albumsArray][arc4random_uniform((uint32_t)[self albumsArray].count)];
}

#pragma mark - HELPERS

-(void)setPicker{ // provide the data for whichever album is initially selected
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    if([NSUD arrayForKey:@"oldIDsReference"]){
        NSArray *locations = [NSUD arrayForKey:@"oldLocationsReference"];
        NSArray *titles = [NSUD arrayForKey:@"oldTitlesReference"];
        NSArray *dates = [NSUD arrayForKey:@"oldDatesReference"];
        NSArray *IDs = [NSUD arrayForKey:@"oldIDsReference"];
        
        self.titlesArray = [[NSMutableArray alloc]initWithArray:titles];
        self.locationsArray = [[NSMutableArray alloc]initWithArray:locations];
        self.datesArray = [[NSMutableArray alloc]initWithArray:dates];
        self.objsIdArray = [[NSMutableArray alloc]initWithArray:IDs];
    }

    if (self.objsIdArray == nil || self.objsIdArray.count == 0){
        self.titlesArray = [NSMutableArray arrayWithObject:@"No Shared Albums"];
        self.deleteButton.enabled = NO;
    }
    else{
        self.deleteButton.enabled = YES;
        
        if (albumRemoved == NO){
            self.objId = [self.objsIdArray objectAtIndex:0];
            self.location = [self.locationsArray objectAtIndex:0];
            self.albumTitle = [self.titlesArray objectAtIndex:0];
            self.eventDate = [self.datesArray objectAtIndex:0];
        }
        else{
            if (albumRemoved == YES){
                if (albumIndex != 0){
                    NSInteger newIndex = albumIndex - 1;
                    self.objId = [self.objsIdArray objectAtIndex:newIndex];
                    self.location = [self.locationsArray objectAtIndex:newIndex];
                    self.albumTitle = [self.titlesArray objectAtIndex:newIndex];
                    self.eventDate = [self.datesArray objectAtIndex:newIndex];
                }
                else{
                    self.objId = [self.objsIdArray objectAtIndex:0];
                    self.location = [self.locationsArray objectAtIndex:0];
                    self.albumTitle = [self.titlesArray objectAtIndex:0];
                    self.eventDate = [self.datesArray objectAtIndex:0];
                }
                albumRemoved = NO;
            }
        }
    }
    [self.pickerView reloadAllComponents];
    [self refreshLabels];
}

-(void)refreshLabels {
    if (self.eventDate == nil){
        self.dateLabel.text = [self.dateFormatter stringFromDate:[NSDate date]];
    }
    else{
        self.dateLabel.text = [self.dateFormatter stringFromDate:self.eventDate];
    }
    self.locationLabel.text = self.location;
}

- (void)setBackgroundImage {
    UIImage *blur = [self.tiltImageView.image applyLightEffect];
    self.blurImageView.image = [self maskImage:blur withMask:[UIImage imageNamed:@"mask"]];
}

- (UIImage*)maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    CGImageRef imgRef = [image CGImage];
    CGImageRef maskRef = [maskImage CGImage];
    CGImageRef actualMask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                              CGImageGetHeight(maskRef),
                                              CGImageGetBitsPerComponent(maskRef),
                                              CGImageGetBitsPerPixel(maskRef),
                                              CGImageGetBytesPerRow(maskRef),
                                              CGImageGetDataProvider(maskRef), NULL, false);
    
    CGImageRef masked = CGImageCreateWithMask(imgRef, actualMask);
    UIImage *retVal =[UIImage imageWithCGImage:masked];
    CGImageRelease(masked);
    CGImageRelease(actualMask);
    
    return retVal;
}

- (void)registerEffectForView:(UIView *)aView depth:(CGFloat)depth; {
	UIInterpolatingMotionEffect *effectX;
	UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	effectX.maximumRelativeValue = @(depth);
	effectX.minimumRelativeValue = @(-depth);
	effectY.maximumRelativeValue = @(depth);
	effectY.minimumRelativeValue = @(-depth);
	
	[aView addMotionEffect:effectX];
	[aView addMotionEffect:effectY];
}


- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 568){
        self.hidesBottomBarWhenPushed = YES;
    }
    
    if  ([segue.identifier isEqualToString:@"showAlbum"]) {

        CollectionViewController *cv = (CollectionViewController *)segue.destinationViewController;
        cv.objId = self.objId;
        cv.title = self.albumTitle;
        cv.albumRef = @"dropped";
    }
    
    self.datesArray = nil;
    self.titlesArray = nil;
    self.locationsArray = nil;
    self.objsIdArray = nil;
    self.blurImageView.image = nil;
    self.tiltImageView.image = nil;
}

- (void)setDefaultDataSource{
    
    self.eventDate = [NSDate date];
    [self refreshLabels];
    
    if (self.titlesArray.count == 0){
        self.titlesArray = [NSMutableArray arrayWithObject:@"No Shared Events"];
        
        [self.pickerView reloadAllComponents];
    }
}
                           

@end
