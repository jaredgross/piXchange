//
//  DetailViewController.m
//  Flashback
//
//  Created by Jared Gross on 9/24/13.
//  Copyright (c) 2013 Kickin'Appz. All rights reserved.
//

#import "DetailViewController.h"
#import "PECropViewController.h"
#import "ScratchPadViewController.h"
#import "PagedScrollViewController.h"
#import "CollectionViewController.h"
#import "MBProgressHUD.h"

#define OPTIONS_SAVE 1
#define OPTIONS_DELETE 2

@interface DetailViewController () <UIPickerViewDataSource, UIPickerViewDelegate> {
    BOOL     delete;
}

- (IBAction)hideBarsButton:(id)sender;


@property (weak, nonatomic) IBOutlet UIBarButtonItem *trashButton;
@property (nonatomic, weak) IBOutlet UIButton *hideBarsButton;
@property (nonatomic, retain) NSMutableArray *titles;
@property (nonatomic, retain) NSMutableDictionary *filtersDict;
@property (nonatomic, retain) NSMutableArray *filtersArray;
@property (nonatomic, retain) NSMutableArray *filtersNamesArray;

@property (nonatomic, weak) IBOutlet UIView *editPhotoOverlay;
@property (nonatomic, retain) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIPickerView *pickerView;
@property (nonatomic, strong) IBOutlet UIButton *hidePicker;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIButton *showPicker;
@property (nonatomic, strong) IBOutlet UIToolbar *toolBar;
@property (nonatomic, strong) UIImage *currentImage;
@property (nonatomic, retain) UIImage *retImage;
@property (nonatomic, retain) UIImage *saveImage;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *drawPadButton;

- (IBAction)showScratchpad:(id)sender;
- (IBAction)deleteImage:(id)sender;
- (IBAction)saveButton:(id)sender;
- (IBAction)cropImage:(id)sender;
- (IBAction)filterButton:(id)sender;
- (IBAction)hidePicker:(id)sender;
- (IBAction)showPicker:(id)sender;
- (IBAction)cancelButton:(id)sender;
- (IBAction)doneButton:(id)sender;
- (IBAction)backButton:(id)sender;
@end

@implementation DetailViewController


#pragma mark - VIEW CONTROLLER
// Initialize the VC
- (void)viewDidLoad
{   [super viewDidLoad];

    
    // Device's screen size
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 480){
        [[NSBundle mainBundle] loadNibNamed:@"editPhoto_i4" owner:self options:nil];
        
        if (self.image.size.width == 600 || self.image.size.height == 800) {
            [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
            self.imageView.clipsToBounds = YES;
        }
    }
    else{
        [[NSBundle mainBundle] loadNibNamed:@"editPhoto_i5" owner:self options:nil];
        self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    self.view = self.editPhotoOverlay;
 
    self.pickerView.dataSource = self;
    self.pickerView.delegate = self;
    
    self.pickerView.hidden = YES;
    self.hidePicker.hidden = YES;
    self.showPicker.hidden = YES;
    self.doneButton.hidden = YES;
    self.toolBar.hidden = NO;
    self.cancelButton.hidden = YES;
    
    if ([self.albumRef isEqual:@"dropped"]){
        self.trashButton.enabled = NO;
    }
    
    // Create a dictionary to reference the CIFilters by a new name
    self.filtersDict = [[NSMutableDictionary alloc] init];
    [self.filtersDict setObject:@"CISepiaTone" forKey:@"Sepia Tone"];
    [self.filtersDict setObject:@"CISharpenLuminance" forKey:@"Sharpen"];
    [self.filtersDict setObject:@"CILinearToSRGBToneCurve" forKey:@"Lighten"];
    [self.filtersDict setObject:@"CISRGBToneCurveToLinear" forKey:@"Darken"];
    [self.filtersDict setObject:@"CIPhotoEffectTransfer" forKey:@"Ink Transfer"];
    [self.filtersDict setObject:@"CIPixellate" forKey:@"Pixellate"];
    [self.filtersDict setObject:@"CIPhotoEffectTonal" forKey:@"Grayscale"];
    [self.filtersDict setObject:@"CIPhotoEffectProcess" forKey:@"Washed"];
    [self.filtersDict setObject:@"CIPhotoEffectNoir" forKey:@"B&W Contrast"];
    [self.filtersDict setObject:@"CIPhotoEffectMono" forKey:@"Black & White"];
    [self.filtersDict setObject:@"CIPhotoEffectInstant" forKey:@"Vintage"];
    [self.filtersDict setObject:@"CIPhotoEffectFade" forKey:@"Faded"];
    [self.filtersDict setObject:@"CIPhotoEffectChrome" forKey:@"Chrome"];

    self.filtersArray = [NSMutableArray arrayWithObject:self.filtersDict];
    [self.filtersArray addObject:self.filtersDict.allValues];
    self.filtersArray = [self.filtersArray objectAtIndex:1];
    
    self.filtersNamesArray = [NSMutableArray arrayWithObject:self.filtersDict];
    [self.filtersNamesArray addObject:self.filtersDict.allKeys];
    self.filtersNamesArray = [self.filtersNamesArray objectAtIndex:1];

    if (self.image.size.height == 600){
        self.imageView.transform = CGAffineTransformMakeRotation(-M_PI/2);
        self.imageView.bounds = CGRectMake (0,0,480,320);
    }
    
    /* Create the Tap Gesture Recognizer */
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                 initWithTarget:self
                                 action:@selector(handleTaps:)];
    self.tapGestureRecognizer.numberOfTouchesRequired = 1;
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.hideBarsButton addGestureRecognizer:self.tapGestureRecognizer];
}

