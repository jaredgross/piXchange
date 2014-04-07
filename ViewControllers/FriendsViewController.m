//
//  FriendsViewController.m
//  Flashback
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 Kickin' Appz All rights reserved.
//

#import "FriendsViewController.h"
#import <mobileCoreServices/UTCoreTypes.h>
#import <MessageUI/MessageUI.h>
#import "PreviewViewController.h"
#import <Parse/Parse.h>
#import "contactDetails.h"
#import "FriendsViewCell.h"
#import "ActiveViewController.h"
#import "MBProgressHUD.h"

#define CONTINUE_INVITE_ALERT 1
#define LEAVE_FLASHBACK_ALERT 2
#define EVENT_ENDED_ALERT 3

@interface FriendsViewController () <MFMessageComposeViewControllerDelegate>
{
    BOOL                eventCreator;
    BOOL                 showFlashMode;
}

#pragma mark - Table View Controller
@property (weak, nonatomic) IBOutlet UIButton *previewButton;
@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) PFUser *currentUser;
@property (nonatomic, strong) PFRelation *friendsRelation;
@property (nonatomic, strong) NSMutableArray *pushRecipients;
@property (nonatomic, strong) NSMutableArray *SMSrecipients;
@property (nonatomic, strong) NSMutableArray *recipientNames;
@property (nonatomic, strong) NSArray *allUsers;
@property (nonatomic, strong) NSArray *friends;

@property (nonatomic, strong) UIImagePickerController *imagePicker;

#pragma mark - Image Picker Properties i5
@property (nonatomic, weak) IBOutlet UIImageView *bottomBar;
@property (nonatomic, weak) IBOutlet UIView *overlayView;
@property (weak, nonatomic) IBOutlet UILabel *timeRemainingLabel;
@property (weak, nonatomic) IBOutlet UILabel *timeUnitLabel;

@property (nonatomic, weak) IBOutlet UIButton *flipCamera;
@property (nonatomic, weak) IBOutlet UIButton *toggleFlash;
@property (nonatomic, weak) IBOutlet UIButton *timedCapture;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;
@property (nonatomic, weak) IBOutlet UIButton *captureImage;
@property (nonatomic, weak) IBOutlet UIBarButtonItem *inviteButton;
@property (nonatomic, weak) IBOutlet UIButton *addFriends;
@property (weak, nonatomic) IBOutlet UIImageView *previewImageView;
@property (nonatomic, weak) IBOutlet UILabel *imageCount;
@property (nonatomic, weak) IBOutlet UILabel *videoTimer;
@property (nonatomic, weak) IBOutlet UILabel *timerLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) NSTimer *cameraTimer;
@property (nonatomic, strong) NSTimer *deadlineTimer;
@property (nonatomic, strong) NSDateFormatter *df;

@property (nonatomic, strong) NSData *vidData;

@property (nonatomic, strong) UIImage *resizedImage;
@property (nonatomic, strong) NSArray *contactDetailsList;

@property (nonatomic, strong) NSArray *sectionsArray;
@property (nonatomic, strong) UILocalizedIndexedCollation *collation;
@property (nonatomic, strong) NSDate *fireTime;
@property (nonatomic, strong) NSCalendar *gregorian;

@property (nonatomic, strong) NSString *NSDD;

@property (nonatomic) NSInteger startingImageCount;

- (void)configureSections;

@end

@implementation FriendsViewController


// Sets up the View Controller
- (void)viewDidLoad {
    [super viewDidLoad];
    
    eventCreator = NO;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.hidden = NO;
    
    self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    self.currentUser = [PFUser currentUser];
    self.pushRecipients = [[NSMutableArray alloc] initWithCapacity:[self.friends count]];
    self.SMSrecipients = [[NSMutableArray alloc] init];
    
    self.contactDetailsList = [userContactsList getInstance].allContactsDetailsList;
    [self configureSections];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;

    self.NSDD = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    // if it's the users first time they will be alerted to check out the "how it works" page
//    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    
    NSString *invite = [NSString stringWithFormat:@"%@/pushInvite.txt", self.NSDD];
    NSString *pushInvite = [NSKeyedUnarchiver unarchiveObjectWithFile:invite];
    
    if (pushInvite == nil){
//        if (![NSUD valueForKey:@"friendsTutorial"]){
//            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"INVITE SOME FRIENDS"
//                                                            message:@"Now, invite some friends to join the event then tap the top right button to start the camera"
//                                                           delegate:self
//                                                  cancelButtonTitle:@"OK"
//                                                  otherButtonTitles:nil];
//            [alert show];
//            [NSUD setObject:@"1" forKey:@"friendsTutorial"];
//            [NSUD synchronize];
//        }
    }
    [NSKeyedArchiver archiveRootObject:nil toFile:invite];
}

-(void)goHome{
    [self performSegueWithIdentifier:@"goHome" sender:self];
}

-(void)viewDidAppear:(BOOL)animated{
    self.contactDetailsList = [userContactsList getInstance].allContactsDetailsList;
    [self configureSections];
    
    NSString *ID = [NSString stringWithFormat:@"%@/eventID.txt", self.NSDD];
    [NSKeyedArchiver archiveRootObject:nil toFile:ID];
}

