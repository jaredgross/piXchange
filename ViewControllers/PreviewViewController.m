//
//  PreviewViewController.m
//  Flashback
//
//  Created by Jared Gross on 12/9/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "PreviewViewController.h"
#import "FriendsViewController.h"

@interface PreviewViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic) UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, weak) IBOutlet UIView *previewOverlay;
- (IBAction)trashButton:(id)sender;
- (IBAction)backButton:(id)sender;

@end

@implementation PreviewViewController


- (void)viewDidLoad{
    
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[self navigationController] setNavigationBarHidden:NO animated:YES];
    
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 480){
        [[NSBundle mainBundle] loadNibNamed:@"preview_i4" owner:self options:nil];
    }
    else{
        [[NSBundle mainBundle] loadNibNamed:@"preview_i5" owner:self options:nil];
    }
    self.view = self.previewOverlay;

    self.imageView.clipsToBounds = YES;
    self.imageView.image = self.image;

    self.tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self
                                                                  action:@selector(handleTaps:)];
    self.tapGestureRecognizer.numberOfTouchesRequired = 1;
    self.tapGestureRecognizer.numberOfTapsRequired = 1;
    [self.view addGestureRecognizer:self.tapGestureRecognizer];

    if (self.image.size.height == 600) // image is in landscape mode
    {
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.imageView.clipsToBounds = NO;
        
        // Set Notifications so that when user rotates phone the image will fit the screen
        [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
        
        // Refer to the method didRotate:
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRotate:)
                                                     name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    }
}

- (IBAction)trashButton:(id)sender
{
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"Delete this photo"
                                                    message:@"Are you sure?"
                                                   delegate:self
                                          cancelButtonTitle:@"NO"
                                          otherButtonTitles:@"YES", nil];
    [alert show];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 1){ // user confirmed the delete - delete the image
        [self.album removeLastObject];
        [self performSegueWithIdentifier:@"showCamera" sender:self];
        
        if (self.album.count == 0){
            NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *str = [NSString stringWithFormat:@"%@/albumData.txt", documentsDirectory];
            [NSKeyedArchiver archiveRootObject:nil toFile:str];
        }
        
        NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
        [ud setObject:self.album forKey:@"album"];
        [ud synchronize];
    }
}

- (void) didRotate:(NSNotification *)notification // user rotated the device
{
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (orientation == 1){ // portrait
        self.imageView.transform = CGAffineTransformMakeRotation(0);
        self.imageView.bounds = CGRectMake (0,0,320,480);
        [[self navigationController] setNavigationBarHidden:NO animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.imageView.clipsToBounds = NO;
    }
    if (orientation == 2){ // portrait upside down
        self.imageView.transform = CGAffineTransformMakeRotation(M_PI);
        self.imageView.bounds = CGRectMake (0,0,320,480);
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFit];
        self.imageView.clipsToBounds = NO;
    }
    if (orientation == 3){ // landscape left
        self.imageView.transform = CGAffineTransformMakeRotation(M_PI/2);
        self.imageView.bounds = CGRectMake (0,0,480,320);
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        self.imageView.clipsToBounds = YES;
    }
    if (orientation == 4) { // landscape right
        self.imageView.transform = CGAffineTransformMakeRotation(-M_PI/2);
        self.imageView.bounds = CGRectMake (0,0,480,320);
        [[self navigationController] setNavigationBarHidden:YES animated:YES];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        [self.imageView setContentMode:UIViewContentModeScaleAspectFill];
        self.imageView.clipsToBounds = YES;
    }
}

- (IBAction)backButton:(id)sender
{
    [self performSegueWithIdentifier:@"showCamera" sender:self];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if  ([segue.identifier isEqualToString:@"showCamera"]) {

        FriendsViewController *cv = (FriendsViewController *)segue.destinationViewController;
        cv.album = self.album;
        cv.albumRef = self.albumRef;
        cv.objId = self.objID;
        cv.startDate = self.startDate;
        cv.theTitle = self.title;
    }
    
    self.navigationController.navigationBar.Hidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    
    // turn rotation notifications off
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                              name:@"UIDeviceOrientationDidChangeNotification" object:nil];
}


- (void)handleTaps:(UITapGestureRecognizer*)paramSender
{
    if ([paramSender isEqual:self.tapGestureRecognizer])
    {
        if (paramSender.numberOfTapsRequired == 1)
        {
            if (self.navigationController.navigationBar.hidden == YES)
            {
                [[self navigationController] setNavigationBarHidden:NO animated:YES];
                    [[UIApplication sharedApplication] setStatusBarHidden:NO];
            }
            else
            {
                [[self navigationController] setNavigationBarHidden:YES animated:YES];
                    [[UIApplication sharedApplication] setStatusBarHidden:YES];
            }
        }
    }
}

@end
