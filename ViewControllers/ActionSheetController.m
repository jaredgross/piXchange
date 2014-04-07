//
//  ActionSheetController.m
//  piXchange
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import "ActionSheetController.h"
#import  "FriendsViewController.h"
#import "HomeViewController.h"

#define PickerAnimationDuration    0.40   // duration for the animation to slide the date picker into view
#define DatePickerTag              99     // view tag identifiying the date picker view

#define TitleKey       @"title"   // key for obtaining the data source item's title
#define DateKey        @"date"    // key for obtaining the data source item's date value

// keep track of which rows have date cells
#define deadlineRow   0
#define dateRow     1
#define timeRow     2

#define OPTIONS_ALERT 1

static NSString *DateCellID = @"dateCell";     // the cells with the dates
static NSString *DatePickerID = @"datePicker"; // the cell containing the date picker
static NSString *OtherCell = @"otherCell";     // the remaining cells at the end

@interface ActionSheetController ()
{
    CLLocationManager *locationManager;
    CLGeocoder *geocoder;
    CLPlacemark *placemark;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@property (strong, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic, retain) NSIndexPath *datePickerIndexPath;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (nonatomic) NSInteger pickerCellRowHeight;

@property (nonatomic, retain) NSString *deadlineCounter;
@property (nonatomic, retain) NSString *releaseCounter;
@property (nonatomic, retain) NSString *dateCounter;
@property (nonatomic, retain) NSString *timeCounter;

@property (nonatomic, retain) NSString *locationData;

@property (nonatomic, retain) NSDate *endDate;
@property (nonatomic, retain) NSDate *endTime;
@property (nonatomic, retain) NSDate *releaseDate;
@property (nonatomic, retain) NSDate *now;
@property (nonatomic, strong) NSDateFormatter *df;

@property (nonatomic, retain) NSArray *dataArray;
@property (nonatomic, strong) NSCalendar *gregorian;
@property (weak, nonatomic) IBOutlet UIButton *capsuleButton;


@property (nonatomic) BOOL timerIsOff;

- (IBAction)toggleTimer:(id)sender;
- (IBAction)toggleOptions:(id)sender;
- (IBAction)hideKeyboard:(id)sender;
- (IBAction)nextButton:(id)sender;
@end

@implementation ActionSheetController{
    
}

#pragma mark - View Controller
- (void)viewDidLoad{
    [super viewDidLoad];

    self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
    
    self.df = [[NSDateFormatter alloc] init];
    [self.df setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    [self.df setTimeZone:[NSTimeZone systemTimeZone]];
    [self.df setFormatterBehavior:NSDateFormatterBehaviorDefault];
    
    self.textField.delegate = self;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    locationManager = [[CLLocationManager alloc] init];
    geocoder = [[CLGeocoder alloc] init];
}

// refreshes the view
-(void)viewWillAppear:(BOOL)animated{
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
  //  [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
     [[self navigationController] setNavigationBarHidden:NO animated:YES];

    self.textField.text = nil;
    self.timerIsOff = NO;

    NSString *newDate = [self.df stringFromDate:[NSDate date]];

    // setup data source
    NSMutableDictionary *deadline = [@{ TitleKey : @"Event Timer",
                                        DateKey : newDate } mutableCopy];
    NSMutableDictionary *date = [@{ TitleKey : @"Release Day",
                                    DateKey : newDate } mutableCopy];
    NSMutableDictionary *time = [@{ TitleKey : @"Release Time",
                                    DateKey : newDate } mutableCopy];
    NSMutableDictionary *empty = [@{ TitleKey : @"" } mutableCopy];
    self.dataArray = @[deadline, date, time, empty];
    
    // Obtain the picker cell's height
    UITableViewCell *pickerViewCellToCheck = [self.tableView dequeueReusableCellWithIdentifier:DatePickerID];
    self.pickerCellRowHeight = pickerViewCellToCheck.frame.size.height;
}
//
//-(void)viewDidAppear:(BOOL)animated{
//    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
//    if (![NSUD valueForKey:@"tutorialSetup"]){
//        UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"CREATE A NEW EVENT"
//                                                        message:@"Set the Event Timer to the day/time the event will end (max 4 days). Choose a Release day & time to create a 'digital time capsule' for the event - where the photos will be held until the specified date."
//                                                       delegate:self
//                                              cancelButtonTitle:@"OK"
//                                              otherButtonTitles:nil];
//        [alert show];
//        [NSUD setObject:@"1" forKey:@"tutorialSetup"];
//        [NSUD synchronize];
//    }
//
//}


#pragma mark - UITableViewDataSource
// Configures the rows/cells
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    UITableViewCell *cell = nil;
    
    NSString *cellID = OtherCell;
    
    if ([self indexPathHasPicker:indexPath])
    {
        // the indexPath is the one containing the inline date picker
        cellID = DatePickerID;     // the current/opened date picker cell
    }
    else if ([self indexPathHasDate:indexPath])
    {
        // the indexPath is one that contains the date information
        cellID = DateCellID;
    }
    
    cell = [tableView dequeueReusableCellWithIdentifier:cellID];
    
    if (indexPath.row == 3)
    {
        // we decide here that last cell in the table is not selectable (it's just an indicator)
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    // if we have a date picker open whose cell is above the cell we want to update, then we have one more cell than the model allows
    NSInteger modelRow = indexPath.row;
    if (self.datePickerIndexPath != nil && self.datePickerIndexPath.row < indexPath.row)
    {
        modelRow--;
    }
    
    NSDictionary *itemData = self.dataArray[modelRow];
    
    // proceed to configure our cell
    if ([cellID isEqualToString:DateCellID])
    {
        // we have a date picker, populate the date field
        cell.textLabel.text = [itemData valueForKey:TitleKey];
    }
    else if ([cellID isEqualToString:OtherCell])
    {
        // just assign it's text label
        cell.textLabel.text = [itemData valueForKey:TitleKey];
    }
	return cell;
}

// Returns height of rows/cells
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ([self indexPathHasPicker:indexPath] ? self.pickerCellRowHeight : self.tableView.rowHeight);
}

// Returns # rows/cells
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self hasInlineDatePicker])
    {
        // we have a date picker, so allow for it in the number of rows in this section
        NSInteger numRows = self.dataArray.count;
        return ++numRows;
    }
    return self.dataArray.count;
}


