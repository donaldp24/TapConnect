//
//  DesignManager.h
//  TapConnect
//
//  Created by Donald Pae on 4/23/14.
//  Copyright (c) 2014 donald. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface DesignManager : NSObject

+ (DesignManager *)sharedInstance;

+ (NSString *)getMainTitle;

@end
