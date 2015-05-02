//
//  DKNetworkActivity.m
//  DataKit
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import "WYNetworkActivity.h"

#import <UIKit/UIKit.h>
#import <libkern/OSAtomic.h>


@implementation WYNetworkActivity

static int32_t kWYNetworkActivityCount = 0;

+ (void)updateNetworkActivityStatus {
  [UIApplication sharedApplication].networkActivityIndicatorVisible = (kWYNetworkActivityCount > 0);
}

+ (void)begin {
  OSAtomicIncrement32(&kWYNetworkActivityCount);
  [self updateNetworkActivityStatus];
}

+ (void)end {
  OSAtomicDecrement32(&kWYNetworkActivityCount);

  // Delay update a little to avoid flickering
  double delayInSeconds = 0.2;
  dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, delayInSeconds * NSEC_PER_SEC);
  dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
    [self updateNetworkActivityStatus];
  });
}

+ (NSInteger)activityCount {
  return kWYNetworkActivityCount;
}

@end