#pragma mark - UITableViewDelegate
// Displays picker for selected indexPath
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self.textField resignFirstResponder];
    
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.reuseIdentifier == DateCellID)
    {
        [self displayInlineDatePickerForRowAtIndexPath:indexPath];
    }
}

// Called by didSelectRowAtIndexPath
- (void)displayInlineDatePickerForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    // Display the picker inline with the table content
    [self.tableView beginUpdates];
    
    BOOL before = NO;   // Checks if picker is below indexPath, help to determine which row to reveal
    if ([self hasInlineDatePicker])
    {
        before = self.datePickerIndexPath.row < indexPath.row;
    }
    
    BOOL sameCellClicked = (self.datePickerIndexPath.row - 1 == indexPath.row);
    
    // Remove any picker cell if it exists
    if ([self hasInlineDatePicker])
    {
        [self.tableView deleteRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.datePickerIndexPath.row inSection:0]]
                              withRowAnimation:UITableViewRowAnimationFade];
        self.datePickerIndexPath = nil;
    }
    
    if (!sameCellClicked)
    {
        // Hide old picker and displays new one
        NSInteger rowToReveal = (before ? indexPath.row - 1 : indexPath.row);
        NSIndexPath *indexPathToReveal = [NSIndexPath indexPathForRow:rowToReveal inSection:0];
        
        [self toggleDatePickerForSelectedIndexPath:indexPathToReveal];
        self.datePickerIndexPath = [NSIndexPath indexPathForRow:indexPathToReveal.row + 1 inSection:0];
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [self.tableView endUpdates];
    
    [self updateDatePicker];
}