- (void) viewWillAppear:(BOOL)animated{
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *scratchImage = [NSString stringWithFormat:@"%@/scratchImage.txt", documentsDirectory];
    UIImage *img = [NSKeyedUnarchiver unarchiveObjectWithFile:scratchImage];
    
    if (img){
        self.image = img;
        [NSKeyedArchiver archiveRootObject:nil toFile:scratchImage];
    }
    
    
//    if ((self.image.size.height != 800) || (self.image.size.width != 600)){
//        self.drawPadButton.enabled = NO;
//    }

    // Keeps an instance of the original
    self.imageView.image = self.image;
    self.currentImage = self.imageView.image;
}

#pragma mark - PICKER ** DATA SOURCE
// Returns the # of components in the picker
- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView  {
    return 1;
}

// Returns the # of filters in the filters array
- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component  {
    return [self.filtersArray count];
}


#pragma mark - PICKER ** DELEGATE
// Returns the array of names assigned to each filter
- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component  {
    return [self.filtersNamesArray objectAtIndex:row];
}

// User choose a filter from the picker
- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    // Creates a new instance (ciImage) of the image and the filter to be applied
    CIImage *ciImage = [[CIImage alloc] initWithImage:self.currentImage];
    
    CIFilter *filter = [CIFilter filterWithName:[self.filtersArray objectAtIndex:row]
                                  keysAndValues:kCIInputImageKey, ciImage, nil];
    [filter setDefaults];
    // Returns new image with the combined context of ciImage and the chosen filter
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *outputImage = [filter outputImage];
    CGImageRef refImage = [context createCGImage:outputImage
                                       fromRect:[outputImage extent]];
    // Set the view show new image
    self.retImage = [UIImage imageWithCGImage:refImage];
    CGImageRelease(refImage);
    self.imageView.image = self.retImage;
}


#pragma mark - TOOLBAR ** ACTIONS
// Shows filters screen
- (IBAction)filterButton:(id)sender
{
    self.hideBarsButton.enabled = NO;
    self.toolBar.hidden= YES;
    self.showPicker.hidden = YES;
    self.pickerView.hidden = NO;
    self.doneButton.hidden = NO;
    self.hidePicker.hidden = NO;
    self.cancelButton.hidden = NO;
    
    self.navigationController.navigationBar.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

// Shows crop image screen
- (IBAction)cropImage:(id)sender
{
    self.hideBarsButton.enabled = NO;
    
    PECropViewController *controller = [[PECropViewController alloc] init];
    controller.delegate = self;
    controller.image = self.imageView.image;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:controller];
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [self presentViewController:navigationController animated:YES completion:NULL];
}


#pragma mark - FILTER VIEW ** ACTIONS
// Shows Filters Picker
- (IBAction)showPicker:(id)sender
{
    self.showPicker.hidden = YES;
    self.pickerView.hidden = NO;
    self.doneButton.hidden = NO;
    self.hidePicker.hidden = NO;
    self.cancelButton.hidden = NO;
}
// Hides Filters Picker
- (IBAction)hidePicker:(id)sender
{
    self.pickerView.hidden = YES;
    self.doneButton.hidden = YES;
    self.hidePicker.hidden = YES;
    self.showPicker.hidden = NO;
    self.cancelButton.hidden = YES;
}
// Hides filter screen (image filtered)
- (IBAction)doneButton:(id)sender
{
    self.hideBarsButton.enabled = YES;
    self.toolBar.hidden = NO;
    self.pickerView.hidden = YES;
    self.doneButton.hidden = YES;
    self.showPicker.hidden = YES;
    self.hidePicker.hidden = YES;
    self.cancelButton.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.hidden = NO;
}