// Refreshes the View Controller
- (void)viewWillAppear:(BOOL)animated {
    
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [self.df setTimeZone:[NSTimeZone systemTimeZone]];
    [self.df setFormatterBehavior:NSDateFormatterBehaviorDefault];

    if ([self.albumRef isEqualToString:@"camera"]) { // user is part of an active Event
        
        if (self.album.count == 0 || self.album == nil){
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *str = [NSString stringWithFormat:@"%@/albumData.txt", documentsDirectory];
            NSArray *albumData = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
            self.album = [[NSMutableArray alloc]initWithArray:albumData];
        }

        if (self.album.count == 0) { // if user doesn't have a current album, create one
            self.album = [[NSMutableArray alloc]init];
        }
        [self startCamera:self];
    }
    else { // user is not part of an active Event. create an array to hold users images
        self.album = [[NSMutableArray alloc]init];
    }
    
    if (self.album.count > 0){
        self.previewButton.alpha = 1;
        self.previewButton.backgroundColor = [UIColor clearColor];
    }
}


#pragma mark - Table view data source
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [[self.collation sectionTitles] count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    // The number of user names in the section is the count of the array associated with the section in the sections array.
	NSArray *userNamesInSection = (self.sectionsArray)[section];
    
    return [userNamesInSection count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *CellIdentifier = @"cell";
    FriendsViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (cell == nil) {
        cell = [[FriendsViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSArray *array = [self.sectionsArray objectAtIndex:indexPath.section];
    PFUser *user = [array objectAtIndex:indexPath.row];
    
    if ([self.pushRecipients containsObject:user]) {
        //cell.accessoryType = UITableViewCellAccessoryCheckmark;
        [cell.addOrInviteButton setImage:[UIImage imageNamed:@"checkmark.png"]
                                forState:UIControlStateNormal];
    }
    else if ([self.SMSrecipients containsObject:user]){
        [cell.addOrInviteButton setImage:[UIImage imageNamed:@"inviteON.png"]
                                forState:UIControlStateNormal];
    }
    else{
        //cell.accessoryType = UITableViewCellAccessoryNone;
        [cell.addOrInviteButton setImage:[UIImage imageNamed:@"add.png"]
                                forState:UIControlStateNormal];
        }

    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    // Get the user names from the array associated with the section index in the sections array.
	NSArray *userNamesInSection = (self.sectionsArray)[indexPath.section];

    // Configure the cell with user name.
	contactDetails *details = userNamesInSection[indexPath.row];
    if (details.lastName == nil){
        details.lastName = @"";
    }

    NSString *firstLastName = [NSString stringWithFormat:@"%@ %@", details.firstName, details.lastName];
    
    cell.textLabel.text = firstLastName;
    if(details.flashbackUserName)
        cell.detailTextLabel.text = details.flashbackUserName;
    else
        cell.detailTextLabel.text = details.phoneNumber;

    return cell;
}

-(void) sendPushToUser:(NSString*) eventID{
    
    if(self.pushRecipients.count <= 0 || !eventID)
        return;
    
    [[userContactsList getInstance] refreshContactsList];
    
    NSMutableArray* userNames = [[NSMutableArray alloc] init];
    
    for (contactDetails* details in self.pushRecipients)
    {
        if ([self.albumRef isEqual:@"update"]){
            [userNames addObject:details];
        }
        else if(details.flashbackUserName){
            [userNames addObject:details.flashbackUserName];
        }
    }
    
    // Create our Installation query
    [[PFInstallation currentInstallation] setObject:[PFUser currentUser] forKey:@"user"];
    [[PFInstallation currentInstallation] saveEventually];
    
    // Build a query to match users with a username
    PFQuery *innerQuery = [PFUser query];
    [innerQuery whereKey:@"username" containedIn:userNames];
    
    // Build the actual push notification target query
    PFQuery *query = [PFInstallation query];
    
    // only return Installations that belong to a User that
    // matches the innerQuery
    [query whereKey:@"user" matchesQuery:innerQuery];
    
    // Send the notification.
    PFPush *push = [[PFPush alloc] init];
    
    NSString *alert;
    if ([self.albumRef isEqual:@"update"]){
        alert = [NSString stringWithFormat:@"You've been added to the event - %@", self.theTitle];
    }
    else{
        alert = [NSString stringWithFormat:@"%@ has invited you to the event '%@'", self.currentUser.username, self.theTitle];
    }
    
    NSDictionary* pushData = @{@"eventID": eventID,
                               @"alert": alert};
    
    [push setQuery:query];
    [push setData:pushData];
    [push sendPushInBackground];
    
    [self.pushRecipients removeAllObjects];
}

#pragma mark - Table view delegate
    // User tapped a Row in the Table View
-(IBAction)addOrInviteButtonTapped:(id)sender {
    
    UIButton *button = sender;
    
    CGPoint buttonPosition = [sender convertPoint:CGPointZero toView:self.tableView];
    NSIndexPath *indexPath = [self.tableView indexPathForRowAtPoint:buttonPosition];
    if (!indexPath)
        return;

    NSArray *array = [self.sectionsArray objectAtIndex:indexPath.section];
    contactDetails *details = [array objectAtIndex:indexPath.row];

    if ([self.pushRecipients containsObject:details])
    {
        [button setImage:[UIImage imageNamed:@"add.png"]
                                forState:UIControlStateNormal];
        [self.pushRecipients removeObject:details];
        
    }
    else if([self.SMSrecipients containsObject:details])
    {
        [button setImage:[UIImage imageNamed:@"add.png"]
                forState:UIControlStateNormal];
        [self.SMSrecipients removeObject:details];
        
    }
    else
    {
        if(details.flashbackUserName)
        {
            [self.pushRecipients addObject:details];
            
            [button setImage:[UIImage imageNamed:@"checkmark.png"]
                    forState:UIControlStateNormal];
        }
        else
        {
            [self.SMSrecipients addObject:details];
            
            [button setImage:[UIImage imageNamed:@"inviteON.png"]
                    forState:UIControlStateNormal];
        }
        
    }

    [self.currentUser saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
        if (error) {
            NSLog(@"Error %@ %@", error, [error userInfo]);
        }
    }];
    
    if ((self.pushRecipients.count != 0) || (self.SMSrecipients.count != 0)){
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                    target:self
                                                                                    action:@selector(showSMS:)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
    }
    else {
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Skip"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(hideFriendsAndLoadCamera)];
        self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
    }
    
    if ([self.albumRef isEqual:@"addFriends"]) { // user accessed the screen from within an open Event Camera
        if ((self.pushRecipients.count == 0) && (self.SMSrecipients.count == 0)) {
            // no recipients found --> set invite button to 'nil'
            self.navigationItem.RightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:nil];
        } else { // recipients found --> set the inviteButtons action
            self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                                    target:self
                                                                                                   action:@selector(showSMS:)];
            self.navigationItem.rightBarButtonItem.tintColor = [UIColor redColor];
        }
    }
}

// Section-related methods: Retrieve the section titles and section index titles from the collation
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    
    NSArray *array = [self.sectionsArray objectAtIndex:section];

    if(array.count)
        return [self.collation sectionTitles][section];
    else
        return 0;
}