// Adds/Removes a UIDatePicker cell below the indexPath
- (void)toggleDatePickerForSelectedIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView beginUpdates];
    
    NSArray *indexPaths = @[[NSIndexPath indexPathForRow:indexPath.row + 1 inSection:0]];
    
    // Check indexPath for a date picker
    if ([self hasPickerForIndexPath:indexPath])
    {   // Found a picker, so remove it
        [self.tableView deleteRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    else
    {   // Didn't find a picker, so add one
        [self.tableView insertRowsAtIndexPaths:indexPaths
                              withRowAnimation:UITableViewRowAnimationFade];
    }
    [self.tableView endUpdates];
}

// Updates pickers's value to match date of cell above
- (void)updateDatePicker
{
    if (self.datePickerIndexPath != nil)
    {
        UITableViewCell *associatedDatePickerCell = [self.tableView cellForRowAtIndexPath:self.datePickerIndexPath];
        
        NSString *todaysDate = [self.df stringFromDate:[NSDate date]];
        NSDate *date = [self.df dateFromString:todaysDate];

        UIDatePicker *targetedDatePicker = (UIDatePicker *)[associatedDatePickerCell viewWithTag:DatePickerTag];
        if (targetedDatePicker != nil)
        {
            // we found a UIDatePicker in this cell, so update it's date value
            [targetedDatePicker setDate:date animated:NO];
            
            if(self.datePickerIndexPath.row == 1){
                targetedDatePicker.datePickerMode = UIDatePickerModeDateAndTime;
                targetedDatePicker.minimumDate = [date dateByAddingTimeInterval:60]; // 300 = 5 mins
                targetedDatePicker.maximumDate = [date dateByAddingTimeInterval:345600]; // 4 days
            } else if (self.datePickerIndexPath.row == 2){
                targetedDatePicker.datePickerMode = UIDatePickerModeDate;
                targetedDatePicker.minimumDate = date;
                targetedDatePicker.maximumDate = nil;
            } else if (self.datePickerIndexPath.row == 3){
                targetedDatePicker.datePickerMode = UIDatePickerModeTime;
                targetedDatePicker.minimumDate = nil;
                targetedDatePicker.maximumDate = nil;
            }
        }
    }
}

// Checks if TableVC has a picker in any of its cells
- (BOOL)hasInlineDatePicker{
    return (self.datePickerIndexPath != nil);
}

// Checks if indexPath has a cell below it with a picker
- (BOOL)hasPickerForIndexPath:(NSIndexPath *)indexPath{
    BOOL hasDatePicker = NO;
    
    NSInteger targetedRow = indexPath.row;
    targetedRow++;
    
    UITableViewCell *checkDatePickerCell =
    [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:targetedRow inSection:0]];
    UIDatePicker *checkDatePicker = (UIDatePicker *)[checkDatePickerCell viewWithTag:DatePickerTag];
    
    hasDatePicker = (checkDatePicker != nil);
    return hasDatePicker;
}

- (BOOL)indexPathHasPicker:(NSIndexPath *)indexPath{
    return ([self hasInlineDatePicker] && self.datePickerIndexPath.row == indexPath.row);
}

- (BOOL)indexPathHasDate:(NSIndexPath *)indexPath{
    BOOL hasDate = NO;
    
    if ((indexPath.row == deadlineRow) || (indexPath.row == dateRow) ||
        (indexPath.row == timeRow || ([self hasInlineDatePicker] && (indexPath.row == timeRow + 1))))
    {
        hasDate = YES;
    }
    return hasDate;
}

