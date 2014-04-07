//
//  ActiveViewController.m
//  piXchange
//
//  Created by Jared Gross on 1/25/14.
//  Copyright (c) 2014 piXchange, LLC. All rights reserved.
//


#import "ActiveViewController.h"
#import "UIImage+ImageEffects.h"
#import "QuartzCore/QuartzCore.h"
#import "FriendsViewController.h"
#import "FlashbacksViewController.h"
#import "MBProgressHUD.h"

#define DELETE_ALERT 1

@interface ActiveViewController () <UIPickerViewDataSource, UIPickerViewDelegate>{
    BOOL    albumRemoved;
    NSInteger     albumIndex;
    BOOL    needNewQuery;
}

@property (weak, nonatomic) IBOutlet UIButton *optionsButton;
@property (weak, nonatomic) IBOutlet UIButton *trashButton;

@property (weak, nonatomic) IBOutlet UIImageView *tutorialImageView;

@property (nonatomic, weak) IBOutlet UIPickerView *pickerView;
@property (nonatomic, weak) IBOutlet UIImageView *tiltImageView;
@property (nonatomic, weak) IBOutlet UIImageView *blurImageView;
@property (nonatomic, weak) IBOutlet UILabel *timerLabel;
@property (nonatomic, weak) IBOutlet UILabel *unitsLabel;

@property (nonatomic) NSCalendar *gregorian;
@property (nonatomic) NSDateFormatter *df;
@property (nonatomic) NSTimer *timer;

@property (nonatomic) NSMutableArray *activeTitles;
@property (nonatomic) NSMutableArray *activeDeadlines;
@property (nonatomic) NSMutableArray *activeEventIDs;
@property (nonatomic) NSMutableArray *activeGroupAlbums;

@property (nonatomic) NSArray *tutorialScreens;

@property (nonatomic) NSMutableArray *userIdsArray;

@property (nonatomic) NSString *albumTitle;
@property (nonatomic) NSString *objId;
@property (nonatomic) NSDate *deadline;

@property (nonatomic, weak) NSArray *NSUDalbum;
@property (nonatomic) NSMutableArray *objsIdArray;


@property (weak, nonatomic) IBOutlet UIButton *nextPageButton;
@property (weak, nonatomic) IBOutlet UIButton *backPageButton;
@property (weak, nonatomic) IBOutlet UIButton *exitTutorialButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;

- (IBAction)pageFoward:(id)sender;
- (IBAction)pageBack:(id)sender;
- (IBAction)exitTutorial:(id)sender;
- (IBAction)joinEvent:(id)sender;
- (IBAction)toggleOptions:(id)sender;
- (IBAction)deleteButton:(id)sender;

@end

@implementation ActiveViewController 

