//
//  ViewController.m
//  TapConnect
//
//  Created by Donald Pae on 4/23/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "ViewController.h"
#import "DesignManager.h"
#import <Parse/Parse.h>
#import "LoginViewController.h"
#import "User.h"
#import "Common.h"

#import "GAIDictionaryBuilder.h"


#define kDuplicateInterval      3

#define ENABLE_RECORDING_OUT    0
#define ENABLE_RECORDING_MOVE   0
#define ENTER_WHEN_NEAR         1

#define kAnimTimeInterval   1


@interface ViewController () {
    NSDate *enterTime;
    NSDate *exitTime;
    
    int currMajor;
    int currMinor;
    
    NSTimer *animTimer;
    int animIndex;
    NSMutableArray *bluetoothIcons;
}

@property (retain, nonatomic) CLBeaconRegion *beaconRegion;
@property (retain, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, readwrite) BOOL isBluetoothOn;
@property (nonatomic, retain) IBOutlet UIImageView *imgviewAlertBg;
@property (nonatomic, retain) IBOutlet UIImageView *imgviewBluetoothIcon;

@property (nonatomic, retain) IBOutlet UILabel *lblStatus;

@end



@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // title
    self.navigationItem.hidesBackButton = YES;
    
    
    // settings button
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsicon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)];
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    
    enterTime = nil;
    exitTime = nil;
    
    currMajor = -1;
    currMinor = -1;
    
    
    
    // load images
    UIImage *image = [UIImage imageNamed:@"bluetoothicon"];
    
    bluetoothIcons = [[NSMutableArray alloc] init];
    UIImage *image1 = [UIImage imageNamed:@"bluetoothicon1"];
    UIImage *image2 = [UIImage imageNamed:@"bluetoothicon2"];
    UIImage *image3 = [UIImage imageNamed:@"bluetoothicon3"];
    UIImage *image4 = [UIImage imageNamed:@"bluetoothicon4"];
    
    [bluetoothIcons addObject:image];
    [bluetoothIcons addObject:image1];
    [bluetoothIcons addObject:image2];
    [bluetoothIcons addObject:image3];
    [bluetoothIcons addObject:image4];
    
    NSLog(@"main view opened - view did load");
    
    animIndex = 0;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self initRegion];
    
    self.isBluetoothOn = YES;
    [self refreshBluetoothStatus];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationItem.title = [DesignManager getMainTitle];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    animTimer = [NSTimer scheduledTimerWithTimeInterval:kAnimTimeInterval target:self selector:@selector(timerProc:) userInfo:nil repeats:YES];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [animTimer invalidate];
    animTimer = nil;
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initRegion {

    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                           identifier:@"com.app.BeaconRegion"];
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
    
    NSLog(@"init region");
}


#pragma mark Actions

- (IBAction)settingsPressed:(id)sender
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil
                                                             delegate:self
                                                    cancelButtonTitle:@"Cancel"
                                               destructiveButtonTitle:nil
                                                    otherButtonTitles:
                                  @"Your Profile",
                                  @"Logout",
                                  nil];
    [actionSheet setTintColor:[UIColor darkGrayColor]];
    
    [actionSheet showFromBarButtonItem:sender animated:YES];
}

#pragma mark - Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0) {
        // profile page
        
        [self performSegueWithIdentifier:@"toprofile" sender:self];
       
    }
    else if (buttonIndex == 1){
        // log out
        
       //self.currentAccount = nil;
       //AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
       //[DataManager sharedInstance].fetchedContacts = NO;
       //[app logout];
        [self performSelectorOnMainThread:@selector(logOut) withObject:nil waitUntilDone:NO];
   }
}

- (void)logOut
{
    [PFUser logOut];
    
    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
        
        NSLog(@"logout - close facebook session!");
    }
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    [self.locationManager stopMonitoringForRegion:self.beaconRegion];
    
    [self.loginController reset];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
}

- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    for (UIView *subview in actionSheet.subviews) {
        if ([subview isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton *)subview;
            [button setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor darkTextColor] forState:UIControlStateHighlighted];
        }
    }
}

