//
//  LoginViewController.m
//  TapConnect
//
//  Created by Donald Pae on 4/23/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "LoginViewController.h"
#import "AppDelegate.h"
#import "SVProgressHUD.h"
#import "NSString+Knotable.h"
#import "Common.h"
#import "DesignManager.h"
#import "User.h"

#define verticalGap 3.0
#define ktDefaultLoginTimeInterval 20.0

static CGFloat logoLowerPos = 84.0;
static CGFloat logoUpperPos = 48.0;

static CGFloat textFieldsLowerPos = 237.0;
static CGFloat textFieldsUpperPos = 190.0;

typedef enum
{
    LoginStateLoggingIn,
    LoginStateSigningUp,
    LoginStateTerms,
    LoginStateForgotPassword
} LoginState;

enum  {
    INPUT_NAME = 0,
    INPUT_NAME_EXISTS,
    INPUT_PASSWORD,
    INPUT_PASSWORD_TOO_SHORT,
    INPUT_EMAIL,
    INPUT_EMAIL_INVALID,
    INPUT_EMAIL_EXISTS,
    INPUT_CONNECTION_PROBLEM,
    INPUT_OK
};


@interface LoginViewController () {
    LoginState loginState;
    UIResponder *currentResponder;
    
    NSString *_inputUsername;
    NSString *_inputPassword;
    NSString *_inputEmail;
    NSString *_inputFullname;
}

@property (weak, nonatomic) IBOutlet UIImageView *imgBg;
@property (strong, nonatomic) UIImageView *logo;
@property (strong, nonatomic) UIView *loginGroup;

@property (strong, nonatomic) UITextField *usernameTextField;
@property (strong, nonatomic) UITextField *passwordTextField;
@property (strong, nonatomic) UITextField *emailTextField;
@property (strong, nonatomic) UIButton *loginFacebookButton;

@property (strong, nonatomic) UIButton *submitButton;
@property (strong, nonatomic) UIButton *bottomRightButton;
@property (strong, nonatomic) UIButton *bottomLeftButton;
@property (strong, nonatomic) UIImageView *verticalDivider;
@property (strong, nonatomic) UITextView *termsTextView;

@property (strong, nonatomic) MASConstraint *loginGroupTopConstraint;
@property (strong, nonatomic) MASConstraint *passwordFieldTopConstraint;
@property (strong, nonatomic) MASConstraint *bottomLeftButtonRightConstraint;

@property (nonatomic, strong) UIInterpolatingMotionEffect *horMotionEffect;
@property (nonatomic, strong) UIInterpolatingMotionEffect *vertMotionEffect;

@property (nonatomic, strong) NSTimer *checkTimer;

@end

