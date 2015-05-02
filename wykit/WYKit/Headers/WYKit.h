//
//  WYKit.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/19/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#ifndef WYKit_h
#define WYKit_h

#import <Foundation/Foundation.h>
#import "WYConstants.h"
#import "WYObject+Subclass.h"
#import "WYObject.h"
#import "WYQuery.h"
#import "WYFile.h"
#import "WYUser.h"
#import "WYGeoPoint.h"
#import "WYInstallation.h"

@interface WYKit : NSObject

+ (void)setApplicationEndpoint:(NSString *)endpoint clientKey:(NSString *)clientKey;
+ (NSString *)getApplicationEndpoint;
+ (NSString *)getClientKey;
+ (NSString*)getApplicationEndpointDomain;

@end

#endif