#pragma mark - VIEW CONTROLLER LIFE CYCLE
- (void)viewDidLoad{
    [super viewDidLoad];
    
    // hide tutorial controls -- do this stuff in inderface builder to get it off code
    self.tutorialImageView.hidden = YES;
    self.nextPageButton.hidden = YES;
    self.backPageButton.hidden = YES;
    self.exitTutorialButton.hidden = YES;
    
    if (![PFUser currentUser]){ // check for a current username
        [self performSegueWithIdentifier:@"logout" sender:self];
        return;
    }
    
    albumRemoved = NO;
    needNewQuery = NO;
    
    self.navigationController.navigationBar.hidden = YES;
    self.tabBarController.tabBar.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];

    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    // establish the calendar and time zone to use for date formatting
    self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [self.df setTimeZone:[NSTimeZone systemTimeZone]];
    [self.df setFormatterBehavior:NSDateFormatterBehaviorDefault];

    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    if (![NSUD valueForKey:@"mainTutorial"]){ // show tutorial on very first launch only
        
        self.trashButton.enabled = NO;
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        if (screenSize.height == 568){
            self.tutorialScreens = [[NSMutableArray alloc]initWithObjects:
                                    [UIImage imageNamed:@"piXchange_tutorial_screen1_i5"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen2_i5"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen3_i5"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen4_i5"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen5_i5"],
                                    nil];
        }
        else if (screenSize.height == 480){
            self.tutorialScreens = [[NSMutableArray alloc]initWithObjects:
                                    [UIImage imageNamed:@"piXchange_tutorial_screen1_i4"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen2_i4"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen3_i4"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen4_i4"],
                                    [UIImage imageNamed:@"piXchange_tutorial_screen5_i4"],
                                    nil];
        }
        albumIndex = 0;
        
        NSTimer *cameraTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(tutorialAlert)
                                                        userInfo:nil
                                                         repeats:NO];
        
        [[NSRunLoop mainRunLoop] addTimer:cameraTimer forMode:NSDefaultRunLoopMode];
    }
    
    // set the background image
    if ([NSUD valueForKey:@"activeBGImage"]){ // set background image from userDefaults
        UIImage *image = [UIImage imageWithData:[NSUD valueForKey:@"activeBGImage"]];
        self.tiltImageView.image = image;
    }
    else{ // set a standard defualt image for the background
        self.activeGroupAlbums = [[NSMutableArray alloc]initWithObjects:
                                  [UIImage imageNamed:@"image1.png"],
                                  [UIImage imageNamed:@"image2.png"],
                                  [UIImage imageNamed:@"image3.png"],
                                  [UIImage imageNamed:@"image4.png"],
                                  [UIImage imageNamed:@"image5.png"],
                                  nil];
        self.tiltImageView.image = [self getRandomImage];
        self.activeGroupAlbums = nil;
    }
    [self setBackgroundImage];
    
    // Check user defaults for data --> should return nil unless user has unsaved data from a previous launch
    self.NSUDalbum = [NSUD arrayForKey:@"album"];
    
    if (self.NSUDalbum.count != 0){ // user has previous unsaved data
        [self uploadUserDefaults]; // upload it
        return; //  already queriedParse in uploadUserDefaults - return to end
    }
    else if (self.eventCreator == YES){
        [self queryParseForAllEvents];
    }
    else{
        if ([NSUD arrayForKey:@"activeEventIDs"] != nil){
            // albums data has been stashed to reduce API calls
            NSArray *ids = [NSUD arrayForKey:@"activeEventIDs"];
            self.activeEventIDs = [[NSMutableArray alloc]initWithArray:ids];
        }else{
            if (![NSUD objectForKey:@"defaults"]){
                [self queryParseForAllEvents];
            }
            else{
                [self setDefaultDataSource];
            }
        }
    }
    
    [self setPicker];
}

-(void)viewWillAppear:(BOOL)animated{
    [self registerEffectForView:self.tiltImageView depth:17];
    self.tiltImageView.clipsToBounds = YES;
}

-(void)refresh{ // called when user receives a PUSH notification to refresh the UI ** NOT WORKING PROPERLY
    [self queryParseForAllEvents];
}

-(void)tutorialAlert{
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    self.optionsButton.enabled = NO;
    self.trashButton.enabled = NO;
    self.tutorialImageView.hidden = NO;
    self.nextPageButton.hidden = NO;
    self.backPageButton.hidden = YES;
    self.exitTutorialButton.hidden = NO;
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 568){
        self.tutorialImageView.image = [UIImage imageNamed:@"piXchange_tutorial_screen1_i5"];
    }else{
        self.tutorialImageView.image = [UIImage imageNamed:@"piXchange_tutorial_screen1_i4"];
        self.tutorialImageView.bounds = [[UIScreen mainScreen] bounds];
        self.tutorialImageView.center = CGPointMake(160, 240);
        self.nextPageButton.center = CGPointMake(265,450);
        self.backPageButton.center = CGPointMake(60,450);
        
    }
}




