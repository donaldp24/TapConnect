//
//  User.h
//  TapConnect
//
//  Created by Donald Pae on 4/28/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Parse/Parse.h>
#import <FacebookSDK/FacebookSDK.h>

enum UserType {
    UserTypeNative = 0, //native user
    UserTypeFB = 1      //facebook user
    };

@interface User : NSObject

@property (nonatomic) int userType;
@property (nonatomic, retain) NSString *email;
@property (nonatomic, retain) NSString *pwd;
@property (nonatomic, retain) NSString *displayName;

+ (void)loadUser;
+ (void)setCurrentUser:(User *)user;
+ (User *)currentUser;

+ (User *)getUserFromPFUser:(PFUser *)pfUser;
+ (User *)getUserFromFBUser:(NSDictionary<FBGraphUser> *)fbUser;


+(BOOL) readBoolEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(BOOL)defaults;
+(float) readFloatEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(float)defaults;
+(int) readIntEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(int)defaults;
+(double) readDoubleEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(double)defaults;
+(NSString *) readEntry:(NSUserDefaults *)config key:(NSString *) key defaults:(NSString *)defaults;


@end
