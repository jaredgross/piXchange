//
//  CollectionViewController.m
//  Flashback
//
//  Created by Jared Gross on 10/11/13.
//  Copyright (c) 2013 piXchange, LLC. All rights reserved.
//

#import "CollectionViewController.h"
#import "PagedScrollViewController.h"
#import "Cell.h"
#import "MBProgressHUD.h"

#define DELETE_ALERT 1

@interface CollectionViewController (){
    BOOL    selectImages;
}
@property (nonatomic, strong) NSMutableIndexSet *indexSet;
@property (nonatomic, strong) NSMutableArray *images;

- (IBAction)backButton:(id)sender;
- (IBAction)deleteButton:(id)sender;

@end

@implementation CollectionViewController


#pragma mark - VIEW CONTROLLER LIFE CYCLE
- (void)viewDidLoad {
    [super viewDidLoad];
    
    // disables default pushToView segue swipe
    if ([self.navigationController respondsToSelector:@selector(interactivePopGestureRecognizer)]) {
        self.navigationController.interactivePopGestureRecognizer.enabled = NO;
    }
    
    self.navigationController.navigationItem.title = self.title;
    self.tabBarController.tabBar.hidden = YES;
    self.navigationController.navigationBar.hidden = NO;
    [self.navigationController.navigationBar setBarStyle:UIBarStyleDefault];
    self.navigationController.navigationBarHidden = NO;
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
    
    
    if ([self.albumRef isEqual:@"dropped"]){
        [self.navigationItem.rightBarButtonItem setTitle:@"Refresh"];
        [self.navigationItem.rightBarButtonItem setImage:nil];
    }
    else{
        [self.navigationItem.rightBarButtonItem setImage:[UIImage imageNamed:@"Trash.png"]];
    }

    
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSMutableArray *userAlbumsArray;
    if ([self.albumRef isEqual:@"cloud"]){
        NSString *str = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", documentsDirectory];
        userAlbumsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
    }
    else if ([self.albumRef isEqual:@"dropped"]) {
        NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSString *str1 = [NSString stringWithFormat:@"%@/releasedAlbums.txt", documentsDirectory];
        userAlbumsArray = [NSKeyedUnarchiver unarchiveObjectWithFile:str1];
    }
    
    NSMutableArray *albumData;
    // get the album array related to the objectID
    for (NSArray *array in userAlbumsArray){
        
        NSInteger i = [userAlbumsArray indexOfObject:array];
        if (array.count != 0){

            NSObject *obj1 = [array objectAtIndex:0];
            
            if ([[obj1 valueForKey:@"objID"] isEqual:self.objId]){
            
                albumData = [userAlbumsArray objectAtIndex:i];
                break;
            }
        }
    }
    
    NSMutableArray *theAlbum = [[NSMutableArray alloc]initWithCapacity:albumData.count];
    for(NSObject *obj in albumData){
        
        NSData *tempDat = [obj valueForKey:@"img"];
        
        [theAlbum addObject:tempDat];
    }
    
    self.album = theAlbum;

    self.albumCount = 0;
    for(NSData *obj in albumData){
        if([[obj valueForKey:@"userID"] isEqual:[[PFUser currentUser] objectId]]){
            self.albumCount++;
        }
    }
}

-(void)viewWillAppear:(BOOL)animated{
    [self.collectionView reloadData];
}

#pragma mark - COLLECTION VIEW - DATA SOURCE
- (NSInteger)collectionView:(UICollectionView *)view numberOfItemsInSection:(NSInteger)section; {
    return self.album.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath; {

    Cell *cell= [collectionView dequeueReusableCellWithReuseIdentifier:@"theCell" forIndexPath:indexPath];

    NSData *tempDat = [self.album objectAtIndex:indexPath.row];

    UIImage *theImage = [UIImage imageWithData:tempDat];

    cell.imageView.clipsToBounds = YES;
    cell.imageView.image = theImage;
    
    if ([self.indexSet containsIndex:indexPath.item]){
        cell.alpha = 0.1f;
    }
    else{
        cell.alpha = 1.0f;
    }
    
    return cell;
}



#pragma mark - COLLECTION VIEW - DELEGATE
- (void) collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    
    UICollectionViewCell *cell = [collectionView cellForItemAtIndexPath:indexPath];

    if (selectImages != YES){
        [self performSegueWithIdentifier:@"showPhoto" sender:self];
    }
    else{
        NSUInteger index = indexPath.item;
        if (cell.alpha == 0.1f){
            cell.alpha = 1.0f;
            [self.indexSet removeIndex:index];
        }
        else if ((cell.alpha == 1.0f)){
            cell.alpha = 0.1f;
            [self.indexSet addIndex:index];
        }
    }
}