@implementation LoginViewController

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
    
    // Check if user is cached and linked to Facebook, if so, bypass login

    [User loadUser];
    
    if ([PFUser currentUser]) {
        // save current user
        [User setCurrentUser:[User getUserFromPFUser:[PFUser currentUser]]];
        
        [self goInto];
    }
    else
    {
        if (FBSession.activeSession.state == FBSessionStateCreatedTokenLoaded) {
            
            [SVProgressHUD showWithStatus:@"Please wait" maskType:SVProgressHUDMaskTypeGradient];
            
            if (![Common hasConnectivity])
            {
                [SVProgressHUD showErrorWithStatus:[DesignManager getStringNoConnectivity] duration:3];
            }
            
            // If there's one, just open the session silently, without showing the user the login UI
            [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email"]
                                               allowLoginUI:NO
                                          completionHandler:^(FBSession *session, FBSessionState state, NSError *error) {
                                              // Handler for session state changes
                                              // This method will be called EACH time the session state changes,
                                              // also for intermediate states and NOT just when the session open
                                              // If the session was opened successfully
                                              if (!error && state == FBSessionStateOpen){
                                                  NSLog(@"Session opened");
                                                  [SVProgressHUD dismiss];
                                                  [self performSelectorOnMainThread:@selector(goInto) withObject:nil waitUntilDone:NO];
                                                  return;
                                              }
                                              [SVProgressHUD dismiss];
                                          }];
        }
    }
    
    
    self.horMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                                           type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    self.vertMotionEffect = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                                            type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
    
    CGFloat amplitude = 50.0;
    _horMotionEffect.minimumRelativeValue = @(amplitude);
    _horMotionEffect.maximumRelativeValue = @(-amplitude);
    _vertMotionEffect.minimumRelativeValue = @(amplitude);
    _vertMotionEffect.maximumRelativeValue = @(-amplitude);

    
    self.logo = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"logo"]];
    [self.view addSubview:self.logo];
    
    [_logo mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(logoLowerPos));
        make.centerX.equalTo(@0);
    }];
    
    
    UIView *bottomGroup = [[UIView alloc] initWithFrame:CGRectZero];
    bottomGroup.backgroundColor = [UIColor clearColor];
    //bottomGroup.alpha = 0.5;
    [self.view addSubview:bottomGroup];
    
    _verticalDivider = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"vertical-divider"]];
    
    _bottomRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_bottomRightButton setTitle:@"PASSWORD" forState:UIControlStateNormal];
    [_bottomRightButton addTarget:self action:@selector(enterForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    _bottomRightButton.tintColor = [UIColor darkGrayColor];
    _bottomRightButton.titleLabel.font = [UIFont systemFontOfSize:12.0];
    
    _bottomLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [_bottomLeftButton setTitle:@"SIGN UP" forState:UIControlStateNormal];
    [_bottomLeftButton addTarget:self action:@selector(enterSignup:) forControlEvents:UIControlEventTouchUpInside];
    _bottomLeftButton.tintColor = _bottomRightButton.tintColor;
    _bottomLeftButton.titleLabel.font = _bottomRightButton.titleLabel.font;
    
    [bottomGroup addSubview:_bottomRightButton];
    [bottomGroup addSubview:_bottomLeftButton];
    [bottomGroup addSubview:_verticalDivider];
    
    
    [bottomGroup mas_makeConstraints:^(MASConstraintMaker *make) {
        //make.bottom.equalTo(@-108);
        make.top.equalTo(@430);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
        
        // make.height.equalTo(@30.0);
    }];
    
    
    [_verticalDivider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@4);
        make.bottom.equalTo(@-4);
        make.centerX.equalTo(@0);
        
    }];
    
    [_bottomLeftButton mas_makeConstraints:^(MASConstraintMaker *make) {
        self.bottomLeftButtonRightConstraint = make.right.equalTo(_verticalDivider.mas_left).with.offset(-8.0);
        make.centerY.equalTo(_verticalDivider);
        // make.left.equalTo(@0);
    }];
    
    [_bottomRightButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_verticalDivider.mas_right).with.offset(8.0);
        make.centerY.equalTo(_verticalDivider);
        // make.right.equalTo(@0);
        
    }];
    
    [self initializeTextFields];
    
    
    _loginFacebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_loginFacebookButton setImage:[UIImage imageNamed:@"loginfacebook"] forState:UIControlStateNormal];
    [_loginFacebookButton setTitle:@"" forState:UIControlStateNormal];
    [_loginFacebookButton addTarget:self action:@selector(onLoginWithFacebook:) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:_loginFacebookButton];
    
    [_loginFacebookButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@42.0);
        make.width.equalTo(@260.0);
        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-50);
    }];
     
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(backgroundTap:)];
    [self.view addGestureRecognizer:tap];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBarHidden = YES;
    
    [self.imgBg addMotionEffect:_horMotionEffect];
    [self.imgBg addMotionEffect:_vertMotionEffect];
}

- (void)viewDidAppear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardShowing:)
                                                 name:UIKeyboardWillShowNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardHiding:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
}
- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
    
    [self.imgBg removeMotionEffect:_horMotionEffect];
    [self.imgBg removeMotionEffect:_vertMotionEffect];
}


- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) initializeTextFields {

    _emailTextField = [self loginTextFieldForIcon:@"login-email" placeholder:@"EMAIL"];
    _emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    _emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _emailTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    
    _usernameTextField = [self loginTextFieldForIcon:@"login-username" placeholder:@"FULL NAME"];
    _usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _usernameTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    
    _passwordTextField = [self loginTextFieldForIcon:@"login-password" placeholder:@"PASSWORD"];
    _passwordTextField.secureTextEntry = YES;
    _passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _passwordTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    
    //usernameTextField.alpha = _passwordTextField.alpha = _emailTextField.alpha = 0.5;
    
    _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _submitButton.backgroundColor = [UIColor colorWithRed:0.21 green:0.68 blue:0.90 alpha:1.0];
    
    _submitButton.tintColor = [UIColor whiteColor];
    _submitButton.layer.cornerRadius = 5.0;
    [_submitButton setTitle:@"LOGIN" forState:UIControlStateNormal];
    [_submitButton addTarget:self action:@selector(onLogin:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _loginGroup = [UIView new];
    _loginGroup.backgroundColor = [UIColor clearColor];
    
    [_loginGroup addSubview:_emailTextField];
    [_loginGroup addSubview:_usernameTextField];
    [_loginGroup addSubview:_passwordTextField];
    [_loginGroup addSubview:_submitButton];
    
    
    
    [self.view addSubview:_loginGroup];
    
    
    [_emailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@42.0);
        make.width.equalTo(@260.0);
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
    }];
    
    [_passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_emailTextField);
        make.left.equalTo(_emailTextField);
        self.passwordFieldTopConstraint = make.top.equalTo(_emailTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    //Start out logging in with the email address behind password
    [_usernameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_emailTextField);
        make.left.equalTo(_emailTextField);
        make.top.equalTo(_emailTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    _usernameTextField.hidden = YES;
    
    
    [_submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_usernameTextField);
        make.left.equalTo(_usernameTextField);
        make.top.equalTo(_passwordTextField.mas_bottom).with.offset(15.0);
        make.bottom.equalTo(@0);
    }];
    
    [_loginGroup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@0);
        _loginGroupTopConstraint = make.top.equalTo(@(textFieldsLowerPos));
    }];
    
    
}

- (UITextField *)loginTextFieldForIcon:(NSString *)filename placeholder:(NSString *)placeholder {
    
    //Gray background view
    UIView *grayView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 45.0, 42.0)];
    grayView.backgroundColor = [UIColor colorWithRed:0.67 green:0.70 blue:0.77 alpha:1.0];
    
    //Path & Mask so we only make rounded corners on right side
    UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:grayView.bounds
                                                   byRoundingCorners:(UIRectCornerTopLeft | UIRectCornerBottomLeft)
                                                         cornerRadii:CGSizeMake(5.0, 5.0)];
    CAShapeLayer *maskLayer = [[CAShapeLayer alloc] init];
    maskLayer.frame = grayView.bounds;
    maskLayer.path = maskPath.CGPath;
    grayView.layer.mask = maskLayer;
    
    //Add icon image
    UIImageView *passwordIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:filename]];
    [grayView addSubview:passwordIcon];
    
    [passwordIcon mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@0);
        make.centerY.equalTo(@0);
    }];
    
    //Finally make the textField
    UITextField *textField = [[UITextField alloc] init];
    textField.borderStyle = UITextBorderStyleRoundedRect;
    textField.font = [UIFont systemFontOfSize:14.0];
    textField.textColor = [UIColor blackColor];
    textField.backgroundColor = [UIColor whiteColor];
    textField.leftViewMode = UITextFieldViewModeAlways;
    textField.leftView = grayView;
    textField.placeholder = placeholder;
    textField.delegate = self;
    
    return textField;
}


# pragma mark Gesture selector
- (void)backgroundTap:(UITapGestureRecognizer *)backgroundTap {
    if(currentResponder){
        [currentResponder resignFirstResponder];
    }
}

#pragma mark Navigation methods between states of the Login screen

- (void)goInto
{
    [self goBackToLogin:nil];
    [self performSegueWithIdentifier:@"tomain" sender:self];
}

#pragma mark Login

- (IBAction)onLogin:(id)sender {
    if (currentResponder) {
        [currentResponder resignFirstResponder];
    }
    
    int nInput = [self getInputType];
     
     if (nInput != INPUT_OK) {
         [self showAlertMessage:nInput];
     } else {
         //_checkTimer = [NSTimer scheduledTimerWithTimeInterval:ktDefaultLoginTimeInterval target:self selector:@selector(onTimer:) userInfo:nil repeats:NO];
         [SVProgressHUD showWithStatus:@"Please wait" maskType:SVProgressHUDMaskTypeGradient];
         
         if (![Common hasConnectivity])
         {
             [SVProgressHUD showErrorWithStatus:[DesignManager getStringNoConnectivity] duration:3];
             return;
         }
         [PFUser logInWithUsernameInBackground:_inputEmail password:_inputPassword
                                         block:^(PFUser *user, NSError *error) {
                                             if (user) {
                                                 // Do stuff after successful login.
                                                 [SVProgressHUD dismiss];
                                                 [User setCurrentUser:[User getUserFromPFUser:user]];
                                                 
                                                 [self performSelectorOnMainThread:@selector(goInto) withObject:nil waitUntilDone:NO];
                                             } else {
                                                 // The login failed. Check error to see why.
                                                 //[SVProgressHUD showErrorWithStatus:[error localizedDescription] duration:3];
                                                 
                                                 [SVProgressHUD showErrorWithStatus:@"Email address and Password is not valied!" duration:3];
                                             }
                                         }];
     }
}