- (NSArray *)sectionIndexTitlesForTableView:(UITableView *)tableView {
    return [self.collation sectionIndexTitles];
}

- (NSInteger)tableView:(UITableView *)tableView sectionForSectionIndexTitle:(NSString *)title atIndex:(NSInteger)index {
    return [self.collation sectionForSectionIndexTitleAtIndex:index];
}


#pragma mark - Set the data array and configure the section data
- (void)configureSections {
    
    // Get the current collation and keep a reference to it.
	self.collation = [UILocalizedIndexedCollation currentCollation];
    
	NSInteger index, sectionTitlesCount = [[self.collation sectionTitles] count];
  
	NSMutableArray *newSectionsArray = [[NSMutableArray alloc] initWithCapacity:sectionTitlesCount];
    
	// Set up the sections array: elements are mutable arrays that will contain the user names for that section.
	for (index = 0; index < sectionTitlesCount; index++) {
		NSMutableArray *array = [[NSMutableArray alloc] init];
		[newSectionsArray addObject:array];
	}
    // Segregate the user names into the appropriate arrays.
    for (contactDetails *details in self.contactDetailsList) {

        // Ask the collation which section number the user name belongs in, based on its name.
		NSInteger sectionNumber = [self.collation sectionForObject:details
                                           collationStringSelector:@selector(firstName)];
       
		// Get the array for the section.
		NSMutableArray *sectionUserDetails = newSectionsArray[sectionNumber];
        // if the username is equal to the current user, we dont need it in the friends list
        if ([details.flashbackUserName isEqualToString: self.currentUser.username]){
        }
        else { //  Add the user name to the section.
            [sectionUserDetails addObject:details];
        }
	}

	self.sectionsArray = [newSectionsArray copy];
  
    [self.tableView reloadData];
}


#pragma mark - Table View Helpers
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 60.f;
}

