//
//  DKNetworkActivity.h
//  DataKit
//
//  Created by Erik Aigner on 10.04.12.
//  Copyright (c) 2012 chocomoko.com. All rights reserved.
//

#import <Foundation/Foundation.h>


/**
 Helper class for displaying the network activity indicator
 */
@interface WYNetworkActivity : NSObject

/**
 Begin a network activity.

 Must be balanced with <end>.
 */
+ (void)begin;

/**
 End a network activity.

 Must be balanced with <begin>.
 */
+ (void)end;

/**
 Returns the number of current network activities
 @return The number of current network activities
 */
+ (NSInteger)activityCount;

@end