// Hides filter sceen (image UN-filtered)
- (IBAction)cancelButton:(id)sender
{
    self.hideBarsButton.enabled = YES;
    self.toolBar.hidden = NO;
    self.pickerView.hidden = YES;
    self.doneButton.hidden = YES;
    self.showPicker.hidden = YES;
    self.cancelButton.hidden = YES;
    self.hidePicker.hidden = YES;
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.navigationController.navigationBar.hidden = NO;
    
    // Sets the imageView back to state before Filter View
    self.imageView.image = self.currentImage;
}


#pragma mark - CROP IMAGE ** ACTIONS
// Cropping ended with Save
- (void)cropViewController:(PECropViewController *)controller didFinishCroppingImage:(UIImage *)croppedImage
{   [controller dismissViewControllerAnimated:YES completion:NULL];
    self.navigationController.navigationBar.hidden = NO;
    self.currentImage = croppedImage;
    self.imageView.image = croppedImage;
    
//    if ((croppedImage.size.height != 800) || (croppedImage.size.width != 600)){
//        self.drawPadButton.enabled = NO;
//    }
    
    self.hideBarsButton.enabled = YES;
}

// Cropping ended with Cancel
- (void)cropViewControllerDidCancel:(PECropViewController *)controller
{   [controller dismissViewControllerAnimated:YES completion:NULL];
    self.navigationController.navigationBar.hidden = NO;
    self.hideBarsButton.enabled = YES;
}


#pragma mark - SEGUE
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    
//    if ([segue.identifier isEqualToString:@"showScratchpad"]) { // user choose to draw on the photo
//        
//        // set the properties to be handed to the Scratch Pad
//        ScratchPadViewController *scratchVC = (ScratchPadViewController *)segue.destinationViewController;
//        scratchVC.albumCount = self.albumCount;
//        scratchVC.albumRef = self.albumRef;
//        scratchVC.album = self.album;
//        scratchVC.albumTitle = self.albumTitle;
//        scratchVC.objId = self.objId;
//        scratchVC.index = self.index;
//        
//        if (self.imageView.image == self.currentImage){ // the image has not been changed yet
//            // send the Original image
//            scratchVC.image = self.currentImage;
//        }
//        else
//            // send the Altered image
//            scratchVC.image = self.imageView.image;
//        }
//    else
        if ([segue.identifier isEqualToString:@"showPages"]){ // user choose to return to the Paged Scroll View Controller
        
        // set the properties that will be handed to the Paged Scroller
        PagedScrollViewController *photoVC = (PagedScrollViewController *)segue.destinationViewController;
        photoVC.albumCount = self.albumCount;
        photoVC.album = self.album;
        photoVC.albumTitle = self.albumTitle;
        photoVC.albumRef = self.albumRef;
        photoVC.page = self.index;
        photoVC.objId = self.objId;
    }
    else if ([segue.identifier isEqualToString:@"showAlbum"]){ // user choose to save or delete the image --> update Parse
        

        // set the properties to be handed to the Collection View Controller
        CollectionViewController *collVC = (CollectionViewController *)segue.destinationViewController;
        collVC.albumCount = self.albumCount;
        collVC.album = self.album;
        collVC.title = self.albumTitle;
        collVC.albumRef = self.albumRef;
        collVC.objId = self.objId;
    }
}

- (IBAction)backButton:(id)sender
{
    [self performSegueWithIdentifier:@"showPages" sender:self];
}

- (IBAction)showScratchpad:(id)sender {
    
    ScratchPadViewController *pad = [[ScratchPadViewController alloc]init];
    
    pad.albumCount = self.albumCount;
    pad.albumRef = self.albumRef;
    pad.album = self.album;
    pad.albumTitle = self.albumTitle;
    pad.objId = self.objId;
    pad.index = self.index;
    
    if (self.imageView.image == self.currentImage){ // the image has not been changed yet
        // send the Original image
        pad.image = self.currentImage;
    }
    else{
        // send the Altered image
        pad.image = self.imageView.image;
    }

    [self presentViewController:pad animated:NO completion:nil];
}