- (void) queryParseForAllEvents {
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *currentAlbums = [[NSMutableArray alloc] init];
    NSMutableArray *currentUserAlbums = [[NSMutableArray alloc] init];
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
    NSMutableArray *activeEventUserObjIDs = [[NSMutableArray alloc] init];
    
    
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
                                                                message:@""
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            [hud hide:YES];
        }
        
        else{
            
            if (Events.count == 0){
                
                [NSUD setObject:@"1" forKey:@"defaults"];
                //           [self resetUserDefaults];
            
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
                    
                    if (![earlierDeadlineDate isEqual:localizedDeadline]){ // the Event is still active
                        
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
                            
                            
                            
                            if (objects.count == 0 || objects == nil){
                                [self setPicker];
                                [self.pickerView reloadAllComponents];
                                [hud hide:YES];
                            }
                            else{
                                for (NSObject *obj in objects){
                                    if ([[obj valueForKey:@"userID"] isEqual:userID]){ // get user images
                                        
                                        [activeEventUserObjIDs addObject:[obj valueForKey:@"objectId"]];
                                        
                                        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                        NSString *idss = [NSString stringWithFormat:@"%@/activeEventObjIds.txt", documentsDirectory];
                                        [NSKeyedArchiver archiveRootObject:activeEventUserObjIDs toFile:idss];
                                        
                                        if ([obj valueForKey:@"content"] != nil){ // user has photos saved, put them into an array
                                            
                                            PFFile *file = [obj valueForKey:@"content"];
                                            
                                            [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                                
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
                                                
                                                [self setPicker];
                                                [self.pickerView reloadAllComponents];
                                                [self refreshTimerLabel];
                                            }];
                                        }
                                    }
                                    
                                    PFFile *file = [obj valueForKey:@"content"];
                                    
                                    if (file != nil){
                                        
                                        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                            
                                            NSMutableArray *images = nil;
                                            images = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                            
                                            if (images != nil){
                                                
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
                                                [self.pickerView reloadAllComponents];
                                                [self refreshTimerLabel];
                                            }
                                        }];
                                    }
                                }
                            }
                        }];
                    }
                    
                    else if (localizedRelease == nil || [earlierReleaseDate isEqual:localizedRelease]){ // been released
                        
                        
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
                        
                        PFQuery *query = [PFQuery queryWithClassName:@"Images"];
                        [query whereKey:@"parent" equalTo:eventID];
                        [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
                            
                            if (objects.count == 0 || error){
                                [hud hide:YES];
                                [self setPicker];
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
                                                    return;
                                                }
                                                else if (releasedAlbums.count > 0){
                                                    for (NSMutableArray *album in releasedAlbums){
                                                        if (album.count > 0){
                                                            NSObject *obj = [album objectAtIndex:0];
                                                            NSString *ID = [obj valueForKey:@"objID"];
                                                            if ([eventID isEqual:ID]){
                                                                
                                                                NSInteger count = album.count + images.count;
                                                                NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:count];
                                                                temp = [[NSMutableArray alloc] initWithArray:album];
                                                                [temp addObjectsFromArray:images];
                                                                [releasedAlbums replaceObjectAtIndex:0 withObject:temp];
                                                                
                                                                break;
                                                                return;
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            if ([[obj valueForKey:@"userID"] isEqual:[[PFUser currentUser] objectId]]){
                                                [releasedObjIDs addObject:[obj valueForKey:@"objectId"]];
                                            }
                                            
                                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                            
                                            NSString *name = [NSString stringWithFormat:@"%@/releasedAlbums.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:releasedAlbums toFile:name];
                                            
                                            NSString *str = [NSString stringWithFormat:@"%@/releasedUserObjIDs.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:releasedObjIDs toFile:str];
                                            
                                            [hud hide:YES];
                                        }];
                                    }
                                }
                            }
                        }];
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
                                
                                NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                
                                
                                PFFile *file = [obj valueForKey:@"content"];
                                if (file != nil){
                                    [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                        
                                        NSArray *images = nil;
                                        images = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                        
                                        if (images != nil){
                                            
                                            if (currentAlbums.count == 0) {
                                                [currentAlbums addObject:images];
                                            }
                                            else if (currentAlbums.count > 0){
                                                for (NSMutableArray *album in currentAlbums){
                                                    if (album.count > 0){
                                                        NSObject *obj = [album objectAtIndex:0];
                                                        NSString *ID = [obj valueForKey:@"objID"];
                                                        if ([eventID isEqual:ID]){
                                                            
                                                            NSInteger count = album.count + images.count;
                                                            NSInteger i = [currentAlbums indexOfObject:album];
                                                            NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:count];
                                                            temp = [[NSMutableArray alloc] initWithArray:album];
                                                            [temp addObjectsFromArray:images];
                                                            [currentAlbums removeObjectAtIndex:i];
                                                            [currentAlbums addObject:temp];
                                                            
                                                            break;
                                                            return;
                                                        }
                                                    }
                                                }
                                                [currentAlbums addObject:images];
                                            }
                                        }
                                        
                                        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                        
                                        NSString *name = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", documentsDirectory];
                                        [NSKeyedArchiver archiveRootObject:currentAlbums toFile:name];
                                        
                                        [hud hide:YES];
                                    }];
                                }
                                
                                if ([[obj valueForKey:@"userID"] isEqual:[[PFUser currentUser] objectId]]){ // get user images
                                    
                                    if ([obj valueForKey:@"content"] != nil){ // user has photos saved, put them into an array
                                        
                                        PFFile *file = [obj valueForKey:@"content"];
                                        
                                        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                                            
                                            NSArray *userImages = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                                            
                                            if (userImages == nil || userImages.count == 0){
                                                userImages = [[NSMutableArray alloc]initWithCapacity:userImages.count];
                                            }
                                            
                                            [currentUserAlbums addObject:userImages];
                                            
                                            NSString *objID = [obj valueForKey:@"objectId"];
                                            [currentObjIDs addObject:objID];
                                            NSString *ids = [NSString stringWithFormat:@"%@/currentObjIDs.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:currentObjIDs toFile:ids];
                                            
                                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                                            NSString *album = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", documentsDirectory];
                                            [NSKeyedArchiver archiveRootObject:currentUserAlbums toFile:album];
                                            
                                            [self refreshTimerLabel];
                                            [self setPicker];
                                            [hud hide:YES];
                                        }];
                                    }
                                }
                            }
                        }];
                    }
                    else{
                        [hud hide:YES];
                    }
                }
            }
        }
    }];
}

