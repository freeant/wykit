//
//  WYInstallation.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/28/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYObject.h"
#import "WYSubclassing.h"

@class WYQuery;

@interface WYInstallation : WYObject<WYSubclassing>
+ (NSString *)wyClassName;

/** @name Targeting Installations */

/*!
 Creates a query for WYInstallation objects. The resulting query can only
 be used for targeting a WYPush. Calling find methods on the resulting query
 will raise an exception.
 */
+ (WYQuery *)query;

/** @name Accessing the Current Installation */

/*!
 Gets the currently-running installation from disk and returns an instance of
 it. If this installation is not stored on disk, returns a WYInstallation
 with deviceType and installationId fields set to those of the
 current installation.
 @result Returns a WYInstallation that represents the currently-running
 installation.
 */
+ (instancetype)currentInstallation;

/*!
 Sets the device token string property from an NSData-encoded token.
 */
- (void)setDeviceTokenFromData:(NSData *)deviceTokenData;

/** @name Properties */

/// The device type for the WYInstallation.
@property (nonatomic, readonly, retain) NSString *deviceType;

/// The installationId for the WYInstallation.
@property (nonatomic, readonly, retain) NSString *installationId;

/// The device token for the WYInstallation.
@property (nonatomic, retain) NSString *deviceToken;

/// The badge for the WYInstallation.
@property (nonatomic, assign) NSInteger badge;

/// The timeZone for the WYInstallation.
@property (nonatomic, readonly, retain) NSString *timeZone;

/// The channels for the WYInstallation.
@property (nonatomic, retain) NSArray *channels;
@end