#pragma mark - ACTIONS
- (IBAction)backButton:(id)sender {
    
    if ([self.albumRef isEqual:@"cloud"] || [self.albumRef isEqual:@"default"] || [self.albumRef isEqual:@"done"]){
        [self performSegueWithIdentifier:@"showCapsules" sender:self];
    }
    else{
        [self performSegueWithIdentifier:@"showTabBar1" sender:self];
    }
    NSString *documentsDirectory = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *name = [NSString stringWithFormat:@"%@/collViewThumbnails.txt", documentsDirectory];
    [NSKeyedArchiver archiveRootObject:nil toFile:name];
}

- (IBAction)deleteButton:(id)sender {
    
    if (self.indexSet.count > 0){
        UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"Really?"
                                                        message:@"Delete the selected images?"
                                                       delegate:self
                                              cancelButtonTitle: @"CANCEL"
                                              otherButtonTitles:@"YES",nil];
        [alert show];
    }
    else{
        if ([self.albumRef isEqual:@"dropped"]){
            [self queryParseForFriendsImages];
        }
        else if ([self.albumRef isEqual:@"cloud"]){
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"DELETE"
                                                            message:@"Entire Album or Select Images?"
                                                           delegate:self
                                                  cancelButtonTitle: @"CANCEL"
                                                  otherButtonTitles:@"Entire Album", @"Select Images",nil];
            alert.tag = DELETE_ALERT;
            [alert show];
        }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{

    if (alertView.tag == DELETE_ALERT){
        
        if (buttonIndex == 1){ // entire album
            selectImages = NO;
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Are you sure?"
                                                                message:@""
                                                               delegate:self
                                                      cancelButtonTitle:@"BACK"
                                                      otherButtonTitles:@"YES", nil];
            [alertView show];
        }
        else if (buttonIndex == 2){
            selectImages = YES;
            self.indexSet = [[NSMutableIndexSet alloc]init];
        }
    }
    
    else{ // "Are you sure?" alert
        if (buttonIndex == 1){ // YES tapped
                [self queryParse];
        }
        if (buttonIndex == 0){
            self.indexSet = nil;
            [self.collectionView reloadData];
        }
    }
}

-(void)queryParseForFriendsImages{
    
    NSLog (@"refreshing");
    NSMutableArray *albums = [[NSMutableArray alloc]init];
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;
    hud.labelText = @"Refreshing...";
    [hud show:YES];
    
    PFQuery *query = [PFQuery queryWithClassName:@"Images"];
    [query whereKey:@"parent" equalTo:self.objId];
    [query findObjectsInBackgroundWithBlock:^(NSArray *objects, NSError *error) {
        
        if(error){
            UIAlertView* alert = [[UIAlertView alloc] initWithTitle: @"error"
                                                            message:@"The server could not be reached. Please try again."
                                                           delegate:self
                                                  cancelButtonTitle: @"OK"
                                                  otherButtonTitles:nil];
            [alert show];
            [hud hide:YES];
        }
        else{
            if (objects.count == 0){
                [hud hide:YES];
            }
            else{
                for (NSObject *obj in objects){
                    PFFile *file = [obj valueForKey:@"content"];
                    if (file != nil){
                        [file getDataInBackgroundWithBlock:^(NSData *data, NSError *error) {
                            
                            NSMutableArray *images = nil;
                            images = [NSKeyedUnarchiver unarchiveObjectWithData:data];
                            NSArray *array = [images valueForKey:@"img"];
                            
                            if(error){
                                NSLog (@"error");
                                [self.collectionView reloadData];
                                [hud hide:YES];
                            }
                            else{
                                
                                if (array != nil){
                                    
                                    
                                    if (albums.count == 0) {
                                        [albums addObject:array];
                                    }
                                    else if (albums.count > 0){
                                        for (NSMutableArray *album in albums){
                                            if (album.count > 0){
                                                
                                                NSInteger count = album.count + array.count;
                                                NSInteger i = [albums indexOfObject:album];
                                                NSMutableArray *temp = [[NSMutableArray alloc]initWithCapacity:count];
                                                temp = [[NSMutableArray alloc] initWithArray:album];
                                                [temp addObjectsFromArray:array];
                                                [albums removeObjectAtIndex:i];
                                                [albums addObject:temp];
                                                
                                                break;
                                                
                                                //       }
                                            }
                                        }
                                    }
                                    else{
                                        [albums addObject:images];
                                    }
                                    
                                    self.album = [albums objectAtIndex:0];
                                    
                                    // set the new album to userDefaults
                                    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
                                    [NSUD setObject:self.album forKey:@"oldAlbumReference"];
                                    
                                    [self.collectionView reloadData];
                                    [hud hide:YES];
                                }
                            }
                        }];
                    }
                }
            }
        }
    }];
}

