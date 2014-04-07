//
//  HomeViewController.m
//  piXchange
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import "HomeViewController.h"
#import "UIImage+ImageEffects.h"
#import "QuartzCore/QuartzCore.h"
#import "CollectionViewController.h"
#import "FriendsViewController.h"
#import "ActiveViewController.h"
#import "MBProgressHUD.h"

#define OPTIONS_ALERT 1
#define DELETE_ALERT 2

@interface HomeViewController () <UIPickerViewDataSource, UIPickerViewDelegate>{
    BOOL        albumRemoved;
    NSInteger     albumIndex;
    BOOL        needNewQuery;
}

#pragma mark - Interface Properties
@property (nonatomic, weak) IBOutlet UIImageView *tiltImageView;
@property (nonatomic, weak) IBOutlet UIImageView *blurImageView;
@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UILabel *timerLabel;
@property (nonatomic, weak) IBOutlet UILabel *timerUnitsLabel;

@property (nonatomic) NSCalendar *gregorian;
@property (nonatomic) NSDateFormatter *df;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) NSMutableArray *titlesArray;
@property (nonatomic) NSMutableArray *timersArray;
@property (nonatomic) NSMutableArray *recImagesArray;
@property (nonatomic) NSMutableArray *objsIdArray;
@property (nonatomic) NSMutableArray *userIdsArray;

@property (nonatomic, weak) NSString *albumTitle;
@property (nonatomic, weak) NSString *objId;
@property (nonatomic, weak) NSString *eventID;
@property (nonatomic) NSDate *releaseTime;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

@property (nonatomic, weak) NSArray *NSUDalbum;
- (IBAction)deleteAlbum:(id)sender;

- (IBAction)toggleTabBar:(id)sender;
- (IBAction)showAlbum:(id)sender;

@end

@implementation HomeViewController{
    dispatch_queue_t _draw_queue;
}

#pragma mark - View Controller Life Cycle
- (void)viewDidLoad{
    [super viewDidLoad];

    // set up the view
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.hidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;

    self.recImagesArray = nil;
    self.titlesArray = nil;
    self.timersArray = nil;
    
    needNewQuery = NO;
    albumRemoved = NO;

    // set the date format, calender, and timezone
    self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [self.df setTimeZone:[NSTimeZone systemTimeZone]];
    [self.df setFormatterBehavior:NSDateFormatterBehaviorDefault];
    

    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];

    // load the background image from userDefaults
    if ([NSUD valueForKey:@"capsuleBGImage"]){
        UIImage *image = [UIImage imageWithData:[NSUD valueForKey:@"capsuleBGImage"]];
        self.tiltImageView.image = image;
    }
    else if (self.tiltImageView.image == nil){
            self.recImagesArray = [[NSMutableArray alloc]initWithObjects:
                                   [UIImage imageNamed:@"image1.png"],
                                   [UIImage imageNamed:@"image2.png"],
                                   [UIImage imageNamed:@"image3.png"],
                                   [UIImage imageNamed:@"image4.png"],
                                   [UIImage imageNamed:@"image5.png"],
                                   nil];
            self.tiltImageView.image = [self getRandomImage];
            self.recImagesArray = nil;
    }
    [self setBackgroundImage];
    
    
    if ([NSUD arrayForKey:@"objectIDReference"] != nil){
        // albums data has been stashed to reduce API calls
        NSArray *ids = [NSUD arrayForKey:@"objectIDReference"];
        self.objsIdArray = [[NSMutableArray alloc]initWithArray:ids];
        
        if (self.objsIdArray.count == 0){ // user has no albums to display and the app has already queried parse at least once this launch
            [self setDefaultDataSource]; // set default source
        }
        [self setPicker];
    }

        else{ // user defaults has no saved data
            if (![NSUD objectForKey:@"defaults"]){
                [self queryParseAlbums];
            }
            else{
                [self setDefaultDataSource];
        }
        [self setPicker];
    }

}

-(void)viewWillAppear:(BOOL)animated{
    [self registerEffectForView:self.tiltImageView depth:17];
    self.tiltImageView.clipsToBounds = YES;
}


