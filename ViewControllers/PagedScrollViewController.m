//
//  PagedScrollViewController.m
//  Flashback
//
//  Created by Jared Gross on 11/17/2013.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "PagedScrollViewController.h"
#import "DetailViewController.h"
#import "CollectionViewController.h"

@interface PagedScrollViewController ()
@property (nonatomic, strong) NSMutableArray *pageViews;
@property (nonatomic, weak) UIImage *currentImage;
@property (nonatomic, strong) UIImage *resizeImage;
@property (nonatomic, strong) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *theTitle;

@property (nonatomic, strong) IBOutlet UIView *pagesOverlay;

@property (nonatomic) NSInteger pageCount;

@property (nonatomic, weak) NSString *check;

@property (nonatomic, unsafe_unretained) CGFloat currentScale;

@property (nonatomic, strong) UILongPressGestureRecognizer *longPressGestureRecognizer;
@property (nonatomic, strong) UITapGestureRecognizer *tapGestureRecognizer;

- (void)loadVisiblePages;
- (void)loadPage:(NSInteger)page;
- (void)purgePage:(NSInteger)page;

- (IBAction)editButton:(id)sender;
- (IBAction)backButton:(id)sender;
@end

@implementation PagedScrollViewController

@synthesize scrollView = _scrollView;
@synthesize album = _album;
@synthesize pageViews = _pageViews;

#pragma mark - VIEW CONTROLLER LIFE CYCLE

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    self.navigationController.navigationBarHidden = NO;
    
    [[NSBundle mainBundle] loadNibNamed:@"pagesOverlayView" owner:self options:nil];
    self.view = self.pagesOverlay;
    
    //Set Notifications so that when user rotates phone, the orientation is reset to landscape.
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    //Refer to the method didRotate:
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRotate:)
                                                 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    /* First create the gesture recognizer */
    self.longPressGestureRecognizer = [[UILongPressGestureRecognizer alloc]initWithTarget:self
                                                                                   action:@selector(handleLongPressGestures:)];
    self.longPressGestureRecognizer.numberOfTouchesRequired = 1;
    self.longPressGestureRecognizer.allowableMovement = 100.0f;
    self.longPressGestureRecognizer.minimumPressDuration = 1.0;
    [self.pagesOverlay addGestureRecognizer:self.longPressGestureRecognizer];

    /* Create the Tap Gesture Recognizer */
    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]
                                 initWithTarget:self
                                 action:@selector(handleTaps:)];
    self.tapGestureRecognizer.numberOfTouchesRequired = 1;
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.pagesOverlay addGestureRecognizer:self.tapGestureRecognizer];
    
    
    NSMutableArray *userAlbumsArray;
    if ([self.albumRef isEqual:@"dropped"]){
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *str = [NSString stringWithFormat:@"%@/releasedAlbums.txt", documentsDirectory];
        userAlbumsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
    }
    else if ([self.albumRef isEqual:@"cloud"]){
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *str = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", documentsDirectory];
        userAlbumsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
    }
    
    NSMutableArray *albumData;
    // get the album array related to the objectID
    for (NSArray *array in userAlbumsArray){
        if (array.count != 0){
            NSObject *obj1 = [array objectAtIndex:0];
            
            if ([[obj1 valueForKey:@"objID"] isEqual:self.objId]){
                
                NSInteger i = [userAlbumsArray indexOfObject:array];
                albumData = [userAlbumsArray objectAtIndex:i];
                break;
            }
        }
    }
    
    NSMutableArray *theAlbum = [[NSMutableArray alloc]initWithCapacity:albumData.count];
    NSMutableArray *userAlbum = [[NSMutableArray alloc]initWithCapacity:albumData.count];
    NSMutableArray *friendsImages = [[NSMutableArray alloc]initWithCapacity:albumData.count];
    for(NSObject *obj in albumData){
        
        NSData *tempDat = [obj valueForKey:@"img"];
        
        NSString *userCheck = [obj valueForKey:@"userID"];
        
        UIImage *image = [UIImage imageWithData:tempDat];
        
        // save a reference to the current users images only
        if ([userCheck isEqual:[[PFUser currentUser] objectId]]){
            [userAlbum addObject:obj];
        }
        else if (![userCheck isEqual:[[PFUser currentUser] objectId]]){
            [friendsImages addObject:obj];
        }

        [theAlbum addObject:image];
    }
    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    if (userAlbum.count > 0){
        
        NSString *str = [NSString stringWithFormat:@"%@/userImagesRef.txt", documentsDirectory];
        [NSKeyedArchiver archiveRootObject:userAlbum toFile:str];
    }
    
    if (friendsImages.count > 0){
        NSString *str = [NSString stringWithFormat:@"%@/friendsImagesRef.txt", documentsDirectory];
        [NSKeyedArchiver archiveRootObject:friendsImages toFile:str];
    }

    self.album = [NSMutableArray arrayWithArray:theAlbum];
    self.theTitle.text = self.albumTitle;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    self.pageCount = self.album.count;
    
    // Set up the array to hold the views for each page
    self.pageViews = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < self.pageCount; ++i) {
        [self.pageViews addObject:[NSNull null]];
    }
    
    NSInteger p = self.page;
    CGFloat w = self.scrollView.bounds.size.width;
    [self.scrollView setContentOffset:CGPointMake(p*w,0) animated:YES];
    
    // Set up the content size of the scroll view
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.pageCount, pagesScrollViewSize.height);
    
    // Load the initial set of pages that are on screen
    [self loadVisiblePages];
}