#pragma mark - ACTIONS
- (IBAction)dateAction:(id)sender{
        NSIndexPath *targetedCellIndexPath = nil;
        
        if ([self hasInlineDatePicker]){
            // inline date picker: update the cell's date "above" the date picker cell
            targetedCellIndexPath = [NSIndexPath indexPathForRow:self.datePickerIndexPath.row - 1 inSection:0];
        }else{
            // external date picker: update the current "selected" cell's date
            targetedCellIndexPath = [self.tableView indexPathForSelectedRow];
        }

        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:targetedCellIndexPath];
        UIDatePicker *targetedDatePicker = sender;
        // update our data model
        NSMutableDictionary *itemData = self.dataArray[targetedCellIndexPath.row];
        [itemData setValue:targetedDatePicker.date forKey:DateKey];
    
        NSString *ref = [self.df stringFromDate:[NSDate date]];
        NSDate *todaysDate = [self.df dateFromString:ref];
    
        if(self.datePickerIndexPath.row == 1){
            NSDate *selected = [NSDate dateWithTimeIntervalSince1970:[targetedDatePicker.date timeIntervalSince1970] - 1];
            
            self.dateFormatter = [[NSDateFormatter alloc] init];
            [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            
            self.deadlineCounter = cell.detailTextLabel.text;
            self.deadlineCounter = [self.df stringFromDate:selected];
            
            NSUInteger unitFlags = NSDayCalendarUnit | NSMinuteCalendarUnit | NSHourCalendarUnit | NSSecondCalendarUnit;
            NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                                      fromDate:todaysDate
                                                                        toDate:selected
                                                                       options:NSWrapCalendarComponents];
            NSInteger days = [dateComparisonComponents day];
            NSInteger hours = [dateComparisonComponents hour];
            NSInteger minutes = [dateComparisonComponents minute];
            NSInteger seconds = [dateComparisonComponents second];
            
            NSString *diff = [NSString stringWithFormat:@"%ld:%02ld:%02ld:%02ld",
                                    (long)days,
                                    (long)hours,
                                    (long)minutes,
                                    (long)seconds];
            
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *deadline = [NSString stringWithFormat:@"%@/deadline.txt", documentsDirectory];
            [NSKeyedArchiver archiveRootObject:self.deadlineCounter toFile:deadline];
            NSLog(@"Deadline: %@ / Timer: %@", self.deadlineCounter, diff);
            
        }
        else if (self.datePickerIndexPath.row == 2){
            NSDate *selected = [NSDate dateWithTimeIntervalSince1970:[targetedDatePicker.date timeIntervalSince1970] - 1];
            
            self.dateFormatter = [[NSDateFormatter alloc] init];
            [self.dateFormatter setDateStyle:NSDateFormatterMediumStyle];
            [self.dateFormatter setTimeStyle:NSDateFormatterNoStyle];
            
            self.dateCounter = cell.detailTextLabel.text;
            self.dateCounter = [self.df stringFromDate:selected];

            NSUInteger unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
            NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                                      fromDate:todaysDate
                                                                        toDate:selected
                                                                       options:NSWrapCalendarComponents];
            NSInteger years = [dateComparisonComponents year];
            NSInteger months = [dateComparisonComponents month];
            NSInteger days = [dateComparisonComponents day];
            
            NSString *diff = [NSString stringWithFormat:@"%ld:%02ld:%02ld",
                                (long)years,
                                (long)months,
                                (long)days];

            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *date = [NSString stringWithFormat:@"%@/date.txt", documentsDirectory];
            [NSKeyedArchiver archiveRootObject:self.dateCounter toFile:date];
            NSLog(@"Date: %@ / timer: %@", self.dateCounter, diff);
            
            self.endDate = selected;
        }
        else if (self.datePickerIndexPath.row == 3){
            
            NSDate *selected = [NSDate dateWithTimeIntervalSince1970:[targetedDatePicker.date timeIntervalSince1970] - 1];
            
            self.dateFormatter = [[NSDateFormatter alloc] init];
            [self.dateFormatter setDateStyle:NSDateFormatterNoStyle];
            [self.dateFormatter setTimeStyle:NSDateFormatterShortStyle];
            
            self.timeCounter = cell.detailTextLabel.text;
            self.timeCounter = [self.df stringFromDate:selected];
            
            NSUInteger unitFlags = NSHourCalendarUnit | NSMinuteCalendarUnit;
            NSDateComponents *dateComparisonComponents = [self.gregorian components:unitFlags
                                                                      fromDate:selected];
            NSInteger hours = [dateComparisonComponents hour];
            NSInteger minutes = [dateComparisonComponents minute];
            
            NSString *diff = [NSString stringWithFormat:@"%02ld:%02ld",
                                (long)hours,
                                (long)minutes];
            
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *time = [NSString stringWithFormat:@"%@/time.txt", documentsDirectory];
            [NSKeyedArchiver archiveRootObject:self.timeCounter toFile:time];
            NSLog(@"Time: %@ / Counter: %@", self.timeCounter, diff);
            
            self.endTime = selected;
        }
        // Update the cell's date string
        cell.detailTextLabel.text = [self.dateFormatter stringFromDate:targetedDatePicker.date];
}