#pragma mark - Image Picker Helpers
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    
    NSString *userID = [[PFUser currentUser] objectId];
    NSDictionary *imageFile;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];

    if ([mediaType isEqualToString:(NSString *)kUTTypeImage]) { // It's a photo
        self.image = [info objectForKey:UIImagePickerControllerOriginalImage];
        
        // check the devices screensize and resize the image accordingly
        UIImage *resizedImage;
        NSData *imageData;

        if (UIDeviceOrientationIsLandscape(orientation)) // landscape orientation
        {
            resizedImage = [self resizeImage:self.image toWidth:800.0f andHeight:600.0f];
            imageData = UIImageJPEGRepresentation(resizedImage, .5f);
        }
        else // portrait orientation
        {
            resizedImage = [self resizeImage:self.image toWidth:600.0f andHeight:800.0f];
            imageData = UIImageJPEGRepresentation(resizedImage, .5f);
        }
 
        // set the image for preview
        self.image = resizedImage;
        
        // create a dictionary reference that ties the objID, userID, and image together
        if (imageData != nil && userID != nil && self.objId != nil){
            imageFile = @{
                          @"objID" : self.objId,
                          @"userID" : userID,
                          @"img" : imageData,
                          @"title" : self.titleLabel.text,
                          };
        }
        
        if (imageFile != nil){
            [self.album addObject:imageFile];
        }
    }
    
    if (self.album.count > 0){
        self.previewButton.alpha = 1;
        [self.previewButton setBackgroundColor:[UIColor clearColor]];
        self.imageCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.album count]];
    }
    else{
        self.previewButton.alpha = .25f;
        self.imageCount.text = @"00";
        
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        if (screenSize.height == 568){
            self.previewButton.backgroundColor = [UIColor lightGrayColor];
        }else if (screenSize.height == 480){
            self.previewButton.backgroundColor = [UIColor darkGrayColor];
        }
    }

    if (self.album.count == 100){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"PHOTO LIMIT REACHED"
                                                            message:@"You've reached your limit of 100 photos for this event. Your photos will now be saved"
                                                           delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        
        [self uploadAlbum];
    }

    UIImage *img = [UIImage imageWithData:[[self.album lastObject] valueForKey:@"img"]];
    self.previewImageView.image = img;

    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    [NSUD setObject:self.album forKey:@"album"];
    [NSUD setObject:self.objId forKey:@"objID"];
    [NSUD synchronize];
}

#pragma mark - HELPERS
- (void) uploadAlbum
{
    [self.imagePicker dismissViewControllerAnimated:NO completion:NULL];
    [self performSegueWithIdentifier:@"goHome" sender:self];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) hideAllControls {
    self.bottomBar.hidden = YES;
    self.imageCount.hidden = YES;
    self.titleLabel.hidden = YES;
    self.timerLabel.hidden = YES;
    self.captureImage.enabled = NO;
    self.cancelButton.hidden = YES;
    self.timedCapture.hidden = YES;
    self.toggleFlash.hidden = YES;
    self.flipCamera.hidden = YES;
}

#pragma mark - ACTIONS

- (IBAction)timedCapture:(id)sender {
    
    if ((self.fireTime != nil)) {
        self.fireTime = nil;
        [self.cameraTimer invalidate];
        self.videoTimer.text = @"10";
        [self timerControlsON];
        
    }else{
        [self timerControlsOFF];
        self.fireTime = [NSDate dateWithTimeIntervalSinceNow:10.0];
        NSTimer *cameraTimer = [NSTimer scheduledTimerWithTimeInterval:-1
                                                            target:self
                                                          selector:@selector(takePic)
                                                          userInfo:nil
                                                           repeats:YES];
    
        [[NSRunLoop mainRunLoop] addTimer:cameraTimer forMode:NSDefaultRunLoopMode];
        self.cameraTimer = cameraTimer;
    }
}

-(void)takePic{
    
    NSDate *todaysDate = [NSDate date];
    
    self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    NSUInteger unitFlags = NSSecondCalendarUnit;
    
    NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                              fromDate:todaysDate
                                                                toDate:self.fireTime
                                                               options:NSWrapCalendarComponents];
    NSInteger seconds = [dateComparisonComponents second];
    
    self.videoTimer.text = [NSString stringWithFormat:@"%02ld",
                            (long)seconds];
    
    if ((long)seconds == 0) {
        [self.cameraTimer invalidate];
        [self.imagePicker takePicture];
        [self timerControlsON];
    }
}

- (void) timerControlsON {
    self.previewButton.enabled = YES;
    self.videoTimer.hidden = YES;
    self.timeRemainingLabel.hidden = NO;
    self.timeUnitLabel.hidden = NO;
    self.captureImage.enabled = YES;
    self.timerLabel.hidden = NO;
    self.cancelButton.hidden = NO;
    self.imageCount.hidden = NO;
    self.previewImageView.hidden = NO;
    self.toggleFlash.hidden = NO;
    self.flipCamera.hidden = NO;
    self.addFriends.hidden = NO;
    [self.timedCapture setImage:[UIImage imageNamed:@"camTimer.png"] forState:UIControlStateNormal];
}
- (void) timerControlsOFF {
    self.previewButton.enabled = NO;
    self.timeRemainingLabel.hidden =YES;
    self.timeUnitLabel.hidden = YES;
    self.captureImage.enabled = NO;
    self.videoTimer.hidden = NO;
    self.toggleFlash.hidden = YES;
    self.flipCamera.hidden = YES;
    self.previewImageView.hidden = YES;
    self.addFriends.hidden = YES;
    self.timerLabel.hidden = YES;
    self.imageCount.hidden = YES;
    self.cancelButton.hidden = YES;
    [self.timedCapture setImage:[UIImage imageNamed:@"camTimerON.png"] forState:UIControlStateNormal];
}

    // * Toggles camera front/rear
- (IBAction)flipCamera:(id)sender {
    
    if (self.imagePicker.cameraDevice == UIImagePickerControllerCameraDeviceRear) {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceFront;
        
        self.toggleFlash.hidden = YES;
        self.toggleFlash.enabled = NO;
        [self.flipCamera setImage:[UIImage imageNamed:@"ChangeCameraSelected.png"] forState:UIControlStateNormal];
    } else {
        self.imagePicker.cameraDevice = UIImagePickerControllerCameraDeviceRear;
        self.toggleFlash.hidden = NO;
        self.toggleFlash.enabled = YES;
        [self.flipCamera setImage:[UIImage imageNamed:@"ChangeCamera.png"] forState:UIControlStateNormal];
    }
}