- (IBAction)pageFoward:(id)sender{
    
    if (albumIndex == 4){
        [self exitTutorial:sender];
    }

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 568){
        if (albumIndex == 0){
            self.backPageButton.hidden = NO;
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:1]];
        }else if(albumIndex == 1){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:2]];
        }else if(albumIndex == 2){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:3]];
        }else if(albumIndex == 3){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:4]];
            [self.nextPageButton setTitle:@"DONE" forState:UIControlStateNormal];
        }
    }else{
        
        if (albumIndex == 0){
            self.backPageButton.hidden = NO;
        [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:1]];
        }else if(albumIndex == 1){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:2]];
        }else if(albumIndex == 2){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:3]];
        }else if(albumIndex == 3){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:4]];
        }

        self.tutorialImageView.center = CGPointMake(160, 240);
        self.nextPageButton.center = CGPointMake(265,450);
        self.backPageButton.center = CGPointMake(60,450);
    }
    NSInteger i = albumIndex;
    albumIndex = i + 1;
    
}

- (IBAction)pageBack:(id)sender{
    
    if ([self.nextPageButton.titleLabel.text isEqual:@"DONE"]){
        [self.nextPageButton setTitle:@"NEXT" forState:UIControlStateNormal];
    }

    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 568){
        if (albumIndex == 1){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:0]];
            self.backPageButton.hidden = YES;
        }else if(albumIndex == 2){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:1]];
        }else if(albumIndex == 3){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:2]];
        }else if (albumIndex == 4){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:3]];
        }
    }
    else{
        
        self.tutorialImageView.center = CGPointMake(160, 240);
        self.nextPageButton.center = CGPointMake(265,450);
        self.backPageButton.center = CGPointMake(60,450);
        
        if (albumIndex == 1){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:0]];
            self.backPageButton.hidden = YES;
        }else if(albumIndex == 2){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:1]];
        }else if(albumIndex == 3){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:2]];
        }else if (albumIndex == 4){
            [self.tutorialImageView setImage:[self.tutorialScreens objectAtIndex:3]];
        }
    }
    NSInteger i = albumIndex;
    albumIndex = i - 1;
}

- (IBAction)exitTutorial:(id)sender{
    
    self.tutorialImageView.hidden = YES;
    self.nextPageButton.hidden = YES;
    self.backPageButton.hidden = YES;
    self.exitTutorialButton.hidden = YES;
    
    self.optionsButton.enabled = YES;
    self.trashButton.enabled = YES;
    
    self.tutorialScreens = nil;
    self.tutorialImageView = nil;
    
    [self alert2];
}
-(void)alert2{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@""
                                                    message:@"Tap 'OK' then shake your device from side to side"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    [alert show];
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    [NSUD setObject:@"1" forKey:@"mainTutorial"];
    [NSUD synchronize];
}


- (IBAction)joinEvent:(id)sender {

    if (self.activeEventIDs.count > 0){
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *usr = [NSString stringWithFormat:@"%@/activeUserAlbums.txt", documentsDirectory];
        NSArray *userAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:usr];
        NSMutableArray *albumsArray = [[NSMutableArray alloc]initWithArray:userAlbums];
        
        NSMutableArray *albumData;
        // get the album array related to the objectID
        for (NSArray *array in albumsArray){
            if (array.count == 0){
                break;
            }
            NSObject *obj1 = [array objectAtIndex:0];
            
            if ([[obj1 valueForKey:@"objID"] isEqual:self.objId]){
                
                NSInteger i = [albumsArray indexOfObject:array];
                albumData = [albumsArray objectAtIndex:i];
            }
        }
        
        if (albumData.count >= 100) {
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Sorry!"
                                                       message:@"You're reached your image limit of 100 photos for this event."
                                                      delegate:self
                                               cancelButtonTitle:@"OK"
                                               otherButtonTitles:nil];
            [alert show];
        }
        else if (self.objId != nil){
            [self performSegueWithIdentifier:@"showFriends" sender:self];
            self.blurImageView.image = nil;
            self.tiltImageView.image = nil;
        }
    }
}