- (IBAction)deleteImage:(id)sender{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                               message:@"This will permanentely delete the photo from the album."
                                              delegate:self
                                      cancelButtonTitle:@"Cancel"
                                      otherButtonTitles:@"YES", nil];
    alert.tag = OPTIONS_DELETE;
    [alert show];
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    
    if (alertView.tag == OPTIONS_DELETE){
        if (buttonIndex == 1){ // user choose to delete the photo from the album
            [self.album removeObjectAtIndex:self.index];
            self.albumCount = self.albumCount - 1;
            
            
            
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *str = [NSString stringWithFormat:@"%@/userImagesRef.txt", documentsDirectory];
            NSMutableArray *userImagesArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
            
//            // need to save the image to the current groupAlbums album
//            NSString *str1 = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", documentsDirectory];
//            NSArray *grpAlbs = [NSKeyedUnarchiver unarchiveObjectWithFile:str1];
            
            NSString *str2 = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", documentsDirectory];
            NSArray *usrAlbs = [NSKeyedUnarchiver unarchiveObjectWithFile:str2];
            
//            NSMutableArray *groupAlbums = [[NSMutableArray alloc]initWithArray:grpAlbs];
            NSMutableArray *userAlbums = [[NSMutableArray alloc]initWithArray:usrAlbs];
            
            NSInteger i;
            for (NSMutableArray *tempArray in userAlbums){
                NSObject *obj = [tempArray objectAtIndex:0];
                NSString *str = [obj valueForKey:@"objID"];
                if ([str isEqual:self.objId]){
                    i = [userAlbums indexOfObject:tempArray];
                    break;
                }
            }
            
            NSMutableArray *tempUsers = [userAlbums objectAtIndex:i];
//            NSMutableArray *temp = [groupAlbums objectAtIndex:i];

            [userImagesArray removeObjectAtIndex:self.index];
            [tempUsers removeObjectAtIndex:self.index];
//            [temp removeObjectAtIndex:self.index];
            
            [userAlbums replaceObjectAtIndex:i withObject:tempUsers];
            
//            [groupAlbums replaceObjectAtIndex:i withObject:temp];
            
//            [NSKeyedArchiver archiveRootObject:groupAlbums toFile:str1];
            [NSKeyedArchiver archiveRootObject:userImagesArray toFile:str];
            
            
            
            
            
            [self queryParse];
            delete = YES;
        }
    }
    else if (alertView.tag == OPTIONS_SAVE){
        if (buttonIndex == 1){ // user choose to save the photo to the album
            self.albumCount = self.albumCount + 1;
            [self.album addObject:self.imageView.image];
            
            
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *str = [NSString stringWithFormat:@"%@/userImagesRef.txt", documentsDirectory];
            NSMutableArray *userImagesArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
            
            // need to save the image to the current groupAlbums album
            NSString *str1 = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", documentsDirectory];
            NSArray *grpAlbs = [NSKeyedUnarchiver unarchiveObjectWithFile:str1];
            
            NSMutableArray *groupAlbums = [[NSMutableArray alloc]initWithArray:grpAlbs];
            
            NSInteger i;
            for (NSMutableArray *tempArray in groupAlbums){
                NSObject *obj = [tempArray objectAtIndex:0];
                NSString *str = [obj valueForKey:@"objID"];
                if ([str isEqual:self.objId]){
                    i = [groupAlbums indexOfObject:tempArray];
                    break;
                }
            }
            
            NSMutableArray *temp = [groupAlbums objectAtIndex:i];
            
    
            NSData *imageData = UIImageJPEGRepresentation(self.imageView.image, .8f);
            NSString *userID = [[PFUser currentUser] objectId];
            NSDictionary *imageFile = @{
                                    @"objID" : self.objId,
                                    @"userID" : userID,
                                    @"title" : self.albumTitle,
                                    @"img" : imageData,  };
            
            [userImagesArray addObject:imageFile];
            [temp addObject:imageFile];
            
            [groupAlbums replaceObjectAtIndex:i withObject:temp];
            
            [NSKeyedArchiver archiveRootObject:groupAlbums toFile:str1];
            [NSKeyedArchiver archiveRootObject:userImagesArray toFile:str];
            
            [self queryParse];
            delete = NO;
        }
    }
}