- (IBAction)toggleFlash:(id)sender {

    if (self.imagePicker.cameraFlashMode == UIImagePickerControllerCameraFlashModeOff) {
        self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOn;
        [self.toggleFlash setImage:[UIImage imageNamed:@"flashON.png"] forState:UIControlStateNormal];
    } else {
        self.imagePicker.cameraFlashMode = UIImagePickerControllerCameraFlashModeOff;
        [self.toggleFlash setImage:[UIImage imageNamed:@"flashIcon.png"] forState:UIControlStateNormal];
    }
}

// User chose to invite more friends from inside the Flashback
- (IBAction)addFriends:(id)sender {
    
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    self.navigationController.navigationBar.hidden = NO;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [self dismissViewControllerAnimated:NO completion:nil];

    self.tableView.hidden = NO;
    self.albumRef = @"addFriends";
    
    // set back button to cancel view controller and return to camera
    self.navigationItem.LeftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Cancel"
                                                                    style:UIBarButtonItemStylePlain
                                                                   target:self
                                                                   action:@selector(backToCam)];
    
    // set back button to cancel view controller and return to camera
    self.navigationItem.RightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@""
                                                                     style:UIBarButtonItemStylePlain
                                                                    target:self
                                                                    action:nil];
}

-(void)backToCam {
    if([self.albumRef isEqual:@"addFriends"]) {
        self.albumRef = @"camera";
    }
    [self startCamera:self];
}

- (IBAction)showPreview:(id)sender {
    
    if ((self.image != nil) || (self.album.count > 0)){
        self.albumRef = @"camera";
        
        [self performSegueWithIdentifier:@"showPreview" sender:self];
        self.navigationController.navigationBar.Hidden = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self dismissViewControllerAnimated:NO completion:nil];
    }
}

- (IBAction)cancelButton:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                  message:@""
                                                  delegate:self
                                           cancelButtonTitle:@"Cancel"
                                           otherButtonTitles:@"YES", nil];
    alert.tag = LEAVE_FLASHBACK_ALERT;
    [alert show];
}


- (IBAction)showMessenger:(id)sender {
    
    if([self.albumRef isEqual:@"addFriends"]) {
        self.albumRef = @"camera";
    }
    self.inviteButton.enabled = NO;
    
    if(self.SMSrecipients.count > 0)
    {
        NSString *selectedFile = self.titleLabel.text;
        [self showSMS:selectedFile];
    }
    else
    {
        [self hideFriendsAndLoadCamera];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(alertView.tag == CONTINUE_INVITE_ALERT)
    {
        if (buttonIndex==1){
            NSString *selectedFile = self.titleLabel.text;
            [self showSMS:selectedFile];
        }
    }
    else if (alertView.tag == LEAVE_FLASHBACK_ALERT)
    {
        if (buttonIndex==1) {
            [self uploadAlbum];
        }
    }
    else if (alertView.tag == EVENT_ENDED_ALERT){
        [self uploadAlbum];
    }
}

- (IBAction)captureImage:(id)sender {
    self.albumRef = @"camera";
    [self.imagePicker takePicture];
}

#pragma mark - HELPERS
- (void)videoCaptureTimer {
    
    NSDate *todaysDate = [NSDate date];
    
    NSUInteger unitFlags = NSSecondCalendarUnit;
    
    NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                              fromDate:todaysDate
                                                                toDate:self.fireTime
                                                               options:NSWrapCalendarComponents];
    NSInteger seconds = [dateComparisonComponents second];
    
    self.videoTimer.text = [NSString stringWithFormat:@"%02ld",
                            (long)seconds];
    
    if ((long)seconds <= 0) {
        
        [self.cameraTimer invalidate];
        
        self.videoTimer.hidden = NO;
        self.cancelButton.hidden = YES;
        self.imageCount.hidden = NO;
        self.addFriends.hidden = YES;
        self.flipCamera.hidden = NO;
        self.toggleFlash.hidden = NO;
        self.timedCapture.hidden = YES;
        self.timerLabel.hidden = YES;
        self.titleLabel.hidden = YES;
    }
}

- (void)refreshMainTimer {
    
    if ([self.deadlineTimer isValid]){
        NSString *sfd1 = [self.df stringFromDate:self.startDate];
        NSDate *dfs1 = [self.df dateFromString:sfd1];
        
        NSString *sfd = [self.df stringFromDate:[NSDate date]];
        NSDate *dfs = [self.df dateFromString:sfd];
        
        NSUInteger unitFlags = NSDayCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                                       fromDate:dfs
                                                                         toDate:dfs1
                                                                        options:NSWrapCalendarComponents];
        NSInteger days = [dateComparisonComponents day];
        NSInteger hours = [dateComparisonComponents hour];
        NSInteger minutes = [dateComparisonComponents minute];
        NSInteger seconds = [dateComparisonComponents second];
        
        self.timerLabel.text = [NSString stringWithFormat:@"%02ld:%02ld:%02ld:%02ld",
                                (long)days,
                                (long)hours,
                                (long)minutes,
                                (long)seconds];
        
        if ((long)days <= 0 && (long)hours <= 0 && (long)minutes <= 0 && (long)seconds <= 0) {
            
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"The timer has expired!"
                                                            message:@"Your photos will now be uploaded"
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            alert.tag = EVENT_ENDED_ALERT;
            [alert show];
            
            [self.deadlineTimer invalidate];
        }

    }
}

    // Resizes the image for storage on backend
