//
//  WYConstants.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/19/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#ifndef WYConstants_h
#define WYConstants_h

@class WYObject;
@class WYUser;

// Cache policies
typedef enum {
    kWYCachePolicyIgnoreCache = 0, //The query does not load from the cache or save results to the cache. kWYCachePolicyIgnoreCache is the default cache policy.
    kWYCachePolicyCacheOnly, // The query only loads from the cache, ignoring the network. If there are no cached results, that causes a NSError.
    kWYCachePolicyNetworkOnly, // The query does not load from the cache, but it will save results to the cache.
    kWYCachePolicyCacheElseNetwork, //The query first tries to load from the cache, but if that fails, it loads results from the network. If neither cache nor network succeed, there is a NSError.
    kWYCachePolicyNetworkElseCache, //The query first tries to load from the network, but if that fails, it loads results from the cache. If neither network nor cache succeed, there is a NSError.
    kWYCachePolicyCacheThenNetwork //The query first loads from the cache, then loads from the network. In this case, the callback will actually be called twice - first with the cached results, then with the network results. Since it returns two results at different times, this cache policy cannot be used synchronously with findObjects. 
} WYCachePolicy;

typedef void (^WYBooleanResultBlock)(BOOL succeeded, NSError *error);
typedef void (^WYIntegerResultBlock)(NSInteger number, NSError *error);
typedef void (^WYArrayResultBlock)(NSArray *objects, NSError *error);
typedef void (^WYObjectResultBlock)(WYObject *object, NSError *error);
typedef void (^WYSetResultBlock)(NSSet *channels, NSError *error);
typedef void (^WYUserResultBlock)(WYUser *user, NSError *error);
typedef void (^WYDataResultBlock)(NSData *data, NSError *error);
typedef void (^WYDataStreamResultBlock)(NSInputStream *stream, NSError *error);
typedef void (^WYStringResultBlock)(NSString *string, NSError *error);
typedef void (^WYIdResultBlock)(id object, NSError *error);
typedef void (^WYProgressBlock)(int percentDone);

enum {
    WYRegexOptionCaseInsensitive = (1 << 0),
    WYRegexOptionMultiline = (1 << 1),
    WYRegexOptionDotall = (1 << 2)
};
typedef NSInteger WYRegexOption;


#endif