- (IBAction)toggleOptions:(id)sender{

    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"OPTIONS"
                                                    message:@""
                                                   delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"ACTIVE EVENTS", @"TIME CAPSULES", @"SHARED ALBUMS", @"Logout", nil];
    alert.tag = OPTIONS_ALERT;
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    if (alertView.tag == OPTIONS_ALERT){
        if (buttonIndex == 1){ // Active
            
            NSArray *caps = [NSUD arrayForKey:@"activeEventIDs"];
            if (caps.count == 0){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [self performSegueWithIdentifier:@"active" sender:self];
            self.navigationController.navigationBar.hidden = YES;
        }
        else if (buttonIndex == 2){ // Unreleased
            
            NSArray *caps = [NSUD arrayForKey:@"objectIDReference"];
            NSString *query = [NSUD valueForKey:@"needNewQuery"];
            if (caps.count == 0 && ![query isEqual:@"yes"]){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [self performSegueWithIdentifier:@"unreleased" sender:self];
            self.navigationController.navigationBar.hidden = YES;
        }
        else if (buttonIndex == 3){ // Shared
            
            NSArray *caps = [NSUD arrayForKey:@"oldIDsReference"];
            NSString *query = [NSUD valueForKey:@"needNewQuery"];
            if (caps.count == 0 && ![query isEqual:@"yes"]){
                [NSUD setObject:@"1" forKey:@"defaults"];
            }
            
            [self performSegueWithIdentifier:@"released" sender:self];
            self.navigationController.navigationBar.hidden = YES;
        }
        else if (buttonIndex == 4){ // Logout
            [PFUser logOut];
            [self performSegueWithIdentifier:@"leave" sender:self];
        }
        [NSUD setObject:nil forKey:@"needsNewQuery"];
        [NSUD synchronize];
    }
}

- (IBAction)hideKeyboard:(id)sender{
    [self.textField resignFirstResponder];
}

- (IBAction)nextButton:(id)sender{
    NSString *name = [self.textField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];

    if (name.length > 22){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                            message:@"Please choose a name less than 20 characters" delegate:nil
                                                  cancelButtonTitle:@"OK"
                                                  otherButtonTitles:nil];
        [alertView show];
        return;
    }

    if(self.timerIsOff == YES){
        if ([name length] == 0 || (self.deadlineCounter == NULL)){
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                                message:@"Make sure you pick a name and timer for the camera before continuing!" delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
            return;
        }else{
            [self getDates];
        }
    }
    else if ([name length] == 0 || (self.deadlineCounter == NULL) || (self.dateCounter == NULL) || (self.timeCounter == NULL) || self.endDate == nil || self.endTime == nil){
            
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                                message:@"Make sure you complete all the required fields before continuing!"
                                                               delegate:nil
                                                      cancelButtonTitle:@"OK"
                                                      otherButtonTitles:nil];
            [alertView show];
        return;
    }
    else if ([name length] > 0 && (self.deadlineCounter != nil)){
        [self getDates];
    }
}