- (UIImage *)resizeImage:(UIImage *)image toWidth:(float)width andHeight:(float)height {
    
    CGSize newSize = CGSizeMake(width, height);
    UIGraphicsBeginImageContext(newSize);
    [self.image drawInRect:CGRectMake(0, 0, width, height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return resizedImage;
}


#pragma mark - TEXT MESSENGER

- (void)showSMS:(NSString*)file{ // called when user taps the 'invite' button to send the invites &/or PUSH notifications
    
    if (self.SMSrecipients.count <= 0){ // all the users invited friends already have the app
        [self hideFriendsAndLoadCamera];
    }
    else{ // user invited friends who do not already have the app installed --> send them a message with a link to download the app
        if(![MFMessageComposeViewController canSendText]) {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error"
                                                              message:@"Your device doesn't support SMS!"
                                                              delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [warningAlert show];
            return;
        }
        self.recipientNames = [[NSMutableArray alloc] initWithCapacity:[self.SMSrecipients count]];
        
        // check the SMS recipients for users without a user name and add their phone number to the list of recipients instead
        for (contactDetails *detail in self.SMSrecipients){
            if(!detail.flashbackUserName)
                [self.recipientNames addObject:detail.phoneNumber];
        }
        
        // compose and set the message/recipients
        NSString *message = [NSString stringWithFormat:@"%@ has invited you to ""%@""! Click here to download piXchange!", self.currentUser.username, self.theTitle];
        
        MFMessageComposeViewController *messageController = [[MFMessageComposeViewController alloc] init];
        messageController.messageComposeDelegate = self;
        [messageController setRecipients:self.recipientNames];
        [messageController setBody:message];
        
        // Present the message view controller
        [self presentViewController:messageController animated:YES completion:nil];
        
        // this will be called only the first time a user invites friends who don't have the app - TUTORIAL ALERT  -
        NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
        if (![NSUD valueForKey:@"SMSTutorial"]){
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Messege Invites"
                                                            message:@"Some of the friends you selected don't yet have the app - this screen will send a text message inviting them to join your event along with a link to download the app from the store."
                                                           delegate:self
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [NSUD setObject:@"1" forKey:@"SMSTutorial"];
            [NSUD synchronize];
        }
    }
}

    // Messenger actions
- (void)messageComposeViewController:(MFMessageComposeViewController *)controller didFinishWithResult:(MessageComposeResult) result {
    switch (result) {
            
        case MessageComposeResultCancelled:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
            
        case MessageComposeResultFailed:
        {
            UIAlertView *warningAlert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Failed to send SMS!" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
            [warningAlert show];
            break;
        }
        case MessageComposeResultSent:
            
            [self hideFriendsAndLoadCamera];
    }
}

-(void) hideFriendsAndLoadCamera
{
    if (self.SMSrecipients.count != 0){
        [self startPushTimer];
    }
    
    [self createPFObject];
    
}

-(void)startPushTimer{
    NSTimer *cameraTimer = [NSTimer scheduledTimerWithTimeInterval:300
                                                    target:self
                                                    selector:@selector(updateRecipients)
                                                    userInfo:nil
                                                    repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:cameraTimer forMode:NSDefaultRunLoopMode];
}

-(void)updateRecipients{

    NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:self.SMSrecipients.count];
    NSMutableArray *newRecipients = [[NSMutableArray alloc]initWithCapacity:self.SMSrecipients.count];
    NSMutableArray *userNames = [[NSMutableArray alloc]initWithCapacity:self.SMSrecipients.count];
    NSString *number;
    for (contactDetails *details in self.SMSrecipients){
        number = details.encryptedPhoneNumber;
        [temp addObject:number];
    }
    
    PFQuery *userQuery = [PFUser query];
    [userQuery whereKey:@"phoneNumber" containedIn:temp];
    [userQuery findObjectsInBackgroundWithBlock:^(NSArray *userDetails, NSError *error){

        if ((error) || ([userDetails count] == 0)){
        }
        else{
            for (NSObject *obj in userDetails){
                
                NSString *userID = [obj valueForKey:@"objectId"];
                NSString *username = [obj valueForKey:@"username"];
                
                if (userID != nil){
                    [newRecipients addObject:userID];
                }
                
                if (username != nil)
                {
                    [userNames addObject:username];
                }
            }
            
            PFQuery *query = [PFQuery queryWithClassName:@"Events"];
            [query getObjectInBackgroundWithId:self.objId block:^(PFObject *Event, NSError *error) {

                NSMutableArray *recipients = [Event valueForKey:@"recipientIds"];
    
                // create an array that holds the old and new recipients
                NSInteger count = recipients.count + newRecipients.count;
                NSMutableArray *combinedRecipients = [[NSMutableArray alloc]initWithCapacity:count];
                
                for (NSObject *obj in newRecipients){
                    [combinedRecipients addObject:obj];
                }
                for (NSObject *obj in recipients){
                    [combinedRecipients addObject:obj];
                }
                
                // set new recipientIDs and save to Parse
                [Event setObject:combinedRecipients forKey:@"recipientIds"];
                [Event saveInBackground];

                self.albumRef = @"update";
                self.pushRecipients = [[NSMutableArray alloc]initWithArray:userNames];
                [self sendPushToUser:self.objId];
            }];
        }
    }];
}

-(void)startTimer{
    
    self.fireTime = [NSDate dateWithTimeIntervalSinceNow:1];
    NSTimer *cameraTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                      target:self
                                                    selector:@selector(fireCamera)
                                                    userInfo:nil
                                                     repeats:YES];
    
    [[NSRunLoop mainRunLoop] addTimer:cameraTimer forMode:NSDefaultRunLoopMode];
    self.cameraTimer = cameraTimer;
}