-(void)queryParse{
    
    MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
    hud.mode = MBProgressHUDModeIndeterminate;

    hud.labelText = @"Deleting album...";

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
            if (events == nil){
                return;
            }
            
            NSString *NSDD = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *objectID;
            NSArray *array;
            if ([self.albumRef isEqual:@"cloud"]){
                NSString *ids = [NSString stringWithFormat:@"%@/currentObjIDs.txt", NSDD];
                array = [NSKeyedUnarchiver unarchiveObjectWithFile:ids];
    
                NSInteger i = 0;
                for (NSString *str in array){
                    if ([str isEqual:self.objId]){
                        i = [array indexOfObject:str];
                        break;
                    }
                }
                objectID = [array objectAtIndex:i];
            }
            
            else if ([self.albumRef isEqual:@"dropped"]){
                NSString *str = [NSString stringWithFormat:@"%@/releasedUserObjIDs.txt", NSDD];
                array = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
                
                NSInteger i = 0;
                for (NSString *str in array){
                    if ([str isEqual:self.objId]){
                        i = [array indexOfObject:str];
                        break;
                    }
                }
                objectID = [array objectAtIndex:i];
            }
            
            PFQuery *query = [PFQuery queryWithClassName:@"Images"];
            [query getObjectInBackgroundWithId:objectID block:^(PFObject *object, NSError *error){
                
                if (error){
                    return;
                }
                else if (object == nil){
                    return;
                }

                if (selectImages == NO){
                    
                    [object deleteInBackground];
                    
                    // get a string reference to the current users ID to delete it from parse recipients array
                    NSString *IDref = [NSString stringWithFormat:@"%@", [[PFUser currentUser] objectId]];
                    NSMutableArray *idsArray  = [events objectForKey:@"recipientIds"];
                    
                    for (NSString *idREF in idsArray){
                        if ([idREF isEqual:IDref]){
                            [idsArray removeObject:idREF];
                            break;
                        }
                    }
                    
                    [events setObject:idsArray forKey:@"recipientIds"];
                    [events saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded == YES){
                            
                            [self updateUserDefaults];
                            [self saveToArchives];
                        }
                        else{
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                                message:@"Please try the action again."
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                            [alertView show];
                        }
                        
                        self.indexSet = nil;
                        [self performSegueWithIdentifier:@"showCapsules" sender:self];
                        [hud hide:YES];
                    }];
                }
                else if (selectImages == YES){
                    
                    [self.album removeObjectsAtIndexes:self.indexSet];
                    
                    NSMutableArray *images = [[NSMutableArray alloc]initWithCapacity:self.album.count];
                    for (NSData *imageData in self.album){
                        NSString *userID = [[PFUser currentUser] objectId];
                        NSDictionary *imageFile = @{
                                                    @"objID" : self.objId,
                                                    @"userID" : userID,
                                                    @"title" : self.title,
                                                    @"img" : imageData,  };
                        
                        [images addObject:imageFile];
                    }
                    self.images = images;
                    
                    NSData *imagesData = [NSKeyedArchiver archivedDataWithRootObject:images];
                    PFFile *file = [PFFile fileWithData:imagesData];
                    [object setObject:file forKey:@"content"];
                    [object saveInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
                        if (succeeded == YES){

                            [self saveToArchives];
                        }
                        else{
                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"An error occurred!"
                                                                                message:@"Please try the action again."
                                                                               delegate:self
                                                                      cancelButtonTitle:@"OK"
                                                                      otherButtonTitles:nil];
                            [alertView show];
                        }
    
                        [hud hide:YES];
                        selectImages = NO;
                        self.indexSet = nil;
                        [self.collectionView reloadData];
                    }];
                }
            }];
        }
    }];
}

