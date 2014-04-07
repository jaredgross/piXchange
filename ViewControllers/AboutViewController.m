//
//  AboutViewController.m
//  piXchange
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 Kickin' Appz. All rights reserved.
//

#import "AboutViewController.h"
#import "HomeViewController.h"

@interface AboutViewController ()

@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) IBOutlet UIImageView *imageView;
@property (nonatomic, strong) IBOutlet UIView *scrollerOverlay;

- (IBAction)toggleOptions:(id)sender;
- (IBAction)showEmail:(id)sender;

@end

@implementation AboutViewController 


-(void)viewDidLoad{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    // disables pushToView segue swipe
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    [[NSBundle mainBundle] loadNibNamed:@"aboutScroller" owner:self options:nil];
    self.view = self.scrollerOverlay;

    self.imageView.image = [UIImage imageNamed:@"scroller.png"];
    
    CGSize newSize = CGSizeMake(320, 2600);
    self.scrollView.contentSize = newSize;
}


- (void) mailComposeController:(MFMailComposeViewController *)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError *)error {
    switch (result)
    {
        case MFMailComposeResultCancelled:
            NSLog(@"Mail cancelled");
            break;
        case MFMailComposeResultSaved:
            NSLog(@"Mail saved");
            break;
        case MFMailComposeResultSent:
            NSLog(@"Mail sent");
            break;
        case MFMailComposeResultFailed:
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            break;
        default:
            break;
    }
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)toggleOptions:(id)sender {

    [self performSegueWithIdentifier:@"active" sender:self];
}

- (IBAction)showEmail:(id)sender{
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    
    NSArray *recipents = [NSArray arrayWithObject:@"support@piXchange.com"];
    [mc setToRecipients:recipents];

    [self presentViewController:mc animated:YES completion:NULL];
}

@end