- (void) queryParseAlbums {
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *currentAlbums = [[NSMutableArray alloc] init];
    NSMutableArray *currentGroupAlbums = [[NSMutableArray alloc] init];
    NSMutableArray *currentTitles = [[NSMutableArray alloc] init];
    NSMutableArray *currentIDs = [[NSMutableArray alloc] init];
    NSMutableArray *currentTimers= [[NSMutableArray alloc] init];
    NSMutableArray *currentObjIDs = [[NSMutableArray alloc] init];
    
    NSMutableArray *releasedAlbums = [[NSMutableArray alloc] init];
    NSMutableArray *releasedIDs = [[NSMutableArray alloc] init];
    NSMutableArray *releasedLocations = [[NSMutableArray alloc] init];
    NSMutableArray *releasedTitles = [[NSMutableArray alloc] init];
    NSMutableArray *releasedDates = [[NSMutableArray alloc] init];
    NSMutableArray *releasedObjIDs = [[NSMutableArray alloc] init];
    
    NSMutableArray *activeAlbums = [[NSMutableArray alloc] init];
    NSMutableArray *activeTitles = [[NSMutableArray alloc] init];
    NSMutableArray *activeIDs = [[NSMutableArray alloc] init];
    NSMutableArray *activeTimers = [[NSMutableArray alloc] init];
    NSMutableArray *activeGroupAlbums = [[NSMutableArray alloc] init];
    NSMutableArray *activeEventObjIDs = [[NSMutableArray alloc] init];
    
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Loading...";
    [hud show:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Events"];
    [query whereKey:@"recipientIds" equalTo:[[PFUser currentUser] objectId]];
    [query orderByDescending:@"createdAt"];
    [query findObjectsInBackgroundWithBlock:^(NSArray *Events, NSError *error){
        
        if (error){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                message:@"The server could not be reached. Please wait a few minutes then try again."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        else{
            if (Events.count == 0){
                [self resetUserDefaults];
                [self setDefaultDataSource];
                [hud hide:YES];
            }
            else{
                for (id obj in Events){
                    NSString *dateRef = [self.df stringFromDate:[NSDate date]];
                    NSDate *now = [self.df dateFromString:dateRef];
                    
                    NSDate *releaseTimer = [obj valueForKey:@"releaseDate"];
                    NSDate *camTimer = [obj valueForKey:@"deadline"];
                    NSString *releaseTime = [self.df stringFromDate:releaseTimer];
                    NSString *date = [self.df stringFromDate:camTimer];
                    NSDate *localizedDeadline = [self.df dateFromString:date];
                    NSDate *localizedRelease = [self.df dateFromString:releaseTime];
                    
                    NSDate *earlierDeadlineDate = [now earlierDate:localizedDeadline];
                    NSDate *earlierReleaseDate = [now earlierDate:localizedRelease];
                    
                    // get the values from Parse
                    NSString *userID = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectId]];
                    NSString *eventTitle = [obj valueForKey:@"title"];
                    NSString *eventID = [obj valueForKey:@"objectId"];
                    //                NSMutableArray *recIDs = [obj valueForKey:@"recipientIds"];
                    
                    if (![earlierDeadlineDate isEqual:localizedDeadline]){ // the Event is still active
                        [releasedObjIDs addObject:[obj valueForKey:@"objectId"]];
                        
                        [activeTimers addObject:localizedDeadline];
                        [activeTitles addObject:eventTitle];
                        [activeIDs addObject:eventID];
                        [NSUD setObject:activeTimers forKey:@"activeDeadlines"];
                        [NSUD setObject:activeTitles forKey:@"activeTitles"];
                        [NSUD setObject:activeIDs forKey:@"activeEventIDs"];
                        [NSUD synchronize];
                        
                        PFQuery *query = [PFQuery queryWithClassName:@"Images"];
                        [query whereKey:@"parent" equalTo:eventID];
                        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            
                            for (NSObject *obj in objects){
                                if ([[obj valueForKey:@"userID"] isEqual:userID]){ // get user images
                                    
                                    if ([obj valueForKey:@"content"] != nil){ // user has photos saved, put them into an array
                                        
                                        PFFile *file = [obj valueForKey:@"content"];
                                        //                                   file = [obj valueForKey:userID];
                                        
                                        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                            
                                            //   NSData *data = [file getData];
                                            NSMutableArray *userImages = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                            
                                            if (userImages.count != 0 && userImages != nil){
                                                [activeAlbums addObject:userImages];
                                            }
                                            else{
                                                NSMutableArray *array = [[NSMutableArray alloc]initWithCapacity:userImages.count];
                                                [activeAlbums addObject:array];
                                            }
                                            
                                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                            NSString *album = [NSString stringWithFormat:@"%@/activeUserAlbums.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:activeAlbums toFile:album];
                                            
                                            NSString *ids = [NSString stringWithFormat:@"%@/activeEventObjIds.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:activeEventObjIDs toFile:ids];
                                        }];
                                    }
                                }
                                
                                PFFile *file = [obj valueForKey:@"content"];
                                
                                if (file != nil){
                                    //PFFile *file = [array valueForKey:@"content"];
                                    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                        
                                        // NSData *data = [file getData];
                                        NSMutableArray *images = nil;
                                        images = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                        
                                        if (images != nil){ //|| images.count == 0){
                                            //                                    images = [[NSMutableArray alloc]initWithCapacity:images.count];
                                            //                                    [activeGroupAlbums addObject:images];
                                            //                                }
                                            //                                else{
                                            if (activeGroupAlbums.count == 0) {
                                                [activeGroupAlbums addObject:images];
                                            }
                                            else if (activeGroupAlbums.count > 0){
                                                for (NSMutableArray *album in activeGroupAlbums){
                                                    if (album.count > 0){
                                                        NSObject *object = [album objectAtIndex:0];
                                                        NSString *ID = [object valueForKey:@"objID"];
                                                        if ([eventID isEqual:ID]){
                                                            
                                                            NSInteger count = album.count + images.count;
                                                            NSInteger i = [activeGroupAlbums indexOfObject:album];
                                                            NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:count];
                                                            temp = [[NSMutableArray alloc] initWithArray:album];
                                                            [temp addObjectsFromArray:images];
                                                            [activeGroupAlbums removeObjectAtIndex:i];
                                                            [activeGroupAlbums addObject:temp];
                                                            
                                                            break;
                                                            return;
                                                        }
                                                        
                                                    }
                                                }
                                                [activeGroupAlbums addObject:images];
                                            }
                                            
                                        }
                                        
                                        if (images != nil){
                                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                            NSString *album = [NSString stringWithFormat:@"%@/activeGroupAlbums.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:activeGroupAlbums toFile:album];
                                            [hud hide:YES];
                                            [self setPicker];
                                        }
                                    }];
                                }
                            }
                        }];
                    }
                    
                    else if (([earlierReleaseDate isEqual:releaseTimer]) || (releaseTime == nil)) { // album has been released
                        
                        [releasedTitles addObject:eventTitle];
                        [releasedIDs addObject:eventID];
                        
                        if ([obj valueForKey:@"location"]){
                            [releasedLocations addObject:[obj valueForKey:@"location"]];
                            [NSUD setObject:releasedLocations forKey:@"oldLocationsReference"];
                        }
                        else{
                            [releasedLocations addObject:@""];
                            [NSUD setObject:releasedLocations forKey:@"oldLocationsReference"];
                        }
                        if ([obj valueForKey:@"createdAt"]){
                            [releasedDates addObject:[obj valueForKey:@"createdAt"]];
                            [NSUD setObject:releasedDates forKey:@"oldDatesReference"];
                        }
                        
                        [NSUD setObject:releasedIDs forKey:@"oldIDsReference"];
                        [NSUD setObject:releasedTitles forKey:@"oldTitlesReference"];
                        [NSUD synchronize];
                        
                        
                        //                  for (NSString *ID in recIDs){
                        
                        PFQuery *query = [PFQuery queryWithClassName:@"Images"];
                        [query whereKey:@"parent" equalTo:eventID];
                        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            
                            // NSObject *array = objects;
                            // PFFile *file;
                            if (objects.count == 0 || error){
                                [hud hide:YES];
                                return;
                            }
                            else{
                                for (NSObject *obj in objects){
                                    PFFile *file = [obj valueForKey:@"content"];
                                    if (file != nil){
                                        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                            
                                            NSArray *images = nil;
                                            images = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                            
                                            if (images != nil){
                                                
                                                if (releasedAlbums.count == 0) {
                                                    [releasedAlbums addObject:images];
                                                }
                                                else if (releasedAlbums.count > 0){
                                                    for (NSMutableArray *album in releasedAlbums){
                                                        if (album.count > 0){
                                                            NSObject *obj = [album objectAtIndex:0];
                                                            NSString *ID = [obj valueForKey:@"objID"];
                                                            if ([eventID isEqual:ID]){
                                                                
                                                                NSInteger count = album.count + images.count;
                                                                NSInteger i = [releasedAlbums indexOfObject:album];
                                                                NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:count];
                                                                temp = [[NSMutableArray alloc] initWithArray:album];
                                                                [temp addObjectsFromArray:images];
                                                                [releasedAlbums removeObjectAtIndex:i];
                                                                [releasedAlbums addObject:temp];
                                                                
                                                                break;
                                                                return;
                                                            }
                                                            
                                                        }
                                                    }
                                                    [releasedAlbums addObject:images];
                                                }
                                                
                                            }
                                            
                                            //                                if (images == nil || images.count == 0){
                                            //                                    NSMutableArray *array = [[NSMutableArray alloc]initWithCapacity:images.count];
                                            //                                    [releasedAlbums addObject:array];
                                            //                                }
                                            //                                else{
                                            //                                    [releasedAlbums addObject:images];
                                            //                                }
                                            if ([[obj valueForKey:@"userID"] isEqual:[[PFUser currentUser] objectId]]){ // its a user image - add it to the userImagesArray
                                                [releasedObjIDs addObject:[obj valueForKey:@"objectId"]];
                                            }
                                            
                                            
                                            if (images != nil){
                                                NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                                
                                                NSString *name = [NSString stringWithFormat:@"%@/releasedAlbums.txt", documentsDirectory];
                                                [NSKeyedArchiver archiveRootObject:releasedAlbums toFile:name];
                                                
                                                NSString *str = [NSString stringWithFormat:@"%@/releasedUserObjIDs.txt", documentsDirectory];
                                                [NSKeyedArchiver archiveRootObject:releasedObjIDs toFile:str];
                                            }
                                            
                                            [hud hide:YES];
                                            [self setPicker];
                                        }];
                                        
                                    }
                                    
                                }
                            }
                            
                            //                           for (PFFile *file in [array valueForKey:@"content"]){
                            
                            // NSObject *ob = newFile;
                            
                            
                            
                            //                          newFile = [array valueForKey:@"content"]; //objectAtIndex:0];                            }
                            
                            //                            PFFile *newFile = [[array valueForKey:@"content"]objectAtIndex:0];
                            //                           }
                            
                            //                           PFFile *file = [obj valueForKey:ID];
                            
                            
                            
                            
                            
                        }];
                        
                        
                        //                        if ([obj valueForKey:ID]){
                        //
                        //
                        //                        }
                        //                   }
                    }
                    
                    else if (![earlierReleaseDate isEqual:localizedRelease]){ // album is awaiting timed release
                        
                        
                        [currentTitles addObject:eventTitle];
                        [currentTimers addObject:localizedRelease];
                        [currentIDs addObject:eventID];
                        self.objsIdArray = currentIDs;
                        [NSUD setObject:currentIDs forKey:@"objectIDReference"];
                        [NSUD setObject:currentTimers forKey:@"timerReference"];
                        [NSUD setObject:currentTitles forKey:@"titlesReference"];
                        [NSUD synchronize];
                        
                        
                        
                        PFQuery *query = [PFQuery queryWithClassName:@"Images"];
                        [query whereKey:@"parent" equalTo:eventID];
                        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            
                            for (PFObject *obj in objects){
                                
                                //            for (NSString *ID in recIDs){
                                
                                //  int objectsCount = objects.count;
                                //    if([[obj valueForKey:@"userID"] isEqual:ID]){
                                PFFile *file = [obj valueForKey:@"content"];
                                
                                //  for (int i = 0; i < objects.count; i++){
                                [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                    
                                    NSArray *images = nil;
                                    images = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                    
                                    if (images == nil || images.count == 0){
                                        images = [[NSMutableArray alloc]initWithCapacity:images.count];
                                        [currentGroupAlbums addObject:images];
                                    }
                                    else{
                                        if (currentGroupAlbums.count == 0) {
                                            [currentGroupAlbums addObject:images];
                                        }
                                        else if (currentGroupAlbums.count > 0){
                                            for (NSMutableArray *album in currentGroupAlbums){
                                                if (album.count > 0){
                                                    NSObject *obj = [album objectAtIndex:0];
                                                    NSString *ID = [obj valueForKey:@"objID"];
                                                    if ([eventID isEqual:ID]){
                                                        
                                                        NSInteger count = album.count + images.count;
                                                        NSInteger i = [currentGroupAlbums indexOfObject:album];
                                                        NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:count];
                                                        temp = [[NSMutableArray alloc] initWithArray:album];
                                                        [temp addObjectsFromArray:images];
                                                        [currentGroupAlbums removeObjectAtIndex:i];
                                                        [currentGroupAlbums addObject:temp];
                                                        break;
                                                    }
                                                    
                                                }
                                            }
                                            [currentGroupAlbums addObject:images];
                                        }
                                        
                                        
                                    }
                                    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                    NSString *album = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", documentsDirectory];
                                    [NSKeyedArchiver archiveRootObject:currentGroupAlbums toFile:album];
                                    
                                    [hud hide:YES];
                                    [self startTimer];
                                    [self setPicker];
                                }];
                                
                                //                                   }
                                
                                //    for (obj in objects){
                                
                                if ([[obj valueForKey:@"userID"] isEqual:[[PFUser currentUser] objectId]]){ // get user images
                                    
                                    if ([obj valueForKey:@"content"] != nil){ // user has photos saved, put them into an array
                                        
                                        PFFile *file = [obj valueForKey:@"content"];
                                        //file = [ valueForKey:userID];
                                        NSString *objID = [obj valueForKey:@"objectId"];
                                        
                                        [currentObjIDs addObject:objID];
                                        
                                        //                               PFFile *file = [obj valueForKey:userID];
                                        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                            
                                            NSArray *userImages = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                            
                                            if (userImages == nil || userImages.count == 0){
                                                userImages = [[NSMutableArray alloc]initWithCapacity:userImages.count];
                                            }
                                            
                                            [currentAlbums addObject:userImages];
                                            
                                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                            NSString *album = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:currentAlbums toFile:album];
                                            
                                            NSString *ids = [NSString stringWithFormat:@"%@/currentObjIDs.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:currentObjIDs toFile:ids];
                                            
                                            [self setPicker];
                                            [hud hide:YES];
                                        }];
                                        
                                        [self startTimer];
                                        
                                    }
                                    //                                    }
                                    
                                };
                                
                                //             }
                            }
                            
                            
                            //           }
                        }];
                        
                        
                        //                            if ([obj valueForKey:ID]){
                        //                                PFFile *file = [obj valueForKey:ID];
                        
                        //                                                            }
                        //     }
                        
                        //                    for (NSObject *obj in objects){
                        //                    }
                    }
                    else{
                        [hud hide:YES];
                    }

            }
            
            
            }
        }
    }];
}

