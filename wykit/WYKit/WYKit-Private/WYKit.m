//
//  WYKit.m
//  Whirl
//
//  Created by Zhong Fanglin on 9/19/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYKit.h"
#import "WYKit-Private.h"
#import "WYUser.h"
#import "WYInstallation.h"

static NSString *kWYKitClientKey;
static NSString *kWYKitApplicationEndpoint;
//static AFNetworkReachabilityManager *networkReachabilityManager;

@implementation WYKit

+ (void)setApplicationEndpoint:(NSString *)endpoint clientKey:(NSString *)clientKey {
    NSURL *ep = [NSURL URLWithString:endpoint];
    if (![ep.scheme isEqualToString:@"https"]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            NSLog(@"\n\nWARNING: WYKit API endpoint not secured! "
                  "It's highly recommended to use SSL (current scheme is '%@')\n\n",
                  ep.scheme);
        });
        
    }
    kWYKitApplicationEndpoint = [endpoint copy];
    kWYKitClientKey = [clientKey copy];
    /*
    if (networkReachabilityManager) {
        [networkReachabilityManager stopMonitoring];
        networkReachabilityManager = nil;
    }
    networkReachabilityManager = [AFNetworkReachabilityManager managerForDomain:endpoint];
    [networkReachabilityManager setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        NSLog(@"status = %d",status);
    }];
    [networkReachabilityManager startMonitoring];
    */
}

+ (NSString *)getApplicationEndpoint {
    if (kWYKitApplicationEndpoint.length == 0) {
        [NSException raise:NSInternalInconsistencyException format:@"No API endpoint specified"];
        return nil;
    }
    return kWYKitApplicationEndpoint;
}

+ (NSString*)getApplicationEndpointDomain {
    NSURL *url = [NSURL URLWithString:[self getApplicationEndpoint]];
    return [url host];
}

+ (NSString *)getClientKey {
    if (kWYKitClientKey.length == 0) {
        [NSException raise:NSInternalInconsistencyException format:@"No client key specified"];
        return nil;
    }
    return kWYKitClientKey;
}

// subclass manager
+(NSMutableDictionary*)subclassMap {
    static NSMutableDictionary *map;
    static dispatch_once_t onecT;
    dispatch_once(&onecT, ^{
        map = [[NSMutableDictionary alloc] init];
    });
    return map;
}
+ (void)registerWYObjectSubclass:(Class)subClass className:(NSString*)className {
    [self subclassMap][className] = subClass;
}

+(Class)wyObjectSubclassWithClassName:(NSString*)className {
    if ([self subclassMap][className]) {
        return [self subclassMap][className];
    }
    if ([className isEqualToString:[WYUser wyClassName]]) {
        return [WYUser class];
    } else if([className isEqualToString:[WYInstallation wyClassName]]) {
        return [WYInstallation class];
    } else {
        return [WYObject class];
    }
}

+(dispatch_queue_t)queue {
    /*
    static dispatch_queue_t queue;
    static dispatch_once_t onecT;
    dispatch_once(&onecT, ^{
        queue = dispatch_queue_create("WYKit queue", DISPATCH_QUEUE_SERIAL);
    });
    return queue;
    */
    return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
}

// private method
+ (NSURL *)endpointForMethod:(NSString *)method {
    NSString *ep = [[self getApplicationEndpoint] stringByAppendingPathComponent:method];
    return [NSURL URLWithString:ep];
}

+ (NSURL *)endpointForMethod:(NSString *)method objectId:(NSString*)objectId {
    NSString *ep = [[[self getApplicationEndpoint] stringByAppendingPathComponent:method] stringByAppendingPathComponent:objectId];
    return [NSURL URLWithString:ep];
}

@end