-(void)createPFObject{

    // get the Flashback counter and location from storage
    NSString *deadline = [NSString stringWithFormat:@"%@/deadline.txt", self.NSDD];
    NSString *releaseString = [NSString stringWithFormat:@"%@/releaseCounter.txt", self.NSDD];
    NSString *locationString = [NSString stringWithFormat:@"%@/location.txt", self.NSDD];
    NSString *location = [NSKeyedUnarchiver unarchiveObjectWithFile:locationString];
    NSDate *rdRef = [NSKeyedUnarchiver unarchiveObjectWithFile:releaseString];
    NSString *cdRef = [NSKeyedUnarchiver unarchiveObjectWithFile:deadline];
    
    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    [df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [df setTimeZone:[NSTimeZone systemTimeZone]];
    [df setFormatterBehavior:NSDateFormatterBehaviorDefault];
    NSString *str = [df stringFromDate:rdRef];
    NSDate *releaseDate = [df dateFromString:str];
    NSDate *camDeadline = [df dateFromString:cdRef];
    
    // prepare an array to store all the recipient names (+1 to add users self)
    NSMutableArray *recipientNames = [[NSMutableArray alloc] initWithCapacity:[self.pushRecipients count]+1];

    if (![self.albumRef isEqual:@"addFriends"]){
        [recipientNames addObject:[self.currentUser objectId]];
    }

    // iterate through the names in the index and get the PFUser info
    for (contactDetails *detail in self.pushRecipients)
    {
        if(detail.objectID)
            [recipientNames addObject:detail.objectID];
    }
    
    // create the object and set contents and keys
    __block PFObject *event = [PFObject objectWithClassName:@"Events"];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Loading the event...";
    [hud show:YES];
    
    if(location != nil){
        [event setObject:location forKey:@"location"];
    }
    if(releaseDate != nil){
        [event setObject:releaseDate forKey:@"releaseDate"];
    }
    
    if ([self.albumRef isEqual:@"invite"])
    {
        if(self.pushRecipients.count > 0)
        {
            [self sendPushToUser:event.objectId];
        }
                
        self.objId = [event valueForKey:@"objectId"];
        
        self.navigationController.navigationBar.hidden = YES;
        [self dismissViewControllerAnimated:NO completion:nil];
        [self startTimer];
                
        // reset 'albRef' archive to 'nil'
        NSString *ar = [NSString stringWithFormat:@"%@/albRef.txt", self.NSDD];
        [NSKeyedArchiver archiveRootObject:nil toFile:ar];
    }
    else if ([self.albumRef isEqual:@"addFriends"]){ // user has added friends to the recipients --> update Parse data
    
            PFQuery *query = [PFQuery queryWithClassName:@"Events"];
            [query getObjectInBackgroundWithId:self.objId block:^(PFObject *event, NSError *error) {
                    
                if (error) {
                    NSLog(@"Error: %@ %@", error, [error userInfo]);
                    [hud hide:YES];
                }
                else{ // get current Event recipient list from Parse
                    NSArray *parseRef = [event valueForKey:@"recipientIds"];
                    
                    // create an array large enough to hold the old + new recipients
                    NSInteger count = parseRef.count + recipientNames.count;
                    NSMutableArray *uniqueUserIDs = [[NSMutableArray alloc]initWithCapacity:count];
        
                    // add all recipients to the userIDs array
                    for (NSString *parseID in parseRef){
                        [uniqueUserIDs addObject:parseID];
                    }
                    for (NSString *friendID in recipientNames){
                        [uniqueUserIDs addObject:friendID];
                    }
                    // set unique recipientIDs ONLY - save to Parse in background
                    [event addUniqueObjectsFromArray:uniqueUserIDs forKey:@"recipientIds"];
            //        [event setObject:uniqueUserIDs forKey:@"recipientIds"];
                    [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                            
                    if (error) {
                        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                             message:@"Please try sending your invites again"
                                                                            delegate:self
                                                                     cancelButtonTitle:@"OK"
                                                                  otherButtonTitles:nil];
                        [alertView show];
                        [hud hide:YES];
                    }
                    else{ NSLog(@"Success!");
                        
                        if(self.pushRecipients.count > 0)
                        {
                            [self sendPushToUser:event.objectId];
                        }
                        self.navigationController.navigationBar.hidden = YES;
                        [self dismissViewControllerAnimated:NO completion:nil];
                        [self startTimer];
                        [hud hide:YES];
                    }
                }];
            }
        }];
    }
    else{
 //       NSData *imagesData = [NSKeyedArchiver archivedDataWithRootObject:nil];
 //           PFFile *file = [PFFile fileWithData:imagesData];

 //           NSString *ref = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectId]];
            eventCreator = YES;
 //           [event setObject:file forKey:ref];
            [event setObject:self.theTitle forKey:@"title"];
            [event setObject:camDeadline forKey:@"deadline"];
            [event setObject:recipientNames forKey:@"recipientIds"];
            [event setObject:[[PFUser currentUser] objectId] forKey:@"senderId"];
            [event setObject:[[PFUser currentUser] username] forKey:@"senderName"];
            [event saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                    
            if (error) {
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                    message:@"Please try sending your file again."
                                                                    delegate:self
                                                            cancelButtonTitle:@"OK"
                                                            otherButtonTitles:nil];
                [alertView show];
                [hud hide:YES];
                self.inviteButton.enabled = YES;
            }
            else{
                NSLog(@"Success! PFObject contains %@:", event);
                        
                if(self.pushRecipients.count > 0)
                {
                    [self sendPushToUser:event.objectId];
                }

                self.objId = [event valueForKey:@"objectId"];

                self.navigationController.navigationBar.hidden = YES;
                [self dismissViewControllerAnimated:NO completion:nil];
                [self startTimer];;
                self.tableView.hidden = YES;
                [hud hide:YES];
            }
        }];
    }
}