- (void)prepareForEnteringLoginState {
    loginState = LoginStateLoggingIn;

    [_passwordFieldTopConstraint uninstall];
    [_passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        self.passwordFieldTopConstraint = make.top.equalTo(_emailTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    [_logo mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(logoLowerPos));
    }];
    
    [_loginGroup mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(textFieldsLowerPos));
    }];
}

- (void)configureLoginState {
    loginState = LoginStateLoggingIn;
    
    [self reset];
    
    //Without these there is an unwanted fade animation
    [UIView setAnimationsEnabled:NO];
    [_bottomLeftButton setTitle:@"SIGN UP" forState:UIControlStateNormal];
    [_bottomRightButton setTitle:@"PASSWORD" forState:UIControlStateNormal];
    [_submitButton setTitle:@"LOGIN" forState:UIControlStateNormal];
    [UIView setAnimationsEnabled:YES];
    
    _usernameTextField.hidden = YES;
    
    [_bottomLeftButton addTarget:self action:@selector(enterSignup:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomRightButton addTarget:self action:@selector(enterForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton addTarget:self action:@selector(onLogin:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)leaveLoginState {
    [_bottomLeftButton removeTarget:self action:@selector(enterSignup:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomRightButton removeTarget:self action:@selector(enterForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton removeTarget:self action:@selector(onLogin:) forControlEvents:UIControlEventTouchUpInside];
}

#pragma mark New User Signup

- (IBAction)enterSignup:(id)sender {
    loginState = LoginStateSigningUp;
    
    _usernameTextField.hidden = NO;
    [_passwordFieldTopConstraint uninstall];
    [_passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        self.passwordFieldTopConstraint = make.top.equalTo(_usernameTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    [_logo mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(logoUpperPos));
    }];
    
    [_loginGroup mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(textFieldsUpperPos));
    }];
    
    [self leaveLoginState];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self reset];
        [self configureSignUpState];
        
    }];
    
}

- (void)configureSignUpState {

    //Without these there is an unwanted fade animation
    [UIView setAnimationsEnabled:NO];
    [_bottomLeftButton setTitle:@"BACK" forState:UIControlStateNormal];
    [_bottomRightButton setTitle:@"TERMS" forState:UIControlStateNormal];
    [_submitButton setTitle:@"SIGN UP" forState:UIControlStateNormal];
    [UIView setAnimationsEnabled:YES];
    
    [_bottomLeftButton addTarget:self action:@selector(goBackToLogin:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomRightButton addTarget:self action:@selector(openTerms:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton addTarget:self action:@selector(submitSignUp:) forControlEvents:UIControlEventTouchUpInside];
}

- (void)submitSignUp:(id)sender {
    if (currentResponder) {
        [currentResponder resignFirstResponder];
    }
    
    int nInput = [self getInputType];
    
    if (nInput != INPUT_OK) {
        [self showAlertMessage:nInput];
    } else {
        
        [SVProgressHUD showWithStatus:@"Please wait" maskType:SVProgressHUDMaskTypeGradient];
        
        if (![Common hasConnectivity])
        {
            [SVProgressHUD showErrorWithStatus:[DesignManager getStringNoConnectivity] duration:3];
            return;
        }
        
        PFUser *user = [PFUser user];
        user.username = _inputEmail;
        user.password = _inputPassword;
        user[@"fullname"] = _inputUsername;
        user[@"usertype"] = [NSString stringWithFormat:@"%d", UserTypeNative];

        [user signUpInBackgroundWithBlock:^(BOOL succeeded, NSError *error) {
            if (!error) {
                // Hooray! Let them use the app now.
                [SVProgressHUD dismiss];
                [User setCurrentUser:[User getUserFromPFUser:user]];
                [self performSelectorOnMainThread:@selector(goInto) withObject:nil waitUntilDone:NO];
            } else {
                NSString *errorString = [error userInfo][@"error"];
                // Show the errorString somewhere and let the user try again.
                [SVProgressHUD showErrorWithStatus:errorString duration:3];
            }
        }];
        // checkUsernameExist
    }
    
}

- (void)onLoginWithFacebook:(id)sender {
    
    NSLog(@"onLoginWithFacebook...");
    
    [SVProgressHUD showWithStatus:@"Please wait" maskType:SVProgressHUDMaskTypeGradient];
    
    if (![Common hasConnectivity])
    {
        [SVProgressHUD showErrorWithStatus:[DesignManager getStringNoConnectivity] duration:3];
        return;
    }
    
    
    // If the session state is any of the two "open" states when the button is clicked
    if (FBSession.activeSession.state == FBSessionStateOpen
        || FBSession.activeSession.state == FBSessionStateOpenTokenExtended) {
        
        NSLog(@"session is exist, so first clear session...");
        
        // Close the session and remove the access token from the cache
        // The session state handler (in the app delegate) will be called automatically
        [FBSession.activeSession closeAndClearTokenInformation];
    }
    
    {
        // Open a session showing the user the login UI
        // You must ALWAYS ask for basic_info permissions when opening a session
        [FBSession openActiveSessionWithReadPermissions:@[@"public_profile", @"email"]
                                           allowLoginUI:YES
                                      completionHandler:
         ^(FBSession *session, FBSessionState state, NSError *error) {
             
             NSLog(@"openActiveSessionWithReadPermissions completionHander...");
             
             // If the session was opened successfully
             if (!error && state == FBSessionStateOpen){
                 NSLog(@"Session opened!");
                 // Request to get information
                 [[FBRequest requestForMe] startWithCompletionHandler:^(FBRequestConnection *connection, NSDictionary<FBGraphUser>* result, NSError *error) {
                     
                     NSLog(@"fetching information...");
                    
                     if (!error)
                     {
                         NSLog(@"fetched information successfully! %@, %@, %@", result[@"email"], result[@"id"], result[@"name"]);
                         
                         [User setCurrentUser:[User getUserFromFBUser:result]];
                         
                         [SVProgressHUD dismiss];
                         
                         // go into main screen
                         [self performSelectorOnMainThread:@selector(goInto) withObject:nil waitUntilDone:NO];
                     }
                     else
                     {
                         NSLog(@"fatching information failed : error = %@", [error localizedDescription]);
                         [SVProgressHUD showErrorWithStatus:@"Getting user info failed." duration:3];
                     }
                 }];
                 
                 return;
             }
             
             [SVProgressHUD dismiss];
             
             if (state == FBSessionStateClosed || state == FBSessionStateClosedLoginFailed){
                 // If the session is closed
                 NSLog(@"Session closed");
                 // Show the user the logged-out UI
                 //[self userLoggedOut];
             }
             
             // Handle errors
             if (error){
                 NSLog(@"Error");
                 NSString *alertText;
                 NSString *alertTitle;
                 // If the error requires people using an app to make an action outside of the app in order to recover
                 if ([FBErrorUtility shouldNotifyUserForError:error] == YES){
                     alertTitle = @"Something went wrong";
                     alertText = [FBErrorUtility userMessageForError:error];
                     //[self showMessage:alertText withTitle:alertTitle];
                     NSLog(@"error open session : %@", alertText);
                 } else {
                     
                     // If the user cancelled login, do nothing
                     if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryUserCancelled) {
                         NSLog(@"User cancelled login");
                         
                         // Handle session closures that happen outside of the app
                     } else if ([FBErrorUtility errorCategoryForError:error] == FBErrorCategoryAuthenticationReopenSession){
                         alertTitle = @"Session Error";
                         alertText = @"Your current session is no longer valid. Please log in again.";
                         //[self showMessage:alertText withTitle:alertTitle];
                         [SVProgressHUD showErrorWithStatus:alertText duration:3];
                         
                         // Here we will handle all other errors with a generic error message.
                         // We recommend you check our Handling Errors guide for more information
                         // https://developers.facebook.com/docs/ios/errors/
                         
                         NSLog(@"error open session : %@", alertText);
                     } else {
                         //Get more error information from the error
                         NSDictionary *errorInformation = [[[error.userInfo objectForKey:@"com.facebook.sdk:ParsedJSONResponseKey"] objectForKey:@"body"] objectForKey:@"error"];
                         
                         // Show the user an error message
                         alertTitle = @"Something went wrong";
                         alertText = [NSString stringWithFormat:@"Please retry. \n\n If the problem persists contact us and mention this error code: %@", [errorInformation objectForKey:@"message"]];
                         //[self showMessage:alertText withTitle:alertTitle];
                         [SVProgressHUD showErrorWithStatus:alertText duration:3];
                         
                         NSLog(@"error open session : %@", alertText);
                     }
                 }
                 
                 NSLog(@"clearing fb token : %@", alertText);
                 // Clear this token
                 [FBSession.activeSession closeAndClearTokenInformation];
                 // Show the user the logged-out UI
                 //[self userLoggedOut];
             }
             
         }];
    }
}

- (void)leaveSignUpState {
    [_bottomLeftButton removeTarget:self action:@selector(goBackToLogin:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomRightButton removeTarget:self action:@selector(openTerms:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton removeTarget:self action:@selector(submitSignUp:) forControlEvents:UIControlEventTouchUpInside];
    
}

- (void)goBackToLogin:(id)sender {
    [self prepareForEnteringLoginState];
    [self leaveSignUpState];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        [self configureLoginState];
        
    }];
    
}

#pragma mark Terms & Conditions


- (void)openTerms:(id)sender {
    [self leaveSignUpState];
    
    
    _termsTextView = [[UITextView alloc] initWithFrame:CGRectZero textContainer:nil];
    _termsTextView.editable = NO;
    _termsTextView.layer.cornerRadius = 5.0;
    _termsTextView.layer.backgroundColor = [[UIColor colorWithRed:0.4f green:0.4f blue:0.4f alpha:0.5f] CGColor];
    
    NSString *titleText = @"Terms and Conditions of Use\n";
    NSString *bodyText = @"\n1. Terms\n\nBy accessing this app, you are agreeing to be bound the app Terms and Conditions of Use, all applicable laws and regulations...";
    
    NSDictionary *titleAttrs = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue-Light" size:16.0], NSForegroundColorAttributeName:[UIColor whiteColor]};
    NSDictionary *bodyAttrs = @{NSFontAttributeName:[UIFont fontWithName:@"HelveticaNeue" size:11.0], NSForegroundColorAttributeName:[UIColor whiteColor]};
    
    NSMutableAttributedString *termsText = [[NSMutableAttributedString alloc] initWithString:titleText attributes:titleAttrs];
    NSAttributedString *bodyAttString = [[NSAttributedString alloc] initWithString:bodyText attributes:bodyAttrs];
    
    [termsText appendAttributedString:bodyAttString];
    
    _termsTextView.attributedText = termsText;
    
    
    
    [self.view addSubview:_termsTextView];
    
    
    [_termsTextView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.equalTo(@256.0);
        make.height.equalTo(@218.0);
        make.centerX.equalTo(@400.0);
        make.top.equalTo(@190.0);
    }];
    
    
    [self.view layoutIfNeeded];
    
    
    [_termsTextView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@0.0);
    }];
    
    
    [_loginGroup mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@-400.0);
    }];
    
    [UIView animateWithDuration:0.3 animations:^{
        //_loginGroup.alpha = 0;
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        //Without these there is an unwanted fade animation
        [UIView setAnimationsEnabled:NO];
        [_bottomLeftButton setTitle:@"BACK" forState:UIControlStateNormal];
        [_bottomRightButton setTitle:@"LOG IN" forState:UIControlStateNormal];
        [UIView setAnimationsEnabled:YES];
        
        [_bottomLeftButton addTarget:self action:@selector(exitTerms:) forControlEvents:UIControlEventTouchUpInside];
        [_bottomRightButton addTarget:self action:@selector(exitTerms:) forControlEvents:UIControlEventTouchUpInside];
    }];
}

