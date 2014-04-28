//
//  ProfileViewController.m
//  TapConnect
//
//  Created by Donald Pae on 4/28/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "ProfileViewController.h"
#import "DesignManager.h"
#import "User.h"

@interface ProfileViewController ()

@property (nonatomic, retain) IBOutlet UILabel *lblName;
@property (nonatomic, retain) IBOutlet UILabel *lblEmail;

@end

@implementation ProfileViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    //if ([User currentUser].userType == UserTypeNative)
    {
        self.lblName.text = [User currentUser].displayName;
        self.lblEmail.text = [User currentUser].email;
    }
 
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // title
    self.navigationItem.hidesBackButton = NO;
    self.navigationItem.title = [DesignManager getMainTitle];
    
   /*
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(goBack)];
    cancelButton.tintColor = [UIColor whiteColor];
    self.navigationItem.leftBarButtonItem = cancelButton;
    */
     UIBarButtonItem *newBackButton =
     [[UIBarButtonItem alloc] initWithTitle:@" Back"
     style:UIBarButtonItemStyleBordered
     target:self
     action:@selector(goBack)];
     
     self.navigationItem.leftBarButtonItem = newBackButton;
    
     
    //self.navigationController.navigationBar.topItem.title = @"Back";
    //self.navigationItem.leftBarButtonItem.title = @"Back";
    
    
    self.navigationController.navigationBar.barStyle = UIBarStyleBlackTranslucent;
    
    self.navigationController.navigationBar.tintColor = [UIColor blackColor];
    self.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor darkGrayColor]};
    
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = [UIColor colorWithWhite:1.0 alpha:0.5];

}

- (void)goBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

@end