- (void)fireCamera {
    
    NSDate *todaysDate = [NSDate date];

    NSUInteger unitFlags = NSSecondCalendarUnit;
    
    NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                              fromDate:todaysDate
                                                                toDate:self.fireTime
                                                               options:NSWrapCalendarComponents];
    NSInteger seconds = [dateComparisonComponents second];
    
    if ((long)seconds == 0) {
        [self.cameraTimer invalidate];
        [self startCamera:self];
    }
}

- (IBAction)startCamera:(id)sender {
    self.captureImage.enabled = YES;
    self.videoTimer.hidden = YES;
    
    self.imagePicker = [[UIImagePickerController alloc] init];
    self.imagePicker.delegate = self;
    self.imagePicker.allowsEditing = YES;
    self.imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePicker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePicker.sourceType];
    self.imagePicker.showsCameraControls = NO;
    
    // Device's screen size
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (self.imagePicker.sourceType == UIImagePickerControllerSourceTypeCamera){
    
        if (screenSize.height == 480){
            [[NSBundle mainBundle] loadNibNamed:@"CamOverlayView4s" owner:self options:nil];
        }
        else{
            [[NSBundle mainBundle] loadNibNamed:@"OverlayView" owner:self options:nil];
        }
    }
    
    self.imagePicker.cameraOverlayView = self.overlayView;
    self.overlayView.frame = self.imagePicker.cameraOverlayView.frame;

    [self presentViewController:self.imagePicker animated:NO completion:NULL];
    
    self.previewImageView.clipsToBounds = YES;
    
    self.deadlineTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                     target:self
                                                   selector:@selector(refreshMainTimer)
                                                   userInfo:nil
                                                    repeats:YES];
    [self refreshMainTimer];
    
    self.titleLabel.text = self.theTitle;
    if (self.album.count > 0){
        self.imageCount.text = [NSString stringWithFormat:@"%lu", (unsigned long)[self.album count]];
    }
    self.startingImageCount = [self.album count];
    
    if (self.album.count > 0){
        UIImage *img = [UIImage imageWithData:[[self.album lastObject] valueForKey:@"img"]];
        self.previewImageView.image = img;
        self.image = img;
    }
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    if (![NSUD valueForKey:@"cameraTutorial"]){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"CAMERA"
                                                        message:@"Just tap the screen to take a picture. Pinch the screen to zoom."
                                                       delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alert show];
        [NSUD setObject:@"1" forKey:@"cameraTutorial"];
        [NSUD synchronize];
    }
}

#pragma mark - SEGUE
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    if ([segue.identifier isEqualToString:@"showPreview"]) {
        [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
        
        PreviewViewController *pc = (PreviewViewController *)segue.destinationViewController;
        pc.title = self.titleLabel.text;
        pc.image = self.image;
        pc.objID = self.objId;
        pc.albumRef = self.albumRef;
        pc.album = self.album;
        pc.startDate = self.startDate;
    }
    else if([segue.identifier isEqualToString:@"goHome"]){
        ActiveViewController *avc = (ActiveViewController *)segue.destinationViewController;
        avc.eventCreator = eventCreator;
        
        [self.deadlineTimer invalidate];
    }
}

@end