- (void)loadVisiblePages {
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    CGFloat pageWidth;
    NSInteger page;
    if (orientation == 3 || orientation == 4){ // portrait
        pageWidth = 480;
    }
    else{
        // First, determine which page is currently visible
        pageWidth = self.scrollView.frame.size.width;
    }
    // First, determine which page is currently visible
    page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    if (page < self.pageCount && page >= 0){
        // Keeps track of which image is showing, for passing to child view controller
        self.currentImage = [self.album objectAtIndex:page];

        self.title =[NSString stringWithFormat:@"%ld of %ld", (long)page+1, (long)self.pageCount];

        // Work out which pages we want to load
        NSInteger firstPage = page - 1;
        NSInteger lastPage = page + 1;
        
        // Purge anything before the first page
        for (NSInteger i=0; i<firstPage; i++) {
            [self purgePage:i];
        }
        for (NSInteger i=firstPage; i<=lastPage; i++) {
            [self loadPage:i];
        }
        for (NSInteger i=lastPage+1; i<self.pageCount; i++) {
            [self purgePage:i];
        }
    }
}

- (void)loadPage:(NSInteger)page {
    
    
    if (page < 0 || page >= self.pageCount) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Load an individual page, first seeing if we've already loaded it
    UIView *pageView = [self.pageViews objectAtIndex:page];
    // create an instance of imageView to be used as the newPageView
    UIImageView *newPageView;
    
    if ((NSNull*)pageView == [NSNull null]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
        UIImage *theImage = [self.album objectAtIndex:page];
        
        newPageView = [[UIImageView alloc] initWithImage:theImage];

        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        CGSize screenSize = [[UIScreen mainScreen] bounds].size;
        if (screenSize.height == 480){
            
            if (theImage.size.width == 600 || theImage.size.height == 800) {
                if (UIDeviceOrientationIsPortrait(orientation)){ // portrait
                    [newPageView setContentMode:UIViewContentModeScaleAspectFill];
                    newPageView.clipsToBounds = YES;
                }
                else{
                    newPageView.contentMode = UIViewContentModeScaleAspectFit;
                }
            }
        }
        else{
            newPageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    
        newPageView.frame = frame;
        [self.scrollView addSubview:newPageView];

        [self.pageViews replaceObjectAtIndex:page withObject:newPageView];
    }
}

- (void) didRotate:(NSNotification *)notification{ // user rotated their device
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];

    if (orientation == 1){ // portrait
        self.scrollView.transform = CGAffineTransformMakeRotation(0);
        [self setPortraitBounds];
    }
    if (orientation == 2){ // portrait upside down
        self.scrollView.transform = CGAffineTransformMakeRotation(M_PI);
        [self setPortraitBounds];
    }
    if (orientation == 3){ // landscape left
        self.scrollView.transform = CGAffineTransformMakeRotation(M_PI/2);
        [self setLandscapeBounds];
    }
    if (orientation == 4) { // landscape right
        self.scrollView.transform = CGAffineTransformMakeRotation(-M_PI/2);
        [self setLandscapeBounds];
    }
}

-(void)setLandscapeBounds{
    NSInteger current = [self.album indexOfObject:self.currentImage];
    [self purgePage:current];
    [self purgePage:current+1];
    [self purgePage:current-1];

    UIImageView *newPageView;
    self.scrollView.bounds = CGRectMake (0,0,480,320);
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = 0.0f;
    frame.origin.y = 0.0f;
    
    newPageView = [[UIImageView alloc] initWithImage:self.currentImage];
    newPageView.contentMode = UIViewContentModeScaleAspectFit;
    newPageView.frame = frame;
    [self.scrollView addSubview:newPageView];
    
    [self.pageViews replaceObjectAtIndex:current withObject:newPageView];

    // Set up the content size of the scroll view
    CGSize pagesScrollViewSize = newPageView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.pageCount, pagesScrollViewSize.width);
    
    [self loadPage:current+1];
    [self loadPage:current-1];
    
    UIImageView *before = [self.pageViews objectAtIndex:current];
    NSInteger w = before.frame.size.width;
    
    NSInteger x = current * w;
    
    [self.scrollView setContentOffset:CGPointMake(x,0) animated:NO];
    
    UIImageView *home = [self.pageViews objectAtIndex:current];
    home.frame = CGRectMake (x,0,480,320);
    
}