- (IBAction)toggleOptions:(id)sender {
    
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"OPTIONS"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"NEW EVENT",@"TIME CAPSULES", @"SHARED ALBUMS", @"About piXchange", @"Logout", nil];
    [alert show];
}

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
            
            NSInteger i = [self.activeTitles indexOfObject:self.albumTitle];
            [self.activeTitles removeObjectAtIndex:i];
            [self.activeEventIDs removeObjectAtIndex:i];
            [self.activeDeadlines removeObjectAtIndex:i];
            [self.pickerView reloadAllComponents];
            
            NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
            // set the info to userDefaults
            if (self.objsIdArray.count == 0){
                [NSUD setObject:nil forKey:@"activeEventIDs"];
                [NSUD setObject:nil forKey:@"activeDeadlines"];
                [NSUD setObject:nil forKey:@"activeTitles"];
            }
            else{
                [NSUD setObject:self.activeEventIDs forKey:@"activeEventIDs"];
                [NSUD setObject:self.activeDeadlines forKey:@"activeDeadlines"];
                [NSUD setObject:self.activeTitles forKey:@"activeTitles"];
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
                            // set the info to userDefaults
                            if (self.objsIdArray.count == 0){
                                [NSUD setObject:nil forKey:@"activeEventIDs"];
                                [NSUD setObject:nil forKey:@"activeDeadlines"];
                                [NSUD setObject:nil forKey:@"activeTitles"];
                            }
                            else{
                                [NSUD setObject:self.activeEventIDs forKey:@"activeEventIDs"];
                                [NSUD setObject:self.activeDeadlines forKey:@"activeDeadlines"];
                                [NSUD setObject:self.activeTitles forKey:@"activeTitles"];
                            }
                            [NSUD synchronize];
                            
                            // get the album from archives
                            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
                            
                            NSString *grp = [NSString stringWithFormat:@"%@/activeGroupAlbums.txt", documentsDirectory];
                            NSString *usr = [NSString stringWithFormat:@"%@/activeUserAlbums.txt", documentsDirectory];
                            NSString *evnt = [NSString stringWithFormat:@"%@/activeEventObjIds.txt", documentsDirectory];
                            
                            NSArray *groupAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:grp];
                            NSArray *userAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:usr];
                            NSArray *eventIds = [NSKeyedUnarchiver unarchiveObjectWithFile:evnt];
                            
                            NSMutableArray *groupsMutable = [[NSMutableArray alloc]initWithArray:groupAlbums];
                            NSMutableArray *userMutable = [[NSMutableArray alloc]initWithArray:userAlbums];
                            NSMutableArray *eventIdsMutable = [[NSMutableArray alloc]initWithArray:eventIds];
                            
                            [groupsMutable removeObjectAtIndex:i];
                            [userMutable removeObjectAtIndex:i];
                            [eventIdsMutable removeObjectAtIndex:i];
                            
                            [NSKeyedArchiver archiveRootObject:groupsMutable toFile:grp];
                            [NSKeyedArchiver archiveRootObject:userMutable toFile:usr];
                            [NSKeyedArchiver archiveRootObject:eventIdsMutable toFile:evnt];
                            
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

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];

    if (alertView.tag == DELETE_ALERT){
        if(buttonIndex == 1){ // user confirmed the delete
            [self deleteTheAlbum];
        }
    }
    else{
        if (buttonIndex == 1){ // New
            [self performSegueWithIdentifier:@"new" sender:self];
            self.navigationController.navigationBar.hidden = NO;
        }
        else if (buttonIndex == 2){ // Unreleased
            
            NSArray *caps = [NSUD arrayForKey:@"objectIDReference"]; // capsules
            if (caps.count == 0 && needNewQuery == NO){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [self performSegueWithIdentifier:@"unreleased" sender:self];
        }
        else if (buttonIndex == 3){ // Shared
            
            NSArray *caps = [NSUD arrayForKey:@"oldIDsReference"]; 
            if (caps.count == 0 && needNewQuery == NO){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            [self performSegueWithIdentifier:@"released" sender:self];
        }
        else if (buttonIndex == 4){ // About
            [self performSegueWithIdentifier:@"about" sender:self];
        }
        else if (buttonIndex == 5){ // LogOut
            [PFUser logOut];
            [self performSegueWithIdentifier:@"logout" sender:self];
        }
        if (buttonIndex != 0){
            self.blurImageView.image = nil;
            self.tiltImageView.image = nil;
            self.activeTitles = nil;
            [self.timer invalidate];
            self.timer = nil;
            self.deadline = nil;
        }
        [NSUD synchronize];
    }
}


#pragma mark - PICKER VIEW - DELEGATE
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return [self.activeTitles count];
}

