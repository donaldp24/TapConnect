//
//  LoginViewController.m
//  TapConnect
//
//  Created by Donald Pae on 4/23/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "LoginViewController.h"

#define verticalGap 3.0

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


@interface LoginViewController () {
    LoginState loginState;
    UIResponder *currentResponder;
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
@property (strong, nonatomic) MASConstraint *loginFacebookButtonTopConstraint;
@property (strong, nonatomic) MASConstraint *bottomLeftButtonRightConstraint;

@property (nonatomic, strong) UIInterpolatingMotionEffect *horMotionEffect;
@property (nonatomic, strong) UIInterpolatingMotionEffect *vertMotionEffect;

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
    
    
//    CGFloat scaleFactor = 1.2;
//    [self.imgBg mas_makeConstraints:^(MASConstraintMaker *maker) {
//        maker.edges.equalTo(self.view);
//    }];
    
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
    
    
    
    _usernameTextField = [self loginTextFieldForIcon:@"login-username" placeholder:@"USERNAME"];
    _usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _usernameTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    
    _emailTextField = [self loginTextFieldForIcon:@"login-email" placeholder:@"EMAIL"];
    _emailTextField.keyboardType = UIKeyboardTypeEmailAddress;
    _emailTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _emailTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _emailTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    
    _passwordTextField = [self loginTextFieldForIcon:@"login-password" placeholder:@"PASSWORD"];
    _passwordTextField.secureTextEntry = YES;
    _passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _passwordTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    _passwordTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    
    //usernameTextField.alpha = _passwordTextField.alpha = _emailTextField.alpha = 0.5;
    
    _loginFacebookButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_loginFacebookButton setImage:[UIImage imageNamed:@"loginfacebook"] forState:UIControlStateNormal];
    [_loginFacebookButton setTitle:@"" forState:UIControlStateNormal];
    
    _submitButton = [UIButton buttonWithType:UIButtonTypeSystem];
    _submitButton.backgroundColor = [UIColor colorWithRed:0.21 green:0.68 blue:0.90 alpha:1.0];
    
    _submitButton.tintColor = [UIColor whiteColor];
    _submitButton.layer.cornerRadius = 5.0;
    [_submitButton setTitle:@"LOGIN" forState:UIControlStateNormal];
    [_submitButton addTarget:self action:@selector(onLogin:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _loginGroup = [UIView new];
    _loginGroup.backgroundColor = [UIColor clearColor];
    
    [_loginGroup addSubview:_usernameTextField];
    [_loginGroup addSubview:_emailTextField];
    [_loginGroup addSubview:_passwordTextField];
    [_loginGroup addSubview:_loginFacebookButton];
    [_loginGroup addSubview:_submitButton];
    
    
    
    [self.view addSubview:_loginGroup];
    
    
    [_usernameTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(@42.0);
        make.width.equalTo(@260.0);
        make.top.equalTo(@0);
        make.left.equalTo(@0);
        make.right.equalTo(@0);
    }];
    
    [_passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_usernameTextField);
        make.left.equalTo(_usernameTextField);
        self.passwordFieldTopConstraint = make.top.equalTo(_usernameTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    //Start out logging in with the email address behind password
    [_emailTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_usernameTextField);
        make.left.equalTo(_usernameTextField);
        make.top.equalTo(_usernameTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    _emailTextField.hidden = YES;
    
    
    [_submitButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_usernameTextField);
        make.left.equalTo(_usernameTextField);
        make.top.equalTo(_passwordTextField.mas_bottom).with.offset(15.0);
        //make.bottom.equalTo(@0);
    }];
    
    [_loginFacebookButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(_submitButton);
        make.left.equalTo(_submitButton);
        self.loginFacebookButtonTopConstraint = make.top.equalTo(_submitButton.mas_top);
        make.bottom.equalTo(@0);
    }];
    
    _loginFacebookButton.hidden = YES;
    
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

#pragma mark Login