-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                        target:self
                                        selector:@selector(refreshTimerLabel)
                                        userInfo:nil
                                        repeats:YES];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    if (alertView.tag == OPTIONS_ALERT){
        if (buttonIndex == 1){
            [self performSegueWithIdentifier:@"new" sender:self];
            self.navigationController.navigationBar.hidden = NO;
        }else if (buttonIndex == 2){
            
            NSArray *caps = [NSUD arrayForKey:@"activeEventIDs"];
            if (caps.count == 0){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [self performSegueWithIdentifier:@"active" sender:self];
        }else if (buttonIndex == 3){
            
            NSArray *caps = [NSUD arrayForKey:@"oldIDsReference"];
            if (caps.count == 0 && needNewQuery == NO){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [self performSegueWithIdentifier:@"released" sender:self];
        }
        else if (buttonIndex == 4){
            [PFUser logOut];
            [self performSegueWithIdentifier:@"exit" sender:self];
        }
    }
    else if (alertView.tag == DELETE_ALERT){
        if (buttonIndex == 1){ // user confirmed the delete
            [self deleteTheAlbum];
        }
    }
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
        self.releaseTime = [self.timersArray objectAtIndex:row];
        self.albumTitle = [self.titlesArray objectAtIndex:row];
        [self refreshTimerLabel];
    }
}

