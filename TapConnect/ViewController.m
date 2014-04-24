//
//  ViewController.m
//  TapConnect
//
//  Created by Donald Pae on 4/23/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "ViewController.h"
#import "DesignManager.h"

@interface ViewController ()

@property (strong, nonatomic) CLBeaconRegion *beaconRegion;
@property (strong, nonatomic) CLLocationManager *locationManager;

@end



@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    // title
    self.navigationItem.hidesBackButton = YES;
    self.navigationItem.title = [DesignManager getMainTitle];
    
    // settings button
    UIBarButtonItem *settingsButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"settingsicon"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsPressed:)];
    self.navigationItem.leftBarButtonItem = settingsButton;
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self initRegion];

}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:1.0 alpha:0.5];
    
    [self.locationManager startRangingBeaconsInRegion:self.beaconRegion];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)initRegion {
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"E2C56DB5-DFFB-48D2-B060-D0F5A71096E0"];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                           identifier:@"com.app.beaconRegion"];
    self.beaconRegion.notifyEntryStateOnDisplay = NO; //Used for Monitoring
    self.beaconRegion.notifyOnEntry = YES; //Used for Monitoring
    self.beaconRegion.notifyOnExit = YES; //Used for Monitoring
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
        
        //MyProfileController *vc = [[MyProfileController alloc] initWithAccount:self.currentAccount];
        //[self.navigationController pushViewController:vc animated:YES];
        
    }
    else if (buttonIndex == 1){
        // log out
        
       //self.currentAccount = nil;
       //AppDelegate* app = (AppDelegate*)[UIApplication sharedApplication].delegate;
       //[DataManager sharedInstance].fetchedContacts = NO;
       //[app logout];
        
        [self.navigationController popViewControllerAnimated:YES];
   }
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
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
}

-(void)locationManager:(CLLocationManager *)manager didRangeBeacons:(NSArray *)beacons inRegion:(CLBeaconRegion *)region {
    CLBeacon *beacon;// = [[CLBeacon alloc] init];
    beacon = [beacons lastObject];
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
}

@end