-(void) queryParse{

    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    if (delete == YES){
        hud.labelText = @"Deleting album...";
    }else if (delete == NO){
        hud.labelText = @"Saving to album...";
    }
    
    [hud show:YES];
    
    
    // get a string reference to the current users ID
    NSString *ref = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectId]];
    NSMutableArray *userImagesArray;
    NSString *str;
    NSArray *albums;
    NSString *objectID;
    NSArray *temp;
    
    if(delete == NO){
        
        
        NSString *NSDD = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) lastObject];

        if ([self.albumRef isEqual:@"cloud"]){
            str = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", NSDD];
            albums = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
            NSString *ids = [NSString stringWithFormat:@"%@/currentObjIDs.txt", NSDD];
            temp = [NSKeyedUnarchiver unarchiveObjectWithFile:ids];
            objectID = [temp objectAtIndex:0];
        }
        else if ([self.albumRef isEqual:@"dropped"]){
            str = [NSString stringWithFormat:@"%@/releasedAlbums.txt", NSDD];
            albums = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
            NSString *str = [NSString stringWithFormat:@"%@/releasedUserObjIDs.txt", NSDD];
            temp = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
            objectID = [temp objectAtIndex:0];
        }
        
        NSMutableArray *tempAlbums = [[NSMutableArray alloc]initWithArray:albums];
        
        NSInteger i;
        for (NSMutableArray *tempArray in tempAlbums){
            NSObject *obj = [tempArray objectAtIndex:0];
            NSString *str = [obj valueForKey:@"objID"];
            if ([str isEqual:self.objId]){
                i = [tempAlbums indexOfObject:tempArray];
                break;
            }
        }
        NSMutableArray *friendsImagesArray;
        
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *str1 = [NSString stringWithFormat:@"%@/userImagesRef.txt", documentsDirectory];
        userImagesArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str1];
        
        if ([self.albumRef isEqual:@"dropped"]){
            NSString *str2 = [NSString stringWithFormat:@"%@/friendsImagesRef.txt", documentsDirectory];
            friendsImagesArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str2];
        }
        
        NSMutableArray *images = [[NSMutableArray alloc]initWithCapacity:friendsImagesArray.count + userImagesArray.count];
        
        [images addObjectsFromArray:userImagesArray];
        [images addObjectsFromArray:friendsImagesArray];
        
        [tempAlbums replaceObjectAtIndex:i withObject:images];
        
        if ([self.albumRef isEqual:@"cloud"]){
            str = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", NSDD];
            [NSKeyedArchiver archiveRootObject:tempAlbums toFile:str];
        }
        else if ([self.albumRef isEqual:@"dropped"]){
            str = [NSString stringWithFormat:@"%@/releasedAlbums.txt", NSDD];
            [NSKeyedArchiver archiveRootObject:tempAlbums toFile:str];
            
        }
    }
    
    NSData *imagesData = [NSKeyedArchiver archivedDataWithRootObject:userImagesArray];
    PFFile *file = [PFFile fileWithData:imagesData];

    PFQuery *query = [PFQuery queryWithClassName:@"Images"];

    // Retrieve the object by id
    [query getObjectInBackgroundWithId:objectID block:^(PFObject *object, NSError *error) {
        
        object[@"content"] = file;
        object[@"userID"] = ref;
        
        // add the relationship to the events objectID
        object[@"parent"] = self.objId;

        [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error){
            
            if (error){
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                    message:@"Please try saving your image again."
                                                                   delegate:self
                                                          cancelButtonTitle:@"OK"
                                                          otherButtonTitles:nil];
                [alertView show];
            }
            else{
                
                NSLog (@"success!! saved file");
                [self performSegueWithIdentifier:@"showAlbum" sender:self];
            }
            
            [hud hide:YES];
        }];
    }];
}

- (IBAction)saveButton:(id)sender{
    
    if ((self.album.count >= 100) || (self.albumCount >= 100)){
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Sorry!"
                                                message:@"This photo can't be saved because you've reached your limit of 100."
                                               delegate:self
                                        cancelButtonTitle:@"Cancel"
                                        otherButtonTitles:nil];
        [alert show];
    }else{
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"SAVE"
                                                   message:@"Save this photo to the album?"
                                                  delegate:self
                                          cancelButtonTitle:@"Cancel"
                                          otherButtonTitles:@"YES",nil];
        alert.tag = OPTIONS_SAVE;
        [alert show];
    }
}

- (void)handleTaps:(UITapGestureRecognizer*)paramSender{ // user tapped the screen
    if ([paramSender isEqual:self.tapGestureRecognizer]){ // check for tapGestureRecognizer
        if (paramSender.numberOfTapsRequired == 1){ // user tapped one time
            if (self.navigationController.navigationBar.hidden == YES){ // nav & status bars are hidden
//                self.navigationController.navigationBar.hidden = NO; // unhide the nav & status bars
            
                [[self navigationController] setNavigationBarHidden:NO animated:YES];
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
                self.toolBar.hidden = NO;
            }else{ // nav bar is not hidden, so hide it
                [[self navigationController] setNavigationBarHidden:YES animated:YES];
//                self.navigationController.navigationBar.hidden = YES;
                [[UIApplication sharedApplication] setStatusBarHidden:YES];
                self.toolBar.hidden = YES;
            }
        }
    }
}

- (IBAction)hideBarsButton:(id)sender {
}
@end