-(void)setPortraitBounds{
    NSInteger current = [self.album indexOfObject:self.currentImage];
    [self purgePage:current];
    [self purgePage:current+1];
    [self purgePage:current-1];
    
    UIImageView *newPageView;
    self.scrollView.bounds = CGRectMake (0,0,320,480);
    CGRect frame = self.scrollView.bounds;
    frame.origin.x = 0.0f;
    frame.origin.y = 0.0f;
    
    newPageView = [[UIImageView alloc] initWithImage:self.currentImage];
    
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 480){
        [newPageView setContentMode:UIViewContentModeScaleAspectFill];
        newPageView.clipsToBounds = YES;
    }
    else{
        newPageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    newPageView.frame = frame;
    [self.scrollView addSubview:newPageView];
    
    [self.pageViews replaceObjectAtIndex:current withObject:newPageView];
    
    // Set up the content size of the scroll view
    CGSize pagesScrollViewSize = newPageView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * self.pageCount, pagesScrollViewSize.height);
    
    [self loadPage:current+1];
    [self loadPage:current-1];

    UIImageView *before = [self.pageViews objectAtIndex:current];
    NSInteger w = before.frame.size.width;

    NSInteger x = current * w;
    
    [self.scrollView setContentOffset:CGPointMake(x,0) animated:NO];
    
    UIImageView *home = [self.pageViews objectAtIndex:current];
    home.frame = CGRectMake (x,0,320,480);
}

- (void)purgePage:(NSInteger)page {
    if (page < 0 || page >= self.pageCount) {
        // If it's outside the range of what we have to display, then do nothing
        return;
    }
    
    // Remove a page from the scroll view and reset the container array
    UIView *pageView = [self.pageViews objectAtIndex:page];
    if ((NSNull*)pageView != [NSNull null]) {
        [pageView removeFromSuperview];
        [self.pageViews replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)sender{

    if (sender.contentOffset.y != 0){ // this 'if' statement prevents vertical scrolling
        CGPoint offset = sender.contentOffset;
        offset.y = 0;
        sender.contentOffset = offset;
    }

    [self loadVisiblePages];
}

- (IBAction)editButton:(id)sender {
    [self performSegueWithIdentifier:@"showEditor" sender:self];
}

- (IBAction)backButton:(id)sender{
    [self performSegueWithIdentifier:@"showAlbum" sender:self];
}

- (void) prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{ // set the properties to be handed to the childVC
    
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications]; // turn rotation notifications off
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    if([segue.identifier isEqualToString:@"showEditor"]){ // user chose to edit the image
        DetailViewController *editView = (DetailViewController *)segue.destinationViewController;
        editView.albumCount = self.albumCount;
        editView.image = self.currentImage;
        editView.album = self.album;
        editView.albumTitle = self.albumTitle;
        editView.albumRef = self.albumRef;
        editView.objId = self.objId;
        editView.index = [self.album indexOfObject:self.currentImage];
        
    }else if([segue.identifier isEqualToString:@"showAlbum"]){ // user chose to return to the collection view
        CollectionViewController *albumView = (CollectionViewController *)segue.destinationViewController;
        albumView.album = self.album;
        albumView.title = self.albumTitle;
        albumView.albumRef = self.albumRef;
        albumView.objId = self.objId;
    }
}

- (void)handleLongPressGestures:(UILongPressGestureRecognizer *)paramSender{
    if ([paramSender isEqual:self.longPressGestureRecognizer]){
        if (paramSender.numberOfTouchesRequired == 1){
            if ([self.check isEqual:@"yes"]){
                return;
            }
            self.check = @"yes";
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@""
                                                        message:@"Save to your devices photo album?"
                                                       delegate:self
                                              cancelButtonTitle:@"Cancel"
                                              otherButtonTitles:@"YES",nil];
            [alert show];
        }
    }
}

- (void)handleTaps:(UITapGestureRecognizer*)paramSender{ // user tapped the screen
    if ([paramSender isEqual:self.tapGestureRecognizer]){ // check for tapGestureRecognizer
        if (paramSender.numberOfTapsRequired == 1){ // user tapped one time
            if (self.navigationController.navigationBar.hidden == YES){ // nav & status bars are hidden
                [[self navigationController] setNavigationBarHidden:NO animated:YES];
                [[UIApplication sharedApplication] setStatusBarHidden:NO];
            }else{ // nav & status bars are not hidden, so hide 'em
                [[self navigationController] setNavigationBarHidden:YES animated:YES];
                [[UIApplication sharedApplication] setStatusBarHidden:YES];
            }
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{ // user clicked a button on an alert
    if (buttonIndex == 1){ // user chose to save the image to their device
        UIImageWriteToSavedPhotosAlbum(self.currentImage, nil, nil, nil);
    }
    self.check = nil; // reset the check
}

@end