#pragma mark - ACTIONS
- (IBAction)deleteAlbum:(id)sender {
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                    message:@"This will delete all of your photos from the capsule"
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
            

            NSArray *ids = [events valueForKey:@"recipientIds"];
            self.userIdsArray = [[NSMutableArray alloc]initWithArray:ids];
            
            for (NSString *idREF in self.userIdsArray){
                if ([idREF isEqual:IDref]){
                    [self.userIdsArray removeObject:idREF];
                    break;
                }
            }
            
            NSInteger i = [self.objsIdArray indexOfObject:self.objId];
            [self.titlesArray removeObjectAtIndex:i];
            [self.objsIdArray removeObjectAtIndex:i];
            [self.timersArray removeObjectAtIndex:i];
            [self.pickerView reloadAllComponents];
            
            NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
            if (self.objsIdArray.count == 0){
                [NSUD setObject:nil forKey:@"titlesReference"];
                [NSUD setObject:nil forKey:@"timerReference"];
                [NSUD setObject:nil forKey:@"objectIDReference"];
            }else{
                [NSUD setObject:self.titlesArray forKey:@"titlesReference"];
                [NSUD setObject:self.timersArray forKey:@"timerReference"];
                [NSUD setObject:self.objsIdArray forKey:@"objectIDReference"];
            }
            [NSUD synchronize];
            
            [events setObject:self.userIdsArray forKey:@"recipientIds"];
            [events saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                if (succeeded == YES){
                    PFQuery *query = [PFQuery queryWithClassName:@"Images"];
                    [query whereKey:@"parent" equalTo:self.objId];
                    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                        
                        if(error){
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                                message:@"Please try the action again."
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                            [alertView show];
                            [hud hide:YES];
                        }
                        else if (objects.count == 0){
                            [self setPicker];
                            [self.pickerView reloadAllComponents];
                            [hud hide:YES];
                            return;
                        }
                        else {
                            for (PFObject *obj in objects){
                                
                                if ([[obj valueForKey:@"userID"] isEqual:IDref]){
                                    [obj deleteInBackground];
                                }
                                
                                NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
                                if(self.objsIdArray.count == 0){
                                    [NSUD setObject:nil forKey:@"timerReference"];
                                    [NSUD setObject:nil forKey:@"titlesReference"];
                                    [NSUD setObject:nil forKey:@"objectIDReference"];
                                }
                                else{
                                    [NSUD setObject:self.timersArray forKey:@"timerReference"];
                                    [NSUD setObject:self.titlesArray forKey:@"titlesReference"];
                                    [NSUD setObject:self.objsIdArray forKey:@"objectIDReference"];
                                }
                                [NSUD synchronize];
                                
                                // get the album from archives
                                NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                
                                NSString *ids = [NSString stringWithFormat:@"%@/currentObjIDs.txt", documentsDirectory];
                                NSString *grp = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", documentsDirectory];
                                NSString *usr = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", documentsDirectory];
                                
                                NSArray *groupAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:grp];
                                NSArray *userAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:usr];
                                NSArray *eventIds = [NSKeyedUnarchiver unarchiveObjectWithFile:ids];
                                
                                NSMutableArray *groupsMutable = [[NSMutableArray alloc]initWithArray:groupAlbums];
                                NSMutableArray *userMutable = [[NSMutableArray alloc]initWithArray:userAlbums];
                                NSMutableArray *eventIdsMutable = [[NSMutableArray alloc]initWithArray:eventIds];
                                
                                [groupsMutable removeObjectAtIndex:i];
                                [userMutable removeObjectAtIndex:i];
                                [eventIdsMutable removeObjectAtIndex:i];
                                
                                [NSKeyedArchiver archiveRootObject:groupsMutable toFile:grp];
                                [NSKeyedArchiver archiveRootObject:userMutable toFile:usr];
                                [NSKeyedArchiver archiveRootObject:eventIdsMutable toFile:ids];
                                
                                albumRemoved = YES;
                                albumIndex = i;
                                
                                [self setPicker];
                                [self.pickerView reloadAllComponents];
                                [hud hide:YES];
                            }
                        }
                    }];
                }
            }];
        }
    }];
}