-(void)saveToArchives{
    
    NSString *NSDD = [NSSearchPathForDirectoriesInDomains (NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *objectID;
    NSArray *array;
    if ([self.albumRef isEqual:@"cloud"]){
        
        if (selectImages == NO){
            NSString *ids = [NSString stringWithFormat:@"%@/currentObjIDs.txt", NSDD];
            array = [NSKeyedUnarchiver unarchiveObjectWithFile:ids];
            
            NSInteger i = 0;
            for (NSString *str in array){
                if ([str isEqual:self.objId]){
                    i = [array indexOfObject:str];
                    break;
                }
            }
            objectID = [array objectAtIndex:i];
            
            
            NSString *grp = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", NSDD];
            NSString *usr = [NSString stringWithFormat:@"%@/unreleasedGroupAlbums.txt", NSDD];
            
            NSArray *groupAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:grp];
            NSArray *userAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:usr];
            
            NSMutableArray *groupsMutable = [[NSMutableArray alloc]initWithArray:groupAlbums];
            NSMutableArray *userMutable = [[NSMutableArray alloc]initWithArray:userAlbums];
            NSMutableArray *eventIdsMutable = [[NSMutableArray alloc]initWithArray:array];
            
            [groupsMutable removeObjectAtIndex:i];
            [userMutable removeObjectAtIndex:i];
            [eventIdsMutable removeObjectAtIndex:i];
            
            [NSKeyedArchiver archiveRootObject:groupsMutable toFile:grp];
            [NSKeyedArchiver archiveRootObject:userMutable toFile:usr];
            [NSKeyedArchiver archiveRootObject:eventIdsMutable toFile:ids];

        }
        else if (selectImages == YES){
            NSString *ids = [NSString stringWithFormat:@"%@/currentObjIDs.txt", NSDD];
            array = [NSKeyedUnarchiver unarchiveObjectWithFile:ids];
            
            NSInteger i = 0;
            for (NSString *str in array){
                if ([str isEqual:self.objId]){
                    i = [array indexOfObject:str];
                    break;
                }
            }
            
            NSString *usr = [NSString stringWithFormat:@"%@/unreleasedUserAlbums.txt", NSDD];
            
            NSArray *userAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:usr];
            
            NSMutableArray *userMutable = [[NSMutableArray alloc]initWithArray:userAlbums];
            
            [userMutable replaceObjectAtIndex:i withObject:self.images];

            [NSKeyedArchiver archiveRootObject:userMutable toFile:usr];
        }
    }
    
    else if ([self.albumRef isEqual:@"dropped"]){
        NSString *str = [NSString stringWithFormat:@"%@/releasedUserObjIDs.txt", NSDD];
        array = [NSKeyedUnarchiver unarchiveObjectWithFile:str];
        
        NSInteger i = 0;
        for (NSString *str in array){
            if ([str isEqual:self.objId]){
                i = [array indexOfObject:str];
                break;
            }
        }
        objectID = [array objectAtIndex:i];
        
        
        NSString *grp = [NSString stringWithFormat:@"%@/releasedAlbums.txt", NSDD];
        
        NSArray *groupAlbums = [NSKeyedUnarchiver unarchiveObjectWithFile:grp];
        
        NSMutableArray *groupsMutable = [[NSMutableArray alloc]initWithArray:groupAlbums];
        NSMutableArray *eventIdsMutable = [[NSMutableArray alloc]initWithArray:array];
        
        [groupsMutable removeObjectAtIndex:i];
        [eventIdsMutable removeObjectAtIndex:i];
        
        [NSKeyedArchiver archiveRootObject:groupsMutable toFile:grp];
        [NSKeyedArchiver archiveRootObject:eventIdsMutable toFile:str];
    }
    self.images = nil;

}

