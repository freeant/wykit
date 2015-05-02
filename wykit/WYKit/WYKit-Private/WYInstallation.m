//
//  WYInstallation.m
//  Whirl
//
//  Created by Zhong Fanglin on 9/28/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYInstallation.h"
#import "WYObject+Subclass.h"
#import "WYQuery.h"
#import "EGOCache.h"
#import "AutoCoding.h"
#import "WYObject-Private.h"
#import "WYConstants-Private.h"


static WYInstallation* currentInstallation = nil;

@implementation WYInstallation
@dynamic  deviceType;
@dynamic installationId;
@dynamic deviceToken;
@dynamic badge;
@dynamic timeZone;
@dynamic channels;


+ (NSString *)wyClassName {
    return @"installation";
}

+ (WYQuery *)query {
    return [WYQuery queryWithClassName:[self wyClassName]];
}

-(void)dealloc {
    
}

+ (instancetype)currentInstallation {
    if (currentInstallation) {
        return currentInstallation;
    }
    WYInstallation *installation = (WYInstallation*)[[EGOCache globalCache] objectForKey:kCurrentInstallationCacheId];
    if (installation == nil) {
        installation = [WYInstallation object];
        installation[@"deviceType"] = @"ios";
        installation.badge = 0;
    }
    UIDevice *device = [UIDevice currentDevice];
    NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
    if (![installation[@"installationId"] isEqualToString:currentDeviceId]) {
        installation[@"installationId"] = currentDeviceId;
    }
    
    if (![installation[@"timeZone"] isEqualToString:[NSTimeZone localTimeZone].name]) {
        installation[@"timeZone"] = [NSTimeZone localTimeZone].name;
    }
    
    if (![installation[@"appIdentifier"] isEqualToString:[[NSBundle mainBundle] bundleIdentifier]]) {
        installation[@"appIdentifier"] = [[NSBundle mainBundle] bundleIdentifier];
    }
    
    if (![installation[@"appVersion"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"]]) {
        installation[@"appVersion"] = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    }
    
    if (![installation[@"appName"] isEqualToString:[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"]]) {
        installation[@"appName"] = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    
    currentInstallation = installation;
    return currentInstallation;
}

- (void)setDeviceTokenFromData:(NSData *)deviceTokenData {
    NSString *deviceToken = [[deviceTokenData description] stringByReplacingOccurrencesOfString: @"<" withString: @""];
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @">" withString: @""] ;
    deviceToken = [deviceToken stringByReplacingOccurrencesOfString: @" " withString: @""];
//    [self setObject:deviceToken forKey:@"deviceToken"];
    self.deviceToken = deviceToken;
}

- (BOOL)save:(NSError **)error {
    
    if(self == currentInstallation) {
        [[EGOCache globalCache] setObjectSync:self forKey:kCurrentInstallationCacheId withTimeoutInterval:MAXFLOAT];
    }
    
    if (self.objectId.length == 0) {
        WYQuery *query = [WYInstallation query];
        [query whereKey:@"installationId" equalTo:self.installationId];
        NSError *error = nil;
        WYInstallation *oldInstallation = (WYInstallation*)[query getFirstObject:&error];
        if (oldInstallation) {
            [self setObjectId:oldInstallation.objectId];
            if(self == currentInstallation) {
                [[EGOCache globalCache] setObjectSync:self forKey:kCurrentInstallationCacheId withTimeoutInterval:MAXFLOAT];
            }
        }
    }
    
    BOOL success = [super save:error];
    if (success && self == currentInstallation) {
        [[EGOCache globalCache] setObjectSync:self forKey:kCurrentInstallationCacheId withTimeoutInterval:MAXFLOAT];
    } else if(self.objectId && self.objectId.length > 0) {
        [self renewInstallation];
        WYQuery *query = [WYInstallation query];
        [query whereKey:@"installationId" equalTo:self.installationId];
        NSError *queryError = nil;
        WYInstallation *oldInstallation = (WYInstallation*)[query getFirstObject:&queryError];
        if (oldInstallation) {
             [self setObjectId:oldInstallation.objectId];
        }
        success = [super save:error];
        if (success && self == currentInstallation) {
            [[EGOCache globalCache] setObjectSync:self forKey:kCurrentInstallationCacheId withTimeoutInterval:MAXFLOAT];
        }
    }
    return success;
}

-(void)renewInstallation {
    [self removeObjectId];
    self[@"deviceType"] = @"ios";
    self.badge = 0;
    UIDevice *device = [UIDevice currentDevice];
    NSString  *currentDeviceId = [[device identifierForVendor]UUIDString];
    self[@"installationId"] = currentDeviceId;
    self[@"timeZone"] = [NSTimeZone localTimeZone].name;
    self[@"appIdentifier"] = [[NSBundle mainBundle] bundleIdentifier];
    self[@"appVersion"] = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"];
    self[@"appName"] = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    self[@"channels"] = @[@"global",@"messages"];
}

-(void)setObjectId:(NSString *)objectId {
    NSMutableDictionary *newResult =  [[NSMutableDictionary alloc] initWithDictionary:self.resultMap];
    newResult[@"id"] = objectId;
    self.resultMap = newResult;
}

-(void)removeObjectId {
    NSMutableDictionary *newResult =  [[NSMutableDictionary alloc] initWithDictionary:self.resultMap];
    [newResult removeObjectForKey:@"id"];
    self.resultMap = newResult;
}



// private methods

-(void)setBadge:(NSInteger)badge {
    [self setObject:[NSNumber numberWithInteger:badge] forKey:@"badge"];
}

-(NSInteger)badge {
    return [[self objectForKey:@"badge"] integerValue];
}

@end