#pragma mark - PICKER VIEW - DATA SOURCE
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    
    return [self.activeTitles objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    
    if (self.activeEventIDs.count > 0){
        self.deadline = [self.activeDeadlines objectAtIndex:row];
        self.albumTitle = [self.activeTitles objectAtIndex:row];
        self.objId = [self.activeEventIDs objectAtIndex:row];
        
        // start a timer that calculates the time between now and the selected albums release date
        if (self.deadline != nil && ![self.timerLabel.text isEqual:@"00:00:00:00"]) {
            [self startTimer];
        }
    }
}

#pragma mark - HELPERS
-(void)setPicker{
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    if([NSUD arrayForKey:@"activeEventIDs"]){
        NSArray *deadlines = [NSUD arrayForKey:@"activeDeadlines"];
        NSArray *titles = [NSUD arrayForKey:@"activeTitles"];
        NSArray *IDs = [NSUD arrayForKey:@"activeEventIDs"];
        self.activeTitles = [[NSMutableArray alloc]initWithArray:titles];
        self.activeEventIDs = [[NSMutableArray alloc]initWithArray:IDs];
        self.activeDeadlines = [[NSMutableArray alloc]initWithArray:deadlines];
    }

    if ((self.activeEventIDs == nil || self.activeEventIDs.count == 0) && albumRemoved == NO){
        [self setDefaultDataSource];
        self.deleteButton.enabled = NO;
    }
    else{
        self.deleteButton.enabled = YES;
        
        if (albumRemoved == NO){

            self.deadline = [self.activeDeadlines objectAtIndex:0];
            self.albumTitle = [self.activeTitles objectAtIndex:0];
            self.objId = [self.activeEventIDs objectAtIndex:0];
            [self startTimer];
        }
        else{
            if (albumRemoved == YES){
                if (albumIndex != 0){
                    NSInteger newIndex = albumIndex - 1;
                    self.deadline = [self.activeDeadlines objectAtIndex:newIndex];
                    self.albumTitle = [self.activeTitles objectAtIndex:newIndex];
                    self.objId = [self.activeEventIDs objectAtIndex:newIndex];
                    [self startTimer];
                }
                else{
                    
                    if(self.activeEventIDs.count > 0){
                        self.deadline = [self.activeDeadlines objectAtIndex:0];
                        self.albumTitle = [self.activeTitles objectAtIndex:0];
                        self.objId = [self.activeEventIDs objectAtIndex:0];
                    }
                    
                    if (self.objId == nil){
                        [self.timer invalidate];
                        self.deleteButton.enabled = NO;
                        self.timer = nil;
                        [self setDefaultDataSource];
                    }
                    else{
                        [self startTimer];
                    }
                }
                albumRemoved = NO;
            }
        }
    }
    [self.pickerView reloadAllComponents];
}


- (void)setBackgroundImage{ // Creates the blur/mask over the background image
    
//    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
//    CGRect rect = CGRectMake(0, 0, screenSize.width, screenSize.height);
    
    UIImage *blur = [self.tiltImageView.image applyLightEffect];
    
//    CGRect drawRect = AVMakeRectWithAspectRatioInsideRect(self.tiltImageView.image.size, rect);


    
    self.blurImageView.image = [self maskImage:blur withMask:[UIImage imageNamed:@"mask"]];
}

