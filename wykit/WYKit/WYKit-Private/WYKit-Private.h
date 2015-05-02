//
//  WYKit-Private.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/21/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYKit.h"

#define WYSynthesize(x) @synthesize x = _##x;

@interface WYKit()

+(dispatch_queue_t)queue;
+ (void)registerWYObjectSubclass:(Class)subClass className:(NSString*)className;
+(Class)wyObjectSubclassWithClassName:(NSString*)className;
+ (NSURL *)endpointForMethod:(NSString *)method;
+ (NSURL *)endpointForMethod:(NSString *)method objectId:(NSString*)objectId;

@end