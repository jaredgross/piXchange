//
//  FadeSegue.m
//  Flashback
//
//  Created by Jared Gross on 9/15/13.
//  Copyright (c) 2013 Flashback Studios. All rights reserved.
//

#import "FadeSegue.h"
#import "QuartzCore/QuartzCore.h"

@implementation FadeSegue

-(void)perform {
    
    UIViewController *sourceViewController = (UIViewController*)[self sourceViewController];
    UIViewController *destinationController = (UIViewController*)[self destinationViewController];
    
    CATransition* transition = [CATransition animation];
    transition.duration = .25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionFade;
    
    [sourceViewController.navigationController.view.layer addAnimation:transition
                                                                forKey:kCATransition];
    
    [sourceViewController.navigationController pushViewController:destinationController animated:NO];
    
}

@end