- (IBAction)toggleTabBar:(id)sender {
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"OPTIONS"
                                                    message:@""
                                                   delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"NEW EVENT", @"ACTIVE EVENTS", @"SHARED ALBUMS",@"Logout", nil];
    alert.tag = OPTIONS_ALERT;
    [alert show];
}

- (IBAction)showAlbum:(id)sender {
    
    if (self.objsIdArray.count > 0){
        [self performSegueWithIdentifier:@"showAlbum" sender:self];
    }
}


-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    
    if (motion == UIEventSubtypeMotionShake){
        
        if (self.recImagesArray == nil || self.recImagesArray.count == 0){
            
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *str1 = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", documentsDirectory];
            self.recImagesArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str1];
            
            if (self.recImagesArray.count == 0 || self.recImagesArray == nil){
                [self setDefaultDataSource];
            }
        }
    }
}

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake){

            NSMutableArray *groupAlb = [[NSMutableArray alloc]init];
            NSMutableArray *images = [[NSMutableArray alloc]init];
            
            for (NSArray *array in self.recImagesArray){
                
                if (array.count > 0){
                    NSObject *obj1 = [array objectAtIndex:0];
                    
                    if ([[obj1 valueForKey:@"objID"] isEqual:self.objId]){
                        
                        NSInteger i = [self.recImagesArray indexOfObject:array];
                        groupAlb = [self.recImagesArray objectAtIndex:i];
                        break;
                    }
                }
            }
        self.recImagesArray = nil;
        
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

        self.recImagesArray = images;
        
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
        
        self.recImagesArray = nil;
        
        // save the image to UserDefaults to load next app launch
        NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
        NSData *imageData = UIImageJPEGRepresentation(self.tiltImageView.image, .8f);
        [NSUD setObject:imageData forKey:@"capsuleBGImage"];
        [NSUD synchronize];
        
        
    }
}

