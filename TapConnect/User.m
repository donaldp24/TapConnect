//
//  User.m
//  TapConnect
//
//  Created by Donald Pae on 4/28/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "User.h"

#define KEY_USERTYPE        @"usertype"
#define KEY_EMAIL           @"email"
#define KEY_PWD             @"pwd"
#define KEY_DISPLAYNAME     @"fullname"

static User *_currentUser;

@implementation User

- (id)init
{
    self = [super init];
    return self;
}

+ (void)loadUser
{
    _currentUser = [[User alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    _currentUser.userType = [User readIntEntry:defaults key:KEY_USERTYPE defaults:UserTypeNative];
    _currentUser.email = [defaults stringForKey:KEY_EMAIL];
    _currentUser.pwd = [defaults stringForKey:KEY_PWD];
    _currentUser.displayName = [defaults stringForKey:KEY_DISPLAYNAME];
}

+ (User *)currentUser
{
    return _currentUser;
}

+ (void)setCurrentUser:(User *)user
{
    _currentUser = [[User alloc] init];
    _currentUser.userType = user.userType;
    _currentUser.email = user.email;
    _currentUser.pwd = user.pwd;
    _currentUser.displayName = user.displayName;

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setInteger:_currentUser.userType forKey:KEY_USERTYPE];
    [defaults setObject:_currentUser.email forKey:KEY_EMAIL];
    [defaults setObject:_currentUser.pwd forKey:KEY_PWD];
    [defaults setObject:_currentUser.displayName forKey:KEY_DISPLAYNAME];
    [defaults synchronize];
}


+ (User *)getUserFromPFUser:(PFUser *)pfUser
{
    User *user = [[User alloc] init];
    
    // email
    if (pfUser.username != nil)
        user.email = pfUser.username;
    else
        user.email = @"";
    
    // password
    if (pfUser.password != nil)
        user.pwd = pfUser.password;
    else
        user.pwd = @"";
    
    // fullname
    if (pfUser[@"fullname"] != nil)
        user.displayName = pfUser[@"fullname"];
    else
        user.displayName = @"";
    
    user.userType = UserTypeNative;

    return user;
}

+ (User *)getUserFromFBUser:(NSDictionary<FBGraphUser> *)fbUser
{
    User *user = [[User alloc] init];
    
    // email
    NSString *obj = [fbUser objectForKey:@"email"];
    if (obj == nil)
        user.email = @"";
    else
        user.email = [NSString stringWithFormat:@"%@", obj];
    
    // id
    obj = [fbUser objectForKey:@"id"];
    if (obj == nil)
        user.pwd = @"";
    else
        user.pwd = [NSString stringWithFormat:@"%@", obj];
    
    // display name
    obj = [fbUser objectForKey:@"name"];
    if (obj == nil)
        user.displayName = @"";
    else
        user.displayName = [NSString stringWithFormat:@"%@", obj];
    
    user.userType = UserTypeFB;
    
    return user;
}

#pragma mark - Config Manager -
+(BOOL) readBoolEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(BOOL)defaults
{
    if (key == nil)
        return defaults;
    
    NSString *str = [config objectForKey:key];
    
    if (str == nil) {
        return defaults;
    } else {
        return str.boolValue;
    }
    
    return defaults;
}

+(float) readFloatEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(float)defaults
{
    if (key == nil)
        return defaults;
    
    NSString *str = [config objectForKey:key];
    
    if (str == nil) {
        return defaults;
    } else {
        return str.floatValue;
    }
    
    return defaults;
}

+(int) readIntEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(int)defaults
{
    if (key == nil)
        return defaults;
    
    NSString *str = [config objectForKey:key];
    
    if (str == nil) {
        return defaults;
    } else {
        return str.intValue;
    }
    
    return defaults;
}

+(double) readDoubleEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(double)defaults
{
    if (key == nil)
        return defaults;
    
    NSString *str = [config objectForKey:key];
    
    if (str == nil) {
        return defaults;
    } else {
        return str.doubleValue;
    }
    
    return defaults;
}

+(NSString *) readEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(NSString *)defaults
{
    if (key == nil)
        return defaults;
    
    NSString *str = [config objectForKey:key];
    
    if (str == nil) {
        return defaults;
    } else {
        return str;
    }
    
    return defaults;
}

@end