- (UIImage*)maskImage:(UIImage *)image withMask:(UIImage *)maskImage{ // called from [setImage]
    
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

- (void)registerEffectForView:(UIView *)aView depth:(CGFloat)depth{ // applies image parrallax effect
    
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


- (void)refreshTimerLabel {
    
    
    if (self.timer != nil){
        // Compare the 'real' time (now) against the date/time the album is to be released
        NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                                       fromDate:[NSDate date]
                                                                         toDate:self.deadline
                                                                        options:NSWrapCalendarComponents];
        // Get the integer value of each comparison unit
        NSInteger days = [dateComparisonComponents day];
        NSInteger hours = [dateComparisonComponents hour];
        NSInteger minutes = [dateComparisonComponents minute];
        NSInteger seconds = [dateComparisonComponents second];
        
        // Format the values for display as a string
        self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld:%02ld",
                                (long)days,
                                (long)hours,
                                (long)minutes,
                                (long)seconds];
        
        if ((long)days <= 0 && (long)hours <= 0 && (long)minutes <= 0 && (long)seconds <= 0){ // timer reached 00:00:00:00
            
            if (self.objId != nil){
                NSInteger i = [self.activeTitles indexOfObject:self.albumTitle];
                [self.activeTitles removeObjectAtIndex:i];
                [self.activeEventIDs removeObjectAtIndex:i];
                [self.activeDeadlines removeObjectAtIndex:i];
                
                self.deadline = nil;
                [self.timer invalidate];
                self.timer = nil;
                self.objId = nil;
                
                needNewQuery = YES;
                albumRemoved = YES;
                albumIndex = i;
                
                // update the userDefaults to reflect the album removal
                NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
                if (self.activeEventIDs.count == 0){
                    [NSUD setObject:nil forKey:@"activeTitles"];
                    [NSUD setObject:nil forKey:@"activeEventIDs"];
                    [NSUD setObject:nil forKey:@"activeDeadlines"];
                }else{
                    [NSUD setObject:self.activeTitles forKey:@"activeTitles"];
                    [NSUD setObject:self.activeEventIDs forKey:@"activeEventIDs"];
                    [NSUD setObject:self.activeDeadlines forKey:@"activeDeadlines"];
                }
                [NSUD setObject:nil forKey:@"oldIDsReference"];
                
/* instead of setting below to nil - set it to update NSUDs with users current event data -  to save parse call --- not intirely vital as it will only save one parse call and only if the user is watching the album as its timer reaches 0  */
                [NSUD setObject:nil forKey:@"objectIDReference"];
                [NSUD setObject:nil forKey:@"defaults"];
                
                [NSUD setObject:@"yes" forKey:@"needNewQuery"];
                
                [NSUD synchronize];
                
                [self setPicker];
                [self.pickerView reloadAllComponents];
            }
        }

    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    [self.timer invalidate];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 568){
        self.hidesBottomBarWhenPushed = YES;
    }
    
    if  ([segue.identifier isEqualToString:@"showFriends"]){
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *usr = [NSString stringWithFormat:@"%@/activeUserAlbums.txt", documentsDirectory];
        NSArray *userAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:usr];
        NSMutableArray *albumsArray = [[NSMutableArray alloc]initWithArray:userAlbums];
        
        NSMutableArray *albumData;
        // get the album array related to the objectID
        for (NSArray *array in albumsArray){
            
            if (array.count != 0){
            
                NSObject *obj1 = [array objectAtIndex:0];
                
                if ([[obj1 valueForKey:@"objID"] isEqual:self.objId]){
                    
                    NSInteger i = [albumsArray indexOfObject:array];
                    albumData = [albumsArray objectAtIndex:i];
                    break;
                }
            }
        }
        
        NSString *location = [NSString stringWithFormat:@"%@/albumData.txt", documentsDirectory];
        [NSKeyedArchiver archiveRootObject:albumData toFile:location];

        FriendsViewController *fvc = (FriendsViewController *)segue.destinationViewController;
        fvc.theTitle = self.albumTitle;
        fvc.startDate = self.deadline;
        fvc.objId = self.objId;
        fvc.albumRef = @"camera";
    }
    self.objId = nil;
}

-(void)motionBegan:(UIEventSubtype)motion withEvent:(UIEvent *)event{
    
    if (motion == UIEventSubtypeMotionShake){

        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *grp = [NSString stringWithFormat:@"%@/activeGroupAlbums.txt", documentsDirectory];
        NSArray *groupAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:grp];
        self.activeGroupAlbums = [[NSMutableArray alloc]initWithArray:groupAlbums];

        if (self.activeGroupAlbums.count == 0 || self.activeGroupAlbums == nil){
            [self setDefaultDataSource];
        }
    }
}


// User shook the device --> Fetch a random image from the albumsArray and set it as the background image
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
    
    if (motion == UIEventSubtypeMotionShake){
        
        NSMutableArray *groupAlb = [[NSMutableArray alloc]init];
        NSMutableArray *images = [[NSMutableArray alloc]init];
        
        for (NSArray *array in self.activeGroupAlbums){
            
            if (array.count > 0){
                NSObject *obj1 = [array objectAtIndex:0];
                if ([[obj1 valueForKey:@"objID"] isEqual:self.objId]){
                    
                    NSInteger i = [self.activeGroupAlbums indexOfObject:array];
                    groupAlb = [self.activeGroupAlbums objectAtIndex:i];
                    break;
                }
            }
        }
        
        self.activeGroupAlbums = nil;
        
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
        
        self.activeGroupAlbums = images;
        
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
        
        self.activeGroupAlbums = nil;
        
        // save the image to UserDefaults to load next app launch
        NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
        NSData *imageData = UIImageJPEGRepresentation(self.tiltImageView.image, .8f);
        [NSUD setObject:imageData forKey:@"activeBGImage"];
        [NSUD synchronize];
        
        
        if (![[NSUD valueForKey:@"tutorial"] isEqual:@"1"]){
            
            NSTimer *cameraTimer = [NSTimer scheduledTimerWithTimeInterval:2
                                                                    target:self
                                                                  selector:@selector(showAlert)
                                                                  userInfo:nil
                                                                   repeats:NO];
            
            [[NSRunLoop mainRunLoop] addTimer:cameraTimer forMode:NSDefaultRunLoopMode];
        }
    }
}