- (UIImage *)getRandomImage {
    return [self recImagesArray][arc4random_uniform((uint32_t)[self recImagesArray].count)];
}

#pragma mark - HELPERS
-(void)setPicker{
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    if([NSUD arrayForKey:@"titlesReference"]){
        NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
        NSArray *timers = [NSUD arrayForKey:@"timerReference"];
        NSArray *titles = [NSUD arrayForKey:@"titlesReference"];
        NSArray *ID = [NSUD arrayForKey:@"objectIDReference"];
        
        self.titlesArray = [[NSMutableArray alloc]initWithArray:titles];
        self.timersArray = [[NSMutableArray alloc]initWithArray:timers];
        self.objsIdArray = [[NSMutableArray alloc]initWithArray:ID];
    }
    
    if ((self.objsIdArray.count == 0 || self.objsIdArray == nil) && albumRemoved == NO){
        self.titlesArray = [NSMutableArray arrayWithObject:@"No Time Capsules"];
        self.deleteButton.enabled = NO;
    }
    else{
        self.deleteButton.enabled = YES;
        
        if (albumRemoved == NO){
            self.objId = [self.objsIdArray objectAtIndex:0];
            self.releaseTime = [self.timersArray objectAtIndex:0];
            self.albumTitle = [self.titlesArray objectAtIndex:0];
            [self startTimer];
        }
        else if (albumRemoved == YES){
            if (albumIndex != 0){
                NSInteger newIndex = albumIndex - 1;
                self.objId = [self.objsIdArray objectAtIndex:newIndex];
                self.releaseTime = [self.timersArray objectAtIndex:newIndex];
                self.albumTitle = [self.titlesArray objectAtIndex:newIndex];
            }
            else{
                if (self.objsIdArray.count > 0){
                    self.objId = [self.objsIdArray objectAtIndex:0];
                    self.releaseTime = [self.timersArray objectAtIndex:0];
                    self.albumTitle = [self.titlesArray objectAtIndex:0];
                }
                
                if (self.objId == nil){
                    [self.timer invalidate];
                    self.timer = nil;
                    self.timersArray = [NSMutableArray arrayWithObject:@"00:00:00:00:00:00"];
                    self.titlesArray = [NSMutableArray arrayWithObject:@"No Time Capsules"];
                    self.deleteButton.enabled = NO;
                }
                else{
                    [self startTimer];
                }
            }
            albumRemoved = NO;
        }
    }
    
    [self.pickerView reloadAllComponents];
}

