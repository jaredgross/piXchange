//
//  ScratchPadViewController.m
//  Flashback
//
//  Created by Jared Gross on 11/8/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "ScratchPadViewController.h"
#import "DAScratchPadView.h"
#import <QuartzCore/QuartzCore.h>
#import "DetailViewController.h"

@interface ScratchPadViewController ()
@property (unsafe_unretained, nonatomic) IBOutlet DAScratchPadView *scratchPad;
@property (unsafe_unretained, nonatomic) IBOutlet UISlider *airbrushFlowSlider;
@property (strong, nonatomic) IBOutlet UISlider *opacitySlider;
@property (strong, nonatomic) IBOutlet UISlider *widthSlider;
@property (strong, nonatomic) IBOutlet UIButton *paintBrush;
@property (strong, nonatomic) IBOutlet UIButton *airBrush;
@property (strong, nonatomic) IBOutlet UILabel *flowLabel;
@property (strong, nonatomic) IBOutlet UIButton *button;
@property (nonatomic) IBOutlet UIView *scratchpadOverlay;
- (IBAction)setColor:(id)sender;
- (IBAction)setWidth:(id)sender;
- (IBAction)setOpacity:(id)sender;
- (IBAction)clear:(id)sender;
- (IBAction)paint:(id)sender;
- (IBAction)airbrush:(id)sender;
- (IBAction)airbrushFlow:(id)sender;
- (IBAction)doneButton:(id)sender;

@end
@implementation ScratchPadViewController

- (void)viewDidLoad
{   [super viewDidLoad];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    // selects the initial tool as 'paintbrush'
    [self.paintBrush setImage:[UIImage imageNamed:@"paintbrushSelected"] forState:UIControlStateNormal];
    
    // Device's screen size
    CGSize screenSize = [[UIScreen mainScreen] bounds].size;
    if (screenSize.height == 480){
        [[NSBundle mainBundle] loadNibNamed:@"scratchpad_i4" owner:self options:nil];
        
        if (self.image.size.width == 600 || self.image.size.height == 800) {
            [self.scratchPad setContentMode:UIViewContentModeScaleAspectFill];
            self.scratchPad.clipsToBounds = YES;
        }
    }
    else{
        [[NSBundle mainBundle] loadNibNamed:@"scratchpad_i5" owner:self options:nil];
        [self.scratchPad setContentMode:UIViewContentModeScaleAspectFit];
    }
    self.view = self.scratchpadOverlay;
    
    // Get the image (passed from detailVC) for the sketch
    [self.scratchPad setSketch:self.image];

    
    if (self.image.size.height == 600){
        self.scratchPad.transform = CGAffineTransformMakeRotation(-M_PI/2);
        self.scratchPad.bounds = CGRectMake (0,0,480,320);
    }
}


#pragma mark - BUTTONS!!
// Toggles paintbrush for airbrush
- (IBAction)paint:(id)sender
{
    if (self.scratchPad.toolType == DAScratchPadToolTypeAirBrush){
        self.scratchPad.toolType = DAScratchPadToolTypePaint;
        
        self.airbrushFlowSlider.hidden = YES;
        self.flowLabel.hidden = YES;
        self.airBrush.hidden = NO;
        [self.airBrush setImage:[UIImage imageNamed:@"Airbrush-icon"] forState:UIControlStateNormal];
        [self.paintBrush setImage:[UIImage imageNamed:@"paintbrushSelected"] forState:UIControlStateNormal];
    }
}

// Toggles airbrush for paintbrush
- (IBAction)airbrush:(id)sender
{
    if (self.scratchPad.toolType == DAScratchPadToolTypePaint){
        self.scratchPad.toolType = DAScratchPadToolTypeAirBrush;
        
        self.flowLabel.hidden = NO;
        self.paintBrush.hidden = NO;
        self.airbrushFlowSlider.hidden = NO;
        [self.paintBrush setImage:[UIImage imageNamed:@"paintbrush"] forState:UIControlStateNormal];
        [self.airBrush setImage:[UIImage imageNamed:@"airbrushSelected"] forState:UIControlStateNormal];
    }
}

// User Chose to leave
- (IBAction)doneButton:(id)sender{
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *scratchImage = [NSString stringWithFormat:@"%@/scratchImage.txt", documentsDirectory];
    [NSKeyedArchiver archiveRootObject:self.scratchPad.getSketch toFile:scratchImage];
    
    [self dismissViewControllerAnimated:NO completion:NULL];

    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

// Returns the sketch to its original state
- (IBAction)clear:(id)sender{
	[self.scratchPad setSketch:self.image];
}


- (IBAction)setColor:(id)sender{   // Attatch buttons with different background colors to get more colors!!
    self.button.alpha = 1.0f;
	self.button = (UIButton*)sender;
    self.button.alpha = .2f;
	self.scratchPad.drawColor = self.button.backgroundColor;
}

- (IBAction)setWidth:(id)sender{   // sets width to slider value
	UISlider* slider = (UISlider*)sender;
	self.scratchPad.drawWidth = slider.value;
}

- (IBAction)setOpacity:(id)sender{   // sets opaacity to slider value
	UISlider* slider = (UISlider*)sender;
	self.scratchPad.drawOpacity = slider.value;
}

- (IBAction)airbrushFlow:(id)sender{   // Sets flow to slider value
	UISlider* slider = (UISlider*)sender;
	self.scratchPad.airBrushFlow = slider.value;
}

@end