-(void)getDates{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    
    NSString *ref = [self.df stringFromDate:[NSDate date]];
    NSDate *now = [self.df dateFromString:ref];

    NSDateComponents *releaseComparisonComponents;
    // set up new flags to determine difference in time between newDate and now
    NSUInteger releaseFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit | NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
    NSDate *dateTime;
    
    if (self.timerIsOff == YES){
        releaseComparisonComponents = [self.gregorian components:releaseFlags
                                                   fromDate:[NSDate date]
                                                     toDate:now
                                                    options:NSWrapCalendarComponents];
    }else{

        // establish a calander to use
//        self.gregorian = [[NSCalendar alloc] initWithCalendarIdentifier:NSGregorianCalendar];
        // get the components to use from the date
        NSUInteger dateFlags = NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit;
        NSDateComponents *dateComponents = [self.gregorian components:dateFlags
                                                             fromDate:self.endDate];
        
        
        // this adjusts the day component of the date because the flags register the date as: 12-12-12 23:59:59 instead of 12-13-12
        NSInteger newDay = dateComponents.day + 1;
        dateComponents.day = newDay;
        

        // get the components to use from the time
        NSUInteger timeFlags = NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit;
        NSDateComponents *timeComponents = [self.gregorian components:timeFlags
                                                        fromDate:self.endTime];
        // gets the gregorian date from the components
        NSDate *dateFromComponents = [self.gregorian dateFromComponents:dateComponents];
        // gets the gregorian time from the components and adds it to the date
        NSDate *dt = [self.gregorian dateByAddingComponents:timeComponents toDate:dateFromComponents  options:0];
        NSString *ref = [self.df stringFromDate:dt];
        dateTime = [self.df dateFromString:ref];
        
        // set up the dates to compare and the flags to use for comparison
        releaseComparisonComponents = [self.gregorian components:releaseFlags
                                                   fromDate:[NSDate date]
                                                     toDate:dateTime
                                                    options:NSWrapCalendarComponents];
    }
    // returns the new date components
    NSInteger newYears = [releaseComparisonComponents year];
    NSInteger newMonths = [releaseComparisonComponents month];
    NSInteger newDays = [releaseComparisonComponents day];
    NSInteger newHours = [releaseComparisonComponents hour];
    NSInteger newMinutes = [releaseComparisonComponents minute];
    NSInteger newSeconds = [releaseComparisonComponents second];

    // formats the components into the form they will be displayed to the user
    self.releaseCounter = [NSString stringWithFormat:@"%ld:%02ld:%02ld:%02ld:%02ld:%02ld",
                           (long)newYears,
                           (long)newMonths,
                           (long)newDays,
                           (long)newHours,
                           (long)newMinutes,
                           (long)newSeconds];
    
    
    
    NSString *date = [NSString stringWithFormat:@"%@/deadline.txt", documentsDirectory];
    NSString *dl = [NSKeyedUnarchiver unarchiveObjectWithFile:date];
    NSDate *deadline = [self.df dateFromString:dl];
    NSDate *laterDate = [deadline laterDate:dateTime];
    
    if(self.timerIsOff == NO && [laterDate isEqual:deadline]) { // check the release timer status
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Oops!"
                                                    message:@"Please check to make sure the release date is later than the camera deadline"
                                                    delegate:self
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
        [alertView show];
    }
    else{
        locationManager.delegate = self;
        locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        [locationManager startUpdatingLocation];
        
        NSString *releaseDate = [NSString stringWithFormat:@"%@/releaseCounter.txt", documentsDirectory];
        NSString *eventTitle = [NSString stringWithFormat:@"%@/title.txt", documentsDirectory];
        [NSKeyedArchiver archiveRootObject:dateTime toFile:releaseDate];
        [NSKeyedArchiver archiveRootObject:self.textField.text toFile:eventTitle];
        
        [self performSegueWithIdentifier:@"showFriends" sender:self];
    }
}

