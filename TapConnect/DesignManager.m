//
//  DesignManager.m
//  TapConnect
//
//  Created by Donald Pae on 4/23/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import "DesignManager.h"

static DesignManager *_sharedDesignManagerInstance = nil;

@implementation DesignManager

+ (DesignManager *)sharedInstance
{
    if (_sharedDesignManagerInstance == nil)
    {
        _sharedDesignManagerInstance = [[DesignManager alloc] init];
    }
    return _sharedDesignManagerInstance;
}

+ (NSString *)getMainTitle
{
    return @"TapConnect!";
}

+ (NSString *)getStringNoConnectivity
{
    return @"Please check your network";
}

@end
