//
//  ViewController.h
//  TapConnect
//
//  Created by Donald Pae on 4/23/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreLocation/CoreLocation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class LoginViewController;

@interface ViewController : UIViewController<UIActionSheetDelegate, CLLocationManagerDelegate>

@property (nonatomic, retain) LoginViewController *loginController;

@end