- (void)setDefaultDataSource{

    self.timersArray = [NSMutableArray arrayWithObject:@"00:00:00:00:00:00"];

    if (self.titlesArray.count == 0){
        self.titlesArray = [NSMutableArray arrayWithObject:@"No Time Capsules"];
        
        [self.pickerView reloadAllComponents];
    }
}


-(void)uploadUserDefaults{
    
    // show progress tracker
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Synching images...";
    [hud show:YES];

    // get data to save to Parse
    NSString *userIDref = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectId]];
    
    NSArray *objIdsArray = [self.NSUDalbum valueForKey:@"objID"];
    NSString *eventID = [objIdsArray objectAtIndex:0];
    
    NSData *objsData = [NSKeyedArchiver archivedDataWithRootObject:self.NSUDalbum];
    PFFile *file = [PFFile fileWithData:objsData];

    // set data to Parse and save
    PFObject *userImages = [PFObject objectWithClassName:@"Images"];
    userImages[@"content"] = file;
    userImages[@"userID"] = userIDref;
    userImages[@"parent"] = eventID;

    [userImages saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        
        if (error){ // show alery
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                message:@"Your photos could not be saved."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        else{
            
/* instead of query parse below - need to get all the info from parse while in this method to save parse call */
            
            [self queryParseAlbums];
            [self resetUserDefaults];
        }
        [hud hide:YES];
    }];
}