- (IBAction)onLogin:(id)sender {
    if (currentResponder) {
        [currentResponder resignFirstResponder];
    }
    
    /*int nInput = [self getInputType];
     
     if (nInput != INPUT_OK) {
     [self showAlertMessage:nInput];
     } else {
     _checkTimer = [NSTimer scheduledTimerWithTimeInterval:ktDefaultLoginTimeInterval target:self selector:@selector(onTimer:) userInfo:nil repeats:NO];
     [SVProgressHUD showWithStatus:@"Please wait" maskType:SVProgressHUDMaskTypeGradient];
     
     [self loginWithMeteor];
     }
     */
    
    [self performSegueWithIdentifier:@"tomain" sender:self];
}

- (void)prepareForEnteringLoginState {
    loginState = LoginStateLoggingIn;
    
    /*
    [_loginFacebookBottomConstraint uninstall];
    [_loginFacebookButton mas_makeConstraints:^(MASConstraintMaker *make) {
        self.loginFacebookBottomConstraint = make.bottom.equalTo(_usernameTextField.mas_top).with.offset(-verticalGap);
    }];
     */
    
    [_passwordFieldTopConstraint uninstall];
    [_passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        self.passwordFieldTopConstraint = make.top.equalTo(_usernameTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    [_loginFacebookButtonTopConstraint uninstall];
    [_loginFacebookButton mas_makeConstraints:^(MASConstraintMaker *make) {
        self.loginFacebookButtonTopConstraint = make.top.equalTo(_submitButton.mas_top);
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
    
    _loginFacebookButton.hidden = YES;
    _emailTextField.hidden = YES;
    
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
    _loginFacebookButton.hidden = NO;
    _emailTextField.hidden = NO;
    [_passwordFieldTopConstraint uninstall];
    [_passwordTextField mas_makeConstraints:^(MASConstraintMaker *make) {
        self.passwordFieldTopConstraint = make.top.equalTo(_emailTextField.mas_bottom).with.offset(verticalGap);
    }];
    
    [_loginFacebookButtonTopConstraint uninstall];
    [_loginFacebookButton mas_makeConstraints:^(MASConstraintMaker *make) {
        self.loginFacebookButtonTopConstraint = make.top.equalTo(_submitButton.mas_bottom).with.offset(verticalGap);
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
    /*
    int nInput = [self getInputType];
    
    if (nInput != INPUT_OK) {
        [self showAlertMessage:nInput];
    } else {
        //UIAlertView* alert = [[UIAlertView alloc] initWithTitle:@"TO DO: Server integration to Sign Up" message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
        //[alert show];
        
        // checkUsernameExist
        
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if(app.meteor){
            MeteorClient *meteor = app.meteor;
            NSLog(@"have meteor, connected ? %d ", meteor.connected);
            
            [meteor callMethodName:@"checkUsernameExist" parameters:@[_inputUsername] responseCallback:^(NSDictionary *response, NSError *error) {
                
                if(error){
                    NSLog(@"called checkUsernameExist got error %@", error);
                    if([MeteorClientTransportErrorDomain isEqualToString:error.domain] && error.code == 0){
                        [self showAlertMessage:INPUT_CONNECTION_PROBLEM];
                    }
                    return;
                }
                
                BOOL usernameExists = ((NSNumber *)response[@"result"]).boolValue;
                NSLog(@"usernameExists? %d", usernameExists);
                
                [self usernameExistsResponse:usernameExists];
            }];
            
            
        }
    }
    */
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
    /*
    int nInput = [self getInputType];
    
    if (nInput != INPUT_OK) {
        [self showAlertMessage:nInput];
    } else {
        
        AppDelegate *app = (AppDelegate *)[UIApplication sharedApplication].delegate;
        if(app.meteor){
            MeteorClient *meteor = app.meteor;
            [meteor callMethodName:@"forgotPassword" parameters:@[@{@"email":_inputEmail}] responseCallback:^(NSDictionary *response, NSError *error) {
                
                if(error){
                    NSLog(@"forgotPassword error: %@", response);
                    NSString *reason = error.userInfo[NSLocalizedDescriptionKey][@"reason"];
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:reason message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                } else {
                    NSLog(@"forgotPassword response: %@", response);
                    NSString *message = @"Email sent. Please check your email.";
                    UIAlertView* alert = [[UIAlertView alloc] initWithTitle:message message:nil delegate:self cancelButtonTitle:@"OK" otherButtonTitles:nil];
                    [alert show];
                    [self exitForgotPassword:nil];
                }
            }];
        }
        
    }
     */
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
@end
