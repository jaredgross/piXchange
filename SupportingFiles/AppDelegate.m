//
//  AppDelegate.m
//  Flashback
//
//  Created by Jared Gross on 8/25/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "AppDelegate.h"
#import <Parse/Parse.h>
#import "FriendsViewController.h"
#import "ActiveViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [Parse setApplicationId:@"u8JIlhzv9wBnQKML5T60UzcM5GV9bzj3YwIbHuCJ"
                  clientKey:@"oTNNuBCYtnfB7BlxYkwBax36syLu0q8kTjjrRiRo"];
    [PFAnalytics trackAppOpenedWithLaunchOptions:launchOptions];

    NSString *NSDD = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *AR = [NSString stringWithFormat:@"%@/albRef.txt", NSDD];
    [NSKeyedArchiver archiveRootObject:nil toFile:AR];

    NSString* eventID = nil;
    
    if(launchOptions) // the user opened the App via Push notification
    {   // get the eventID from Parse notification key
        NSDictionary *notificationPayload = launchOptions[UIApplicationLaunchOptionsRemoteNotificationKey];
        eventID = notificationPayload[@"eventID"];
        NSLog(@"Push notification received for event: %@", eventID);
        
        // stash the eventID
        NSString *ID = [NSString stringWithFormat:@"%@/eventID.txt", NSDD];
        [NSKeyedArchiver archiveRootObject:eventID toFile:ID];
        NSLog(@"eventID %@ archived", eventID);
        
        NSString *AR = [NSString stringWithFormat:@"%@/albRef.txt", NSDD];
        [NSKeyedArchiver archiveRootObject:@"invite" toFile:AR];
    }

    
    // set the homeViewController as the default rootViewController
    UITabBarController *tabBarController = (UITabBarController*)self.window.rootViewController;
    [tabBarController setSelectedIndex:3];
    
    // register the app to recieve remote notifications
    [application registerForRemoteNotificationTypes:
     UIRemoteNotificationTypeBadge |
     UIRemoteNotificationTypeAlert |
     UIRemoteNotificationTypeSound];

    return YES;
}

- (void)application:(UIApplication *)application
didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)newDeviceToken {

    // check to see if there is a valid PFUser before installing device token
    if ([PFUser currentUser] == nil){
    }
    else
    {
        // Store the deviceToken in the current installation and save it to Parse.
        PFInstallation *currentInstallation = [PFInstallation currentInstallation];
        [currentInstallation setDeviceTokenFromData:newDeviceToken];
        [currentInstallation saveInBackground];
        currentInstallation[@"user"] = [PFUser currentUser];
    
        [currentInstallation saveInBackground];
    }
}

-(void) application:(UIApplication*) application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
    NSLog(@"Failed to register for Remote notifications: %@", error);
}

- (void)application:(UIApplication *)application
didReceiveRemoteNotification:(NSDictionary *)userInfo {
    [PFPush handlePush:userInfo];
    
    NSString* eventID = userInfo[@"eventID"];
    
    //This gets called when the app loads from a Push where:
    //1. the app is in the background and not terminated
    //2. the app is in the foreground
    
    // stash the eventID
    NSString *NSDD = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *ID = [NSString stringWithFormat:@"%@/eventID.txt", NSDD];
    NSString *AR = [NSString stringWithFormat:@"%@/albRef.txt", NSDD];
    [NSKeyedArchiver archiveRootObject:@"invite" toFile:AR];
    [NSKeyedArchiver archiveRootObject:eventID toFile:ID];
    NSLog(@"eventID %@ archived", eventID);

    NSLog(@"Push notification received for event: %@", eventID);
    ActiveViewController *avc = [[ActiveViewController alloc] init];
    [avc refresh];
}

- (void)applicationDidFinishLaunching:(UIApplication *)application {}

- (void)applicationWillResignActive:(UIApplication *)application {}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    
}

- (void)applicationWillEnterForeground:(UIApplication *)application {}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [[userContactsList getInstance] refreshContactsList];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    NSString *NSDD = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *str = [NSString stringWithFormat:@"%@/eventID.txt", NSDD];
    NSString *str1 = [NSString stringWithFormat:@"%@/releasedAlbums.txt", NSDD];
    NSString *str2 = [NSString stringWithFormat:@"%@/activeUserAlbums.txt", NSDD];
    NSString *str3 = [NSString stringWithFormat:@"%@/activeGroupAlbums.txt", NSDD];
    NSString *str4 = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", NSDD];
    NSString *str5 = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", NSDD];
    NSString *str6 = [NSString stringWithFormat:@"%@/collViewThumbnails.txt", NSDD];
    [NSKeyedArchiver archiveRootObject:nil toFile:str];
    [NSKeyedArchiver archiveRootObject:nil toFile:str1];
    [NSKeyedArchiver archiveRootObject:nil toFile:str2];
    [NSKeyedArchiver archiveRootObject:nil toFile:str3];
    [NSKeyedArchiver archiveRootObject:nil toFile:str4];
    [NSKeyedArchiver archiveRootObject:nil toFile:str5];
    [NSKeyedArchiver archiveRootObject:nil toFile:str6];
    
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];

    [NSUD setObject:nil forKey:@"albumReference"];
    [NSUD setObject:nil forKey:@"objectIDReference"];
    [NSUD setObject:nil forKey:@"timerReference"];
    [NSUD setObject:nil forKey:@"titlesReference"];
    [NSUD setObject:nil forKey:@"allImagesReference"];
    [NSUD setObject:nil forKey:@"oldTitlesReference"];
    [NSUD setObject:nil forKey:@"oldIDsReference"];
    
    [NSUD setObject:nil forKey:@"defaults"];
    
    [NSUD setObject:nil forKey:@"activeAlbums"];
    [NSUD setObject:nil forKey:@"activeDeadlines"];
    [NSUD setObject:nil forKey:@"activeTitles"];
    [NSUD setObject:nil forKey:@"activeEventIDs"];
    [NSUD setObject:nil forKey:@"activeGroupImagesReference"];
    
    [NSUD synchronize];

}

@end