- (void)exitTerms:(id)sender {
    BOOL goingToSignUp = sender == _bottomLeftButton;
    
    [_bottomLeftButton removeTarget:self action:@selector(exitTerms:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomRightButton removeTarget:self action:@selector(exitTerms:) forControlEvents:UIControlEventTouchUpInside];
    
    
    [_termsTextView mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@400.0);
    }];
    
    [_loginGroup mas_updateConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(@0);
    }];
    
    if(!goingToSignUp){
        [self prepareForEnteringLoginState];
    }
    
    [UIView animateWithDuration:0.3 animations:^{
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        //Without these there is an unwanted fade animation
        [UIView setAnimationsEnabled:NO];
        if(goingToSignUp){
            [self configureSignUpState];
        } else {
            [self configureLoginState];
        }
        [UIView setAnimationsEnabled:YES];
    }];
}

#pragma mark Forgot / Rest Password

- (void)enterForgotPassword:(id)sender {
    [self leaveLoginState];
    
    loginState = LoginStateForgotPassword;
    
    _emailTextField.hidden = NO;
    
    [_logo mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(logoUpperPos));
    }];
    _bottomLeftButtonRightConstraint.offset( -8 + (_bottomLeftButton.bounds.size.width / 2.0) );
    /*
     [_bottomLeftButton mas_makeConstraints:^(MASConstraintMaker *make) {
     make.right.equalTo(@0.0);
     }];
     */
    
    _loginGroupTopConstraint.offset(textFieldsUpperPos);
    
    
    [UIView animateWithDuration:0.3 animations:^{
        _usernameTextField.alpha = 0;
        _passwordTextField.alpha = 0;
        _verticalDivider.alpha = 0;
        _bottomRightButton.alpha = 0;
        [self.view layoutIfNeeded];
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        
        [UIView setAnimationsEnabled:NO];
        [_bottomLeftButton setTitle:@"BACK" forState:UIControlStateNormal];
        //[_bottomRightButton setTitle:@"" forState:UIControlStateNormal];
        [_submitButton setTitle:@"RESET PASSWORD" forState:UIControlStateNormal];
        
        [UIView setAnimationsEnabled:YES];
        
        [_bottomLeftButton addTarget:self action:@selector(exitForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
        //[_bottomRightButton addTarget:self action:@selector(exitForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
        [_submitButton addTarget:self action:@selector(resetPassword) forControlEvents:UIControlEventTouchUpInside];
        
    }];
    
    
}

- (void)resetPassword {
    if (currentResponder) {
        [currentResponder resignFirstResponder];
    }
    
    int nInput = [self getInputType];
    
    if (nInput != INPUT_OK) {
        [self showAlertMessage:nInput];
    } else {
        
        [PFUser requestPasswordResetForEmailInBackground:_inputEmail];
        [self exitForgotPassword:nil];
        
    }
    
}

- (void)exitForgotPassword:(id)sender {
    [_bottomLeftButton removeTarget:self action:@selector(exitForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    [_bottomRightButton removeTarget:self action:@selector(exitForgotPassword:) forControlEvents:UIControlEventTouchUpInside];
    [_submitButton removeTarget:self action:@selector(resetPassword) forControlEvents:UIControlEventTouchUpInside];
    
    
    [_logo mas_updateConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(@(logoLowerPos));
    }];
    
    _bottomLeftButtonRightConstraint.offset(-8);
    
    _loginGroupTopConstraint.offset(textFieldsLowerPos);
    
    
    [UIView animateWithDuration:0.3 animations:^{
        _usernameTextField.alpha = 1.0;
        _passwordTextField.alpha = 1.0;
        _verticalDivider.alpha = 1.0;
        _bottomRightButton.alpha = 1.0;
        
        [self.view layoutIfNeeded];
        
    } completion:^(BOOL finished) {
        [self configureLoginState];
    }];

}

#pragma mark -
#pragma mark UITextFieldDelegate Methods

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    currentResponder = textField;
    /*
    if (textField == _usernameTextField && preFilledUsername) {
        preFilledUsername = NO;
        textField.text = @"";
    }
     */
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    currentResponder = nil;
}


- (void) reset
{
    /*
    if(self.currentAccount && loginState == LoginStateLoggingIn){
        _usernameTextField.text = self.currentAccount.user.name;
        preFilledUsername = YES;
    } else {
        _usernameTextField.text = @"";
        preFilledUsername = NO;
    }
     */
    
    _passwordTextField.text = @"";
    _emailTextField.text = @"";
}

#pragma mark Keyboard Methods

- (void)keyboardShowing:(NSNotification *)note
{
    NSNumber *duration = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    //CGRect endFrame = ((NSValue *)note.userInfo[UIKeyboardFrameEndUserInfoKey]).CGRectValue;
    _loginGroupTopConstraint.with.offset(60.0);
    
    
    [UIView animateWithDuration:duration.floatValue animations:^{
        self.logo.alpha = 0.0;
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardHiding:(NSNotification *)note
{
    NSNumber *duration = note.userInfo[UIKeyboardAnimationDurationUserInfoKey];
    
    _loginGroupTopConstraint.with.offset(loginState == LoginStateLoggingIn ? textFieldsLowerPos : textFieldsUpperPos);
    
    [UIView animateWithDuration:duration.floatValue animations:^{
        self.logo.alpha = 1.0;
        [self.view layoutIfNeeded];
    }];
    
}

#pragma mark Input Validation

- (void) updateAndCleanInput {
    _inputUsername = [_usernameTextField.text trimmed];
    _usernameTextField.text = _inputUsername;
    
    _inputEmail = [[_emailTextField.text trimmed] lowercaseStringWithLocale:[NSLocale currentLocale]];
    _emailTextField.text = _inputEmail;
    
    NSArray *emailComponents = [_inputEmail componentsSeparatedByString:@"@"];
    _inputFullname = emailComponents.count > 0 ? emailComponents.firstObject : _inputEmail;
    
    _inputPassword = _passwordTextField.text;
}

- (int) getInputType {
    int nRet;
    
    [self updateAndCleanInput];
    
    switch (loginState) {
        case LoginStateForgotPassword:
            nRet = [self validateForgotPassword];
            break;
        case LoginStateSigningUp:
            nRet = [self validateSigningUp];
            break;
        default:
            //LoginStateLoggingIn
            nRet = [self validateLoggingIn];
            break;
    }
    return nRet;
}


- (int) validateForgotPassword {
    if (_inputEmail.length == 0) {
        return INPUT_EMAIL;
    }
    else if (![_inputEmail isValidEmail]) {
        return INPUT_EMAIL_INVALID;
    }
    return INPUT_OK;
}

- (int)validateLoggingIn {
    int nRet;
    if (_inputEmail.length == 0) {
        nRet = INPUT_EMAIL;
    } else if (_inputPassword.length == 0) {
        nRet = INPUT_PASSWORD;
    } else {
        nRet = INPUT_OK;
    }
    return nRet;
}

- (int)validateSigningUp {
    int nRet;
    if (_inputUsername.length == 0) {
        nRet = INPUT_NAME;
    }
    else if (_inputEmail.length == 0) {
        nRet = INPUT_EMAIL;
    }
    else if (![_inputEmail isValidEmail]) {
        nRet = INPUT_EMAIL_INVALID;
    }
    else if (_inputPassword.length == 0) {
        nRet = INPUT_PASSWORD;
    }
    else if (_inputPassword.length < 6) {
        nRet = INPUT_PASSWORD_TOO_SHORT;
    }
    else {
        nRet = INPUT_OK;
    }
    return nRet;
}

- (void) showAlertMessage:(int) type {
    NSString* strTitle;
    switch (type) {
        case INPUT_CONNECTION_PROBLEM:
            strTitle = @"We're sorry, there is a network issue. Please try again later";
            break;
        case INPUT_NAME:
            strTitle = loginState == LoginStateLoggingIn ? @"Please enter your name" : @"Please enter a name";
            break;
        case INPUT_NAME_EXISTS:
            strTitle = @"That username is taken, please choose another";
            break;
        case INPUT_PASSWORD:
            strTitle = loginState == LoginStateLoggingIn ? @"Please enter your password" : @"Please enter a password";
            break;
        case INPUT_PASSWORD_TOO_SHORT:
            strTitle = @"That password is too short, it must be at least 6 characters";
            break;
        case INPUT_EMAIL:
            strTitle = @"Please enter your email address";
            break;
        case INPUT_EMAIL_INVALID:
            strTitle = @"That email address is not valid";
            break;
        case INPUT_EMAIL_EXISTS:
            strTitle = @"That email is already being used, please log in";
            break;
        default:
            strTitle = @"";
            break;
    }
    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:strTitle message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

@end