#pragma mark - HELPERS
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 568){
        self.hidesBottomBarWhenPushed = YES;
    }
    
    if ([segue.identifier isEqualToString:@"showFriends"]) {
        [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
        FriendsViewController *friendsVC = (FriendsViewController *)segue.destinationViewController;
        friendsVC.theTitle = self.textField.text;
        
        NSDate *ref = [self.df dateFromString:self.deadlineCounter];
        friendsVC.startDate = ref;
    }

    self.locationData = nil;
    self.deadlineCounter = nil;
    self.releaseCounter = nil;
}

// gets the users current location
- (void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation{
//    NSLog(@"didUpdateToLocation: %@", newLocation);
    CLLocation *currentLocation = newLocation;

    // Reverse Geocoding
    [geocoder reverseGeocodeLocation:currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
//        NSLog(@"Found placemarks: %@, error: %@", placemarks, error);
        if (error == nil && [placemarks count] > 0) {
            [locationManager stopUpdatingLocation];
            
            placemark = [placemarks lastObject];
            self.locationData = [NSString stringWithFormat:@"%@, %@",
                                 placemark.locality,
                                 placemark.administrativeArea];
        } else {
 //           NSLog(@"%@", error.debugDescription);
        }
        // write the location to storage
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *location = [NSString stringWithFormat:@"%@/location.txt", documentsDirectory];
        [NSKeyedArchiver archiveRootObject:self.locationData toFile:location];
        
//        NSLog(@"Title: %@", self.textField.text);
//        NSLog(@"Location:  %@", self.locationData);
//        NSLog(@"Deadline: %@", self.deadlineCounter);
//        NSLog(@"Release Counter: %@", self.releaseCounter);
    } ];
}

-(IBAction)toggleTimer:(id)sender{ // get a reference to the array of cells
    NSArray *array = [self.tableView.indexPathsForVisibleRows copy];
    UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[array objectAtIndex:1]];
    UITableViewCell *cell2 = [self.tableView cellForRowAtIndexPath:[array objectAtIndex:2]];

    if (self.timerIsOff == YES){ // auto-release is off --> turn it on & unhide the cells
        [self.capsuleButton setImage:[UIImage imageNamed:@"releaseON"] forState:normal];
        self.timerIsOff = NO;
        cell.hidden = NO;
        cell2.hidden = NO;
        
        cell.detailTextLabel.text = @"Tap to set";
        cell2.detailTextLabel.text = @"Tap to set";
        
        self.endDate = nil;
        self.endTime = nil;

        if ([array count] != 4){ // a pickerView cell was showing --> unhide the additional cells
            UITableViewCell *cell3 = [self.tableView cellForRowAtIndexPath:[array objectAtIndex:3]];
            UITableViewCell *cell4 = [self.tableView cellForRowAtIndexPath:[array objectAtIndex:4]];
            cell3.hidden = NO;
            cell4.hidden = NO;
            
            cell3.detailTextLabel.text = @"Tap to set";
            cell4.detailTextLabel.text = @"Tap to set";
        }
    }else{ // auto-release is on --> turn it off & hide the cells
        self.endDate = nil;
        self.endTime = nil;
        
        [self.capsuleButton setImage:[UIImage imageNamed:@"releaseOFF"] forState:normal];
        self.timerIsOff = YES;
        cell.hidden = YES;
        cell2.hidden = YES;
        
        if ([array count] != 4){ // a pickerView cell is showing --> hide the additional cells
            UITableViewCell *cell3 = [self.tableView cellForRowAtIndexPath:[array objectAtIndex:3]];
            UITableViewCell *cell4 = [self.tableView cellForRowAtIndexPath:[array objectAtIndex:4]];
            cell3.hidden = YES;
            cell4.hidden = YES;
        }
    }
}

@end