#pragma mark - Location Manager delegate
- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    //self.lblStatus.text = @"user entered in a range of beacon";
    
    NSLog(@"didEnterRegion -- ");
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    //self.lblStatus.text = @"user exited in a range of beacon";
    
    NSLog(@"didExitRegion ---");

}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    
#ifdef USE_TRY
    @try {
#endif
        CLBeacon *beacon;// = [[CLBeacon alloc] init];
        beacon = [beacons firstObject];//[[beacons firstObject] copy];
        
        if (beacons == nil || [beacons count] == 0 || beacon == nil)
        {
            if (beacons == nil)
                NSLog(@"beacons = nil");
            else if ([beacons count] == 0)
                NSLog(@"beacons count = 0");
            else
                NSLog(@"beacon = nil");
        }
        else
        {
            CLProximity beaconProximity = beacon.proximity;
            NSString *beaconUUID = [NSString stringWithFormat:@"%@", beacon.proximityUUID.UUIDString];
            int beaconMajor = [beacon.major intValue];
            int beaconMinor = [beacon.minor intValue];
            
#if ENTER_WHEN_NEAR
            if (beaconProximity == CLProximityUnknown || beaconProximity == CLProximityFar || beaconProximity == CLProximityNear)
#else
                if (beaconProximity == CLProximityUnknown)
#endif
                {
                    NSLog(@"out of range : %d", (int)beaconProximity);
                    
                    animIndex = 0;
                    
                    if (currMajor != -1 && currMinor != -1)
                    {
                        // ------ duplicate checking -----------
                        NSDate *currDate = [NSDate date];
                        
                        BOOL isDuplicated = YES;
                        if (exitTime == nil)
                            isDuplicated = NO;
                        else
                        {
                            NSTimeInterval secs = [currDate timeIntervalSinceDate:exitTime];
                            if (secs < kDuplicateInterval)
                                isDuplicated = YES;
                            else
                                isDuplicated = NO;
                        }
                        exitTime = currDate;
                        
#if ENABLE_RECORDING_OUT
                        User *user = [User currentUser];
                        if (user)
                        {
                            PFObject *event = [PFObject objectWithClassName:@"Events"];
                            event[@"email"] = user.email;
                            event[@"type"] = @"out of range";
                            event[@"uuid"] = beaconUUID;
                            event[@"major"] = [NSString stringWithFormat:@"%d", currMajor];
                            event[@"minior"] = [NSString stringWithFormat:@"%d", currMinor];
                            event[@"localtime"] = [Common date2str:[NSDate date] withFormat:DATETIME_FORMAT];
                            [event saveInBackground];
                        }
                        else
                            NSLog(@"out event not recorded since user is null");
#endif
                        
                        currMajor = currMinor = -1;
                        
                        self.lblStatus.text = @"user exited in a range of beacon";
                        
                        NSLog(@"exited -------------------- \n");
                    }
                    
                }
                else
                {
                    animIndex = (animIndex + 1) % [bluetoothIcons count];
                    
                    if (currMajor != beaconMajor || currMinor != beaconMinor) {
                        
                        NSLog(@"user enterend %d, %d", beaconMajor, beaconMinor);
                        
                        // ------ duplicate checking -----------
                        NSDate *currDate = [NSDate date];
                        
                        BOOL isDuplicated = YES;
                        if (enterTime == nil)
                            isDuplicated = NO;
                        else
                        {
                            NSTimeInterval secs = [currDate timeIntervalSinceDate:enterTime];
                            if (secs < kDuplicateInterval)
                                isDuplicated = YES;
                            else
                                isDuplicated = NO;
                        }
                        enterTime = currDate;
                        
                        // --------
                        User *user = [User currentUser];
                        
                        if (user && !isDuplicated)
                        {
                            PFObject *event = [PFObject objectWithClassName:@"Events"];
                            event[@"email"] = user.email;
                            BOOL isEnter = NO;
                            if (currMajor == -1 && currMinor == -1)
                            {
                                event[@"type"] = @"enter into range";
                                isEnter = YES;
                            }
                            else
                            {
                                event[@"type"] = @"move in range";
                                isEnter = NO;
                            }
                            event[@"uuid"] = beaconUUID;
                            event[@"major"] = [NSString stringWithFormat:@"%d", beaconMajor];
                            event[@"minior"] = [NSString stringWithFormat:@"%d", beaconMinor];
                            event[@"localtime"] = [Common date2str:[NSDate date] withFormat:DATETIME_FORMAT];
                            if (isEnter == NO)
                            {
#if ENABLE_RECORDING_MOVE
                                [event saveInBackground];
#endif
                            }
                            else
                            {
                                [event saveInBackground];
                            }
                        }
                        else
                        {
                            if (user == nil)
                                NSLog(@"enter or move event not recorded since user is null");
                            else
                                NSLog(@"enter or move event not recorded since it is duplicated");
                        }
                        
                        currMajor = beaconMajor;
                        currMinor = beaconMinor;
                        
                        self.lblStatus.text = @"user entered in a range of beacon";
                    }
                }
        }
        
        
        /*
         self.beaconFoundLabel.text = @"Yes";
         self.proximityUUIDLabel.text = beacon.proximityUUID.UUIDString;
         self.majorLabel.text = [NSString stringWithFormat:@"%@", beacon.major];
         self.minorLabel.text = [NSString stringWithFormat:@"%@", beacon.minor];
         self.accuracyLabel.text = [NSString stringWithFormat:@"%f", beacon.accuracy];
         if (beacon.proximity == CLProximityUnknown) {
         self.distanceLabel.text = @"Unknown Proximity";
         } else if (beacon.proximity == CLProximityImmediate) {
         self.distanceLabel.text = @"Immediate";
         } else if (beacon.proximity == CLProximityNear) {
         self.distanceLabel.text = @"Near";
         } else if (beacon.proximity == CLProximityFar) {
         self.distanceLabel.text = @"Far";
         }
         self.rssiLabel.text = [NSString stringWithFormat:@"%i", beacon.rssi];
         */
        
#ifdef USE_TRY
    }
    @catch (NSException *exception) {
        // May return nil if a tracker has not already been initialized with a
        // property ID.
        id tracker = [[GAI sharedInstance] defaultTracker];

        [tracker send:[[GAIDictionaryBuilder createExceptionWithDescription:[NSString stringWithFormat:@"exception %@:%@", exception.name, exception.reason] withFatal:[NSNumber numberWithBool:NO]] build]];  // isFatal (required). NO indicates non-fatal exception.
    }
    @finally {
        //
    }
#endif
    
}

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLRegion *)region {
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
    NSLog(@"didStartMonitoringForRegion -- ");
}

#pragma mark - show/hide bluetooth status
- (void)refreshBluetoothStatus
{
    self.imgviewAlertBg.hidden = self.isBluetoothOn;
    self.imgviewBluetoothIcon.hidden = !self.isBluetoothOn;
}

#pragma mark - Timer Proc
- (void)timerProc: (NSTimer *)timer
{
    [self.imgviewBluetoothIcon setImage:[bluetoothIcons objectAtIndex:animIndex]];
}


@end