-(void)startTimer{
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                  target:self
                                                selector:@selector(refreshTimerLabel)
                                                userInfo:nil
                                                 repeats:YES];
}

-(void)showAlert {
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    [NSUD setObject:@"1" forKey:@"tutorial"];
    [NSUD synchronize];
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Cool huh?"
                                                    message:@"Use this feature to preview images at random from the selected album and/or to set your background image"
                                                   delegate:self
                                          cancelButtonTitle:@"OK"
                                          otherButtonTitles:nil];
    alert.alpha = 0.70f;
    [alert show];
}

- (UIImage *)getRandomImage{ // returns a random image from the array
    return [self activeGroupAlbums][arc4random_uniform((uint32_t)[self activeGroupAlbums].count)];
}

- (void)setDefaultDataSource{ // set the default images
    
    [self.timer invalidate];
    self.timer = nil;
    
    if (self.activeEventIDs.count == 0){
        
        self.activeDeadlines = [NSMutableArray arrayWithObject:@"00:00:00:00"];
    //    self.activeDeadlines = [NSMutableArray arrayWithObject:@"00:00:00:00"];
        self.timerLabel.text = @"00:00:00:00";
        self.activeTitles = [NSMutableArray arrayWithObject:@"No Active Events"];
        self.albumTitle = @"No Active Events";
    }
}

-(void)resetUserDefaults{
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    [NSUD setObject:nil forKey:@"defaults"];
    
    [NSUD setObject:nil forKey:@"album"];
    [NSUD setObject:nil forKey:@"objID"];
    [NSUD setObject:nil forKey:@"deadline"];
    
    [NSUD setObject:nil forKey:@"activeDeadlines"];
    [NSUD setObject:nil forKey:@"activeEventIDs"];
    [NSUD setObject:nil forKey:@"activeTitles"];
    [NSUD synchronize];
}
-(void)uploadUserDefaults{
    
    NSArray *temp = [self.NSUDalbum valueForKey:@"objID"];
    NSString *eventID = [temp objectAtIndex:0];

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Synching images...";
    [hud show:YES];

    NSString *userRef = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectId]];
    
    
    PFQuery *query = [PFQuery queryWithClassName:@"Images"];
    [query whereKey:@"parent" equalTo:eventID];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        
        NSData *objsData = [NSKeyedArchiver archivedDataWithRootObject:self.NSUDalbum];
        PFFile *file = [PFFile fileWithData:objsData];
        
        if (error){
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                message:@"Your photos could not be saved at this time."
                                                               delegate:self
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        }
        else if (objects.count == 0 || objects == nil){
            
            // this should only get called if the user doesnt have a pfobject for the event yet
            PFObject *userImages = [PFObject objectWithClassName:@"Images"];
            userImages[@"content"] = file;
            userImages[@"userID"] = userRef;
            userImages[@"parent"] = eventID;
            
            [userImages saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                
                if (error) {
                    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                        message:@"Your photos could not be saved at this time."
                                                                       delegate:self
                                                              cancelButtonTitle:@"OK"
                                                              otherButtonTitles:nil];
                    [alertView show];
                }
                else{
                    [self queryParseForAllEvents];
                    [self resetUserDefaults];
                }
                [hud hide:YES];
            }];
        }
        else{
            
            int i;
            
            for (i = 0; i < objects.count; i++){
                
                for (PFObject *obj in objects){
                    
                    if ([[obj valueForKey:@"userID"] isEqual:userRef]){
                        
                        NSString *objectID = [obj valueForKey:@"objectId"];

                        PFObject *object = [query getObjectWithId:objectID];
                        
                        object[@"content"] = file;
                        
                        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            
                            if (error) {
                                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                                    message:@"Your photos could not be saved at this time."
                                                                                   delegate:self
                                                                          cancelButtonTitle:@"OK"
                                                                          otherButtonTitles:nil];
                                [alertView show];
                            }
                            else{
                                /* need to update below to refresh all data while in this query */
                                [self queryParseForAllEvents];
                                [self resetUserDefaults];
                            }
                            
                            [hud hide:YES];
                        }];
                        
                        break;
                    }
                }
            }
        }
    }];
}

 


@end