-(void)resetUserDefaults{
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];

    [NSUD setObject:nil forKey:@"oldAlbumReference"];
    [NSUD setObject:nil forKey:@"oldLocationsReference"];
    [NSUD setObject:nil forKey:@"oldTitlesReference"];
    [NSUD setObject:nil forKey:@"oldDatesReference"];
    
    [NSUD synchronize];
}

- (void)refreshTimerLabel {
    
    if (self.timer != nil){
        // Compare the 'real' time (now) against the date/time the album is to be released
        NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                                       fromDate:[NSDate date]
                                                                         toDate:self.releaseTime
                                                                        options:NSWrapCalendarComponents];
        // Get the integer value of each comparison unit
        NSInteger years = [dateComparisonComponents year];
        NSInteger months = [dateComparisonComponents month];
        NSInteger days = [dateComparisonComponents day];
        NSInteger hours = [dateComparisonComponents hour];
        NSInteger minutes = [dateComparisonComponents minute];
        NSInteger seconds = [dateComparisonComponents second];
        
        // Format the values for display as a string
        self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld:%02ld:%02ld:%02ld",
                                (long)years,
                                (long)months,
                                (long)days,
                                (long)hours,
                                (long)minutes,
                                (long)seconds];
        
        // Check the individual components to know when the timer is up
        if ((long)years <= 0 && (long)months <= 0 && (long)days <= 0 && (long)hours <= 0 && (long)minutes <= 0 && (long)seconds <= 0) {
            
            if (self.objId != nil){
                NSInteger i = [self.titlesArray indexOfObject:self.albumTitle];
                [self.titlesArray removeObjectAtIndex:i];
                [self.objsIdArray removeObjectAtIndex:i];
                [self.timersArray removeObjectAtIndex:i];

                [self.timer invalidate];
                self.timer = nil;
                self.objId = nil;
                
                needNewQuery = YES;
                albumRemoved = YES;
                albumIndex = i;
                
                NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
                
                if (self.objsIdArray.count == 0) {
                    [NSUD setObject:nil forKey:@"titlesReference"];
                    [NSUD setObject:nil forKey:@"objectIDReference"];
                    [NSUD setObject:nil forKey:@"timerReference"];
                }else{
                    [NSUD setObject:self.titlesArray forKey:@"titlesReference"];
                    [NSUD setObject:self.objsIdArray forKey:@"objectIDReference"];
                    [NSUD setObject:self.timersArray forKey:@"timerReference"];
                }
                
                [NSUD setObject:nil forKey:@"oldIDsReference"];
                
                [NSUD setObject:@"yes" forKey:@"needNewQuery"];
                
                [NSUD synchronize];
                
                [self setPicker];
                [self.pickerView reloadAllComponents];
            }
        }

    }
}

- (void)setBackgroundImage {
    UIImage *blur = [self.tiltImageView.image applyLightEffect];
    
    // if blur size is larger (horizontal) than screen dimensions we need to create a new rect and draw only the portion of the image shown from tiltimageview 
    
    
    
    self.blurImageView.image = [self maskImage:blur withMask:[UIImage imageNamed:@"mask"]];
}

- (UIImage*)maskImage:(UIImage *)image withMask:(UIImage *)maskImage { // called from [setBackgroundImage]
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

- (void)registerEffectForView:(UIView *)aView depth:(CGFloat)depth{ // parallax effect
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 568){
        self.hidesBottomBarWhenPushed = YES;
    }
    
    if  ([segue.identifier isEqualToString:@"showAlbum"]) {

        CollectionViewController *cvc = (CollectionViewController *)segue.destinationViewController;
        cvc.objId = self.objId;
        cvc.title = self.albumTitle;
        cvc.albumRef = @"cloud";
    }
    self.titlesArray = nil;
    self.timersArray = nil;
    self.objsIdArray = nil;
    self.blurImageView.image = nil;
    self.tiltImageView.image = nil;
}

@end



         
         