-(void)updateUserDefaults{
    NSUserDefaults *NSUD = [NSUserDefaults standardUserDefaults];
    
    if ([self.albumRef isEqual:@"dropped"]){
        
        // get the data for the 'shared' event from userDefaults
        NSArray *a = [NSUD valueForKey:@"oldTitlesReference"];
        NSArray *b = [NSUD valueForKey:@"oldLocationsReference"];
        NSArray *c = [NSUD valueForKey:@"oldDatesReference"];
        NSArray *d = [NSUD valueForKey:@"oldIDsReference"];
        NSMutableArray *titles = [[NSMutableArray alloc]initWithArray:a];
        NSMutableArray *locations = [[NSMutableArray alloc]initWithArray:b];
        NSMutableArray *timers = [[NSMutableArray alloc]initWithArray:c];
        NSMutableArray *ids = [[NSMutableArray alloc]initWithArray:d];
        
        // remove the event info from the arrays
        NSInteger i = [ids indexOfObject:self.objId];
        [titles removeObjectAtIndex:i];
        [ids removeObjectAtIndex:i];
        [locations removeObjectAtIndex:i];
        [timers removeObjectAtIndex:i];
        
        if (ids.count == 0){ // no remaining events - set the userDefualts to 'nil'
            [NSUD setObject:nil forKey:@"oldLocationsReference"];
            [NSUD setObject:nil forKey:@"oldTitlesReference"];
            [NSUD setObject:nil forKey:@"oldDatesReference"];
            [NSUD setObject:nil forKey:@"oldIDsReference"];
        }
        else{ // set the userDefaults to reflect the modefied arrays
            [NSUD setObject:locations forKey:@"oldLocationsReference"];
            [NSUD setObject:titles forKey:@"oldTitlesReference"];
            [NSUD setObject:timers forKey:@"oldDatesReference"];
            [NSUD setObject:ids forKey:@"oldIDsReference"];
        }
    }
    else if ([self.albumRef isEqual:@"cloud"]){
        
        // get the data for the 'time capsule' event from userDefualts
        NSArray *a = [NSUD valueForKey:@"objectIDReference"];
        NSArray *b = [NSUD valueForKey:@"timerReference"];
        NSArray *c = [NSUD valueForKey:@"titlesReference"];
        NSMutableArray *ids = [[NSMutableArray alloc]initWithArray:a];
        NSMutableArray *timers = [[NSMutableArray alloc]initWithArray:b];
        NSMutableArray *titles = [[NSMutableArray alloc]initWithArray:c];
        
        // remove the event info from the arrays
        NSInteger i = [ids indexOfObject:self.objId];
        [titles removeObjectAtIndex:i];
        [ids removeObjectAtIndex:i];
        [timers removeObjectAtIndex:i];
        
        if (ids.count == 0){ // no remaining events - set the userDefualts to 'nil'
            [NSUD setObject:nil forKey:@"titlesReference"];
            [NSUD setObject:nil forKey:@"timerReference"];
            [NSUD setObject:nil forKey:@"objectIDReference"];
        }
        else{ // set the userDefaults to reflect the modefied arrays
            [NSUD setObject:titles forKey:@"titlesReference"];
            [NSUD setObject:timers forKey:@"timerReference"];
            [NSUD setObject:ids forKey:@"objectIDReference"];
        }
    }
    [NSUD synchronize];
}

#pragma mark - HELPERS
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
    
    if  ([segue.identifier isEqualToString:@"showPhoto"]) {
        
        PagedScrollViewController *photoView = (PagedScrollViewController *)segue.destinationViewController;

        NSIndexPath *selectedIndex = [self.collectionView indexPathsForSelectedItems][0];

        photoView.albumCount = self.albumCount;
        photoView.page = selectedIndex.row;
        photoView.albumTitle = self.title;
        photoView.albumRef = self.albumRef;
        photoView.objId = self.objId;
    }
    self.album = nil;
    self.title = nil;
    self.albumRef = nil;
    self.objId = nil;
}

@end
