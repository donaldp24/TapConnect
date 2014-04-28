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

@interface ViewController ()

@property (retain, nonatomic) CLBeaconRegion *beaconRegion;
@property (retain, nonatomic) CLLocationManager *locationManager;
@property (nonatomic, retain) CBCentralManager *bluetoothCentralManager;
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
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    [self initRegion];
    
    //self.bluetoothCentralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
    
    self.isBluetoothOn = NO;
    [self refreshBluetoothStatus];
}

- (void)dealloc
{
    // self.bluetoothCentralManager.delegate = nil;
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
    NSUUID *uuid = [[NSUUID alloc] initWithUUIDString:@"B9407F30-F5F8-466E-AFF9-25556B57FE6D"];
    self.beaconRegion = [[CLBeaconRegion alloc] initWithProximityUUID:uuid
                                                           identifier:@"com.app.beaconRegion"];
    self.beaconRegion.notifyEntryStateOnDisplay = NO; //Used for Monitoring
    self.beaconRegion.notifyOnEntry = YES; //Used for Monitoring
    self.beaconRegion.notifyOnExit = YES; //Used for Monitoring
    
    [self.locationManager startMonitoringForRegion:self.beaconRegion];
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
    }
    
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

    User *user = [User currentUser];
    
    self.lblStatus.text = @"close with a beacon";
    if (user)
    {
        PFObject *event = [PFObject objectWithClassName:@"Events"];
        event[@"email"] = user.email;
        event[@"type"] = @"in";
        event[@"localtime"] = [Common date2str:[NSDate date] withFormat:DATETIME_FORMAT];
        [event saveInBackground];
    }
}

-(void)locationManager:(CLLocationManager *)manager didExitRegion:(CLRegion *)region {
    [self.locationManager stopRangingBeaconsInRegion:self.beaconRegion];
    
    User *user = [User currentUser];
    
    self.lblStatus.text = @"out of range of beacon";
    if (user)
    {
        PFObject *event = [PFObject objectWithClassName:@"Events"];
        event[@"email"] = user.email;
        event[@"type"] = @"out";
        event[@"localtime"] = [Common date2str:[NSDate date] withFormat:DATETIME_FORMAT];
        [event saveInBackground];
    }
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

#pragma mark - Bluetooth

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    
    NSString *stateDescription = nil;
    NSString *stateAlert = nil;
    self.isBluetoothOn = NO;
    switch ([central state]) {
        case CBCentralManagerStateResetting:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateResetting %d ", central.state];
            break;
        case CBCentralManagerStateUnsupported:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateUnsupported %d ", central.state];
            stateAlert = @"This device does not support Bluetooth low energy.";
            break;
        case CBCentralManagerStateUnauthorized:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateUnauthorized %d ", central.state];
            stateAlert = @"This app is not authorized to use Bluetooth low energy.\n\nAuthorize in Settings > Bluetooth.";
            break;
        case CBCentralManagerStatePoweredOff:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStatePoweredOff %d ", central.state];
            stateAlert = @"Bluetooth is currently powered off.\n\nPower ON the bluetooth in Settings > Bluetooth.";
            break;
        case CBCentralManagerStatePoweredOn:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStatePoweredOn %d ", central.state];
            self.isBluetoothOn = YES;
            break;
        case CBCentralManagerStateUnknown:
            stateDescription = [NSString stringWithFormat:@"CBCentralManagerStateUnknown %d ", central.state];
            stateAlert = @"Bluetooth state unknown";
            break;
        default:
            stateDescription = [NSString stringWithFormat:@"CBCentralManager Undefined %d ", central.state];
            stateAlert = @"Bluetooth state undefined";
            break;
    }
    
    NSLog(@"centralManagerDidUpdateState:[%@]", stateDescription);
    
    [self performSelectorOnMainThread:@selector(refreshBluetoothStatus) withObject:nil waitUntilDone:NO];
    
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary *)advertisementData
                  RSSI:(NSNumber *)RSSI
{
    NSLog(@"%@",[NSString stringWithFormat:@"didDiscoverPeripheral:name=[%@]",
                 peripheral.name]);
}

#pragma mark - show/hide bluetooth status
- (void)refreshBluetoothStatus
{
    self.imgviewAlertBg.hidden = self.isBluetoothOn;
    self.imgviewBluetoothIcon.hidden = !self.isBluetoothOn;
}


@end
