//
//  WYQuery.m
//  Whirl
//
//  Created by Zhong Fanglin on 9/21/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYQuery.h"
#import "OrderedDictionary.h"
#import "WYKit-Private.h"
#import "WYConstants-Private.h"
#import "WYNetworkActivity.h"
#import "WYObject-Private.h"
#import "WYGeoPoint-Private.h"
#import "EGOCache.h"
#import "WYUser.h"


@interface WYQuery()
@property(nonatomic,retain) OrderedDictionary *query;
@property(nonatomic,retain) NSMutableArray *orQuerys;
@property(nonatomic,retain) NSSortDescriptor *sortDescriptor;
@property(nonatomic,retain) NSArray *sortDescriptors;
@property(nonatomic,retain) NSDictionary *notInQuery;
@property(nonatomic,retain) NSDictionary *inQuery;
@property(nonatomic,retain) NSURLSessionDataTask *task;
-(OrderedDictionary*)queryBody;

@end

@implementation WYQuery

+ (WYQuery *)queryWithClassName:(NSString *)className {
    return [[WYQuery alloc] initWithClassName:className];
}

- (id)initWithClassName:(NSString *)newClassName {
    self = [super init];
    if (self) {
        _wyClassName = newClassName;
        _query = [[OrderedDictionary alloc] init];
        _orQuerys = [[NSMutableArray alloc] init];
        _limit = -1;
        _skip = -1;
        _maxCacheAge = -1;
    }
    return self;
}


- (void)includeKey:(NSString *)key {
    NSMutableDictionary *fields = _query[@"$includes"];
    if (fields == nil) {
        fields = [[NSMutableDictionary alloc] init];
        _query[@"$includes"] = fields;
    }
    fields[key] = @1;
}

- (void)selectKeys:(NSArray *)keys {
    NSMutableDictionary *fields = [[NSMutableDictionary alloc] init];
    for (NSString *key in keys) {
        fields[key] = @1;
    }
    _query[@"$fields"] = fields;
}

- (void)whereKeyExists:(NSString *)key {
    [self commendsWithKey:key][@"$exists"] = @1;
}

- (void)whereKeyDoesNotExist:(NSString *)key {
    [self commendsWithKey:key][@"$exists"] = @0;
}

- (void)whereKey:(NSString *)key equalTo:(id)object {
    if (object == nil) {
        return;
    }
    if ([object isKindOfClass:[WYFile class]]) {
        WYFile *file = (WYFile*)object;
        NSString *typeKey = [NSString stringWithFormat:@"%@.__type",key];
        NSString *nameKey = [NSString stringWithFormat:@"%@.name",key];
        _query[typeKey] = @"File";
        _query[nameKey] = file.name;
    } else if([object isKindOfClass:[WYObject class]]) {
        WYObject *wyObject = (WYObject*)object;
        NSString *typeKey = [NSString stringWithFormat:@"%@.__type",key];
        NSString *classKey = [NSString stringWithFormat:@"%@.className",key];
        NSString *idKey = [NSString stringWithFormat:@"%@.id",key];
        _query[typeKey] = @"Pointer";
        _query[classKey] = wyObject.wyClassName;
        _query[idKey] = [wyObject objectId];
    } else if([object isKindOfClass:[WYGeoPoint class]]) {
        WYGeoPoint *point = (WYGeoPoint*)object;
        _query[key] = [point toJsonObject];
    } else if([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate*)object;
        _query[key] = [NSNumber numberWithDouble:[date timeIntervalSince1970]*1000.0f];
    }
    else {
        _query[key] = object;
    }
}

- (void)whereKey:(NSString *)key lessThan:(id)object {
    if([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate*)object;
        [self commendsWithKey:key][@"$lt"] = [NSNumber numberWithDouble:[date timeIntervalSince1970]*1000.0f];
    } else {
        [self commendsWithKey:key][@"$lt"] = object;
    }
    
}

- (void)whereKey:(NSString *)key lessThanOrEqualTo:(id)object {
    if([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate*)object;
        [self commendsWithKey:key][@"$lte"] = [NSNumber numberWithDouble:[date timeIntervalSince1970]*1000.0f];
    } else {
        [self commendsWithKey:key][@"$lte"] = object;
    }
    
}

- (void)whereKey:(NSString *)key greaterThan:(id)object {
    if([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate*)object;
        [self commendsWithKey:key][@"$gt"] = [NSNumber numberWithDouble:[date timeIntervalSince1970]*1000.0f];
    } else {
        [self commendsWithKey:key][@"$gt"] = object;
    }
    
}

- (void)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object {
    if([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate*)object;
        [self commendsWithKey:key][@"$gte"] = [NSNumber numberWithDouble:[date timeIntervalSince1970]*1000.0f];
    } else {
        [self commendsWithKey:key][@"$gte"] = object;
    }
}

- (void)whereKey:(NSString *)key notEqualTo:(id)object {
    if([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate*)object;
        [self commendsWithKey:key][@"$ne"] = [NSNumber numberWithDouble:[date timeIntervalSince1970]*1000.0f];
    } else if([object isKindOfClass:[WYObject class]]) {
        
    } else {
        [self commendsWithKey:key][@"$ne"] = object;
    }
}

- (void)whereKey:(NSString *)key containedIn:(NSArray *)array {
    [self commendsWithKey:key][@"$in"] = array;
}

- (void)whereKey:(NSString *)key notContainedIn:(NSArray *)array {
    [self commendsWithKey:key][@"$nin"] = array;
}

- (void)whereKey:(NSString *)key containsAllObjectsInArray:(NSArray *)array {
    [self commendsWithKey:key][@"$all"] = array;
}

- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint {
    [self commendsWithKey:key][@"$nearSphere"] = @{@"$geometry":[geopoint toGeometry]};
}

- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint withinMiles:(double)maxDistance {
    [self commendsWithKey:key][@"$nearSphere"] = @{@"$geometry":[geopoint toGeometry],@"$maxDistance":[NSNumber numberWithDouble:(maxDistance*1609.344)]};
}

- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint withinKilometers:(double)maxDistance {
    [self commendsWithKey:key][@"$nearSphere"] = @{@"$geometry":[geopoint toGeometry],@"$maxDistance":[NSNumber numberWithDouble:(maxDistance*1000.0)]};
}

- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint withinRadians:(double)maxDistance {
    [self commendsWithKey:key][@"$nearSphere"] = @[[NSNumber numberWithDouble:geopoint.latitude],[NSNumber numberWithDouble:geopoint.longitude]];
    [self commendsWithKey:key][@"$maxDistance"] = [NSNumber numberWithDouble:maxDistance];
}

- (void)whereKey:(NSString *)key withinGeoBoxFromSouthwest:(WYGeoPoint *)southwest toNortheast:(WYGeoPoint *)northeast {
    [self commendsWithKey:key][@"$geoWithin"] = @{@"$geometry":
        @{ @"type":@"Polygon",
            @"coordinates":@[@[@[[NSNumber numberWithDouble:southwest.latitude],[NSNumber numberWithDouble:southwest.longitude]],@[[NSNumber numberWithDouble:northeast.latitude],[NSNumber numberWithDouble:northeast.longitude]]]]
         }
                                                  };
}

- (void)whereKey:(NSString *)key matchesRegex:(NSString *)regex {
    [self whereKey:key matchesRegex:regex modifiers:@"i"];
}

- (void)whereKey:(NSString *)key matchesRegex:(NSString *)regex modifiers:(NSString *)modifiers {
    _query[key] = @{ @"$regex": regex, @"$options": modifiers };
}

- (void)whereKey:(NSString *)key matchesRegex:(NSString *)regex options:(WYRegexOption)options {
    NSMutableString *optionString = [NSMutableString new];
    if ((options & WYRegexOptionCaseInsensitive) == WYRegexOptionCaseInsensitive) {
        [optionString appendString:@"i"];
    }
    else if ((options & WYRegexOptionMultiline) == WYRegexOptionMultiline) {
        [optionString appendString:@"m"];
    }
    else if ((options & WYRegexOptionDotall) == WYRegexOptionDotall) {
        [optionString appendString:@"s"];
    }
    _query[key] = @{ @"$regex": regex, @"$options": optionString };
}

- (void)whereKey:(NSString *)key containsString:(NSString *)substring caseInsensitive:(BOOL)caseInsensitive {
    NSString *safeString = [self makeRegexSafeString:substring];
    WYRegexOption opts = WYRegexOptionMultiline;
    if (caseInsensitive) {
        opts |= WYRegexOptionCaseInsensitive;
    }
    [self whereKey:key matchesRegex:safeString options:opts];
}

- (void)whereKey:(NSString *)key hasPrefix:(NSString *)prefix {
    NSString *safeString = [self makeRegexSafeString:prefix];
    NSString *regex = [NSString stringWithFormat:@"^%@", safeString];
    [self whereKey:key matchesRegex:regex];
}

- (void)whereKey:(NSString *)key hasSuffix:(NSString *)suffix {
    NSString *safeString = [self makeRegexSafeString:suffix];
    NSString *regex = [NSString stringWithFormat:@"%@$", safeString];
    [self whereKey:key matchesRegex:regex];
}

- (void)cancel {
    if (_task) {
        [_task cancel];
    }
    
}



/** @name Getting all Matches for a Query */
- (NSArray *)findObjects {
    return [self findObjects:NULL];
}

- (NSArray *)findObjects:(NSError **)error {
    return [self findObjects:error first:NO];
}

- (NSArray *)findObjects:(NSError **)error first:(BOOL)first {
    NSError *jsonError = nil;
    OrderedDictionary *qBody = [self queryBody];
    if (first) {
        qBody[@"$limit"] = @1;
    } else if(_limit != -1) {
        qBody[@"$limit"] = [NSNumber numberWithInteger: _limit];
    }
    
    if (_skip != -1) {
        qBody[@"$skip"] = [NSNumber numberWithInteger: _skip];
    }
    NSData *body = [NSJSONSerialization dataWithJSONObject:qBody options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return nil;
    }
    
    NSString *queryString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
//    NSLog(@"queryString = %@",queryString);
    NSData *result;
    NSError *requestError = nil;
    switch (_cachePolicy) {
        case kWYCachePolicyCacheThenNetwork:
        case kWYCachePolicyIgnoreCache:
        {
            result = [self requestDataViaNetworkWithQueryString:queryString error:&requestError];
            break;
        }
        case kWYCachePolicyCacheOnly:
        {
            result = [[EGOCache globalCache] dataForKey:[self cacheIdWithQueryString:queryString]];
            requestError = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Cache didn't exists", @"")}];
            break;
        }
        case kWYCachePolicyNetworkOnly:
        {
            result = [self requestDataViaNetworkWithQueryString:queryString error:&requestError];
            if (requestError == nil && result != nil) {
                if (_maxCacheAge != -1) {
                    [[EGOCache globalCache] setData:result forKey:[self cacheIdWithQueryString:queryString] withTimeoutInterval:_maxCacheAge];
                } else {
                    [[EGOCache globalCache] setData:result forKey:[self cacheIdWithQueryString:queryString]];
                }
            }
            break;
        }
        case kWYCachePolicyCacheElseNetwork:
        {
            result = [[EGOCache globalCache] dataForKey:[self cacheIdWithQueryString:queryString]];
            if (result == nil) {
                result = [self requestDataViaNetworkWithQueryString:queryString error:&requestError];
            }
            break;
        }
        case kWYCachePolicyNetworkElseCache:
        {
            result = [self requestDataViaNetworkWithQueryString:queryString error:&requestError];
            if (requestError || result == nil) {
                requestError = nil;
                result = [[EGOCache globalCache] dataForKey:[self cacheIdWithQueryString:queryString]];
            }
            break;
        }
    }
    
    if(requestError || result == nil) {
        if (error != NULL) {
            *error = requestError;
        }
        return nil;
    }
    
    
    
    jsonError = nil;
    id resultJSONObject = nil;
    if(result.length > 0) {
        resultJSONObject = [NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonError];
    }
    
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return nil;
    }
    
    id parseResponse = [WYObject parseReponse:resultJSONObject];
    
    if ([parseResponse isKindOfClass:[NSArray class]]) {
        NSMutableArray *results = [[NSMutableArray alloc] init];
        NSString *className = _wyClassName;
        Class class;
        if (className) {
            class = [WYKit wyObjectSubclassWithClassName:className];
        } else {
            class = [WYObject class];
        }
        for (NSDictionary *resultMap in parseResponse) {
            WYObject *instance = [[class alloc] init];
            [instance setResultMap:resultMap];
            [results addObject:instance];
        }
        if (_sortDescriptor) {
            results = [[results sortedArrayUsingDescriptors:@[_sortDescriptor]] mutableCopy];
        }
        if (_sortDescriptors) {
            results = [[results sortedArrayUsingDescriptors:_sortDescriptors] mutableCopy];
        }
        return results;
    }
    
    return @[];
}

-(NSString*)cacheIdWithQueryString:(NSString*)queryString {
    NSMutableString *cacheId = [[NSMutableString alloc] initWithString:_wyClassName];
    if (queryString && queryString.length > 0) {
        [cacheId appendString:queryString];
    }
    if (_sortDescriptor) {
        [cacheId appendString:[_sortDescriptor description]];
    }
    if (_sortDescriptors && _sortDescriptors.count > 0) {
        for (id desc in _sortDescriptors) {
            [cacheId appendString:[desc description]];
        }
    }
    NSCharacterSet* illegalFileNameCharacters = [NSCharacterSet characterSetWithCharactersInString:@"/\\?%*|\"<>"];
    return [[[NSString stringWithFormat:@"%@",[NSNumber numberWithInteger:[cacheId hash]]] componentsSeparatedByCharactersInSet:illegalFileNameCharacters] componentsJoinedByString:@""];
}


- (void)findObjectsInBackgroundWithBlock:(WYArrayResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        NSArray *results = [self findObjects:&error];
        if (error && error.code == -999) {
            return;
        }
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(results,error);
            });
        }
    });
}

- (WYObject *)getFirstObject {
    return [self getFirstObject:NULL];
}

- (WYObject *)getFirstObject:(NSError **)error {
    NSArray *results = [self findObjects:error first:YES];
    if (results != nil && results.count > 0) {
        return results[0];
    } else {
        return nil;
    }
}

- (void)getFirstObjectInBackgroundWithBlock:(WYObjectResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        WYObject *object = [self getFirstObject:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(object,error);
            });
        }
    });
}

+ (WYQuery *)orQueryWithSubqueries:(NSArray *)queries {
    if ([queries count] == 0) {
        return nil;
    }
    WYQuery *firstQuery = queries[0];
    NSString *queryClassName = firstQuery.wyClassName;
    // valiate the query class is same
    for (int index = 1; index<queries.count; index++) {
        WYQuery *wyQuery = queries[index];
        if (![wyQuery.wyClassName isEqualToString:queryClassName]) {
            [NSException raise:NSInvalidArgumentException format:@"Query class didn't same"];
            return nil;
        }
    }
    WYQuery *orQuery = [WYQuery queryWithClassName:queryClassName];
    orQuery.orQuerys = [queries mutableCopy];
    return orQuery;
}

// $inQuery
- (void)whereKey:(NSString *)key matchesKey:(NSString *)otherKey inQuery:(WYQuery *)query {
    if (query == self) {
        return;
    }
    _inQuery = @{@"key":key,@"otherKey":otherKey,@"query":query};
}

// $notInQuery
- (void)whereKey:(NSString *)key doesNotMatchKey:(NSString *)otherKey inQuery:(WYQuery *)query {
    if (query == self) {
        return;
    }
    _notInQuery = @{@"key":key,@"otherKey":otherKey,@"query":query};
}

- (void)whereKey:(NSString *)key matchesQuery:(WYQuery *)query {
    [self whereKey:key matchesKey:@"id" inQuery:query];
}

- (void)whereKey:(NSString *)key doesNotMatchQuery:(WYQuery *)query {
    [self whereKey:key doesNotMatchKey:@"id" inQuery:query];
}

- (void)orderByAscending:(NSString *)key {
    OrderedDictionary *orderCommand = [[OrderedDictionary alloc] init];
    [orderCommand setObject:@1 forKey:key];
    _query[@"$sort"] = orderCommand;
}

- (void)addAscendingOrder:(NSString *)key {
    [[self commendsWithKey:@"$sort"] insertObject:@1 forKey:key atIndex:0];
}

- (void)orderByDescending:(NSString *)key {
    OrderedDictionary *orderCommand = [[OrderedDictionary alloc] init];
    [orderCommand setObject:@-1 forKey:key];
    _query[@"$sort"] = orderCommand;
}

- (void)addDescendingOrder:(NSString *)key {
    [[self commendsWithKey:@"$sort"] insertObject:@-1 forKey:key atIndex:0];
}

- (void)orderBySortDescriptor:(NSSortDescriptor *)sortDescriptor {
    _sortDescriptor = sortDescriptor;
}

- (void)orderBySortDescriptors:(NSArray *)sortDescriptors {
    _sortDescriptors = sortDescriptors;
}

+ (WYObject *)getObjectOfClass:(NSString *)objectClass
                      objectId:(NSString *)objectId {
    return [self getObjectOfClass:objectClass objectId:objectId error:NULL];
}

+ (WYObject *)getObjectOfClass:(NSString *)objectClass
                      objectId:(NSString *)objectId
                         error:(NSError **)error {
    WYObject *object = [WYObject objectWithoutDataWithClassName:objectClass objectId:objectId];
    [object fetch:error];
    return object;
}

- (WYObject *)getObjectWithId:(NSString *)objectId {
    return [self getObjectWithId:objectId error:NULL];
}

- (WYObject *)getObjectWithId:(NSString *)objectId error:(NSError **)error {
    WYObject *object = [WYObject objectWithoutDataWithClassName:_wyClassName objectId:objectId];
    [object fetch:error];
    return object;
}

- (void)getObjectInBackgroundWithId:(NSString *)objectId
                              block:(WYObjectResultBlock)block {
    WYObject *object = [WYObject objectWithoutDataWithClassName:_wyClassName objectId:objectId];
    [object fetchInBackgroundWithBlock:block];
}

+ (WYUser *)getUserObjectWithId:(NSString *)objectId {
    return [self getUserObjectWithId:objectId error:NULL];
}

+ (WYUser *)getUserObjectWithId:(NSString *)objectId
                          error:(NSError **)error {
    WYUser *user = [WYUser objectWithoutDataWithObjectId:objectId];
    NSError *fError = nil;
    [user fetch:&fError];
    if(fError && error != NULL) {
        *error = fError;
    }
    return user;
}

- (NSInteger)countObjects {
    return [self countObjects:NULL];
}

- (NSInteger)countObjects:(NSError **)error {
    NSError *jsonError = nil;
    OrderedDictionary *qBody = [self queryBody];
    [qBody removeObjectForKey:@"$sort"];
    [qBody removeObjectForKey:@"$limit"];
    [qBody removeObjectForKey:@"$skip"];
    qBody[@"id"] = @"count";
    
    NSData *body = [NSJSONSerialization dataWithJSONObject:qBody options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return 0;
    }
    
    NSString *queryString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
//    NSLog(@"queryString = %@",queryString);
    
    NSString *queryUrl = [NSString stringWithFormat:@"%@?%@",[[WYKit endpointForMethod:_wyClassName] absoluteString],[queryString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    
    NSURL *url = [NSURL URLWithString:queryUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"GET";
    [request setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];
    
    [WYNetworkActivity begin];
    
    NSError *requestError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    [WYNetworkActivity end];
    
    jsonError = nil;
    id resultJSONObject = nil;
    if(result.length > 0) {
        resultJSONObject = [NSJSONSerialization JSONObjectWithData:result options:0 error:&jsonError];
    }
    
    if(requestError) {
        if (error != NULL) {
            if(resultJSONObject) {
                *error = [NSError errorWithDomain:@"WYKit" code:response.statusCode userInfo:resultJSONObject[@"errors"]];
            } else {
                *error = requestError;
            }
        }
        return 0;
    }
    
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return 0;
    }
    
    if (response.statusCode != 200) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:response.statusCode userInfo:resultJSONObject[@"errors"]];
        }
        return 0;
    }
    
    if (resultJSONObject[@"count"]) {
        return [resultJSONObject[@"count"] integerValue];
    } else {
        if (error!=NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Bad response", @"")}];
        }
        return 0;
    }
}

- (void)countObjectsInBackgroundWithBlock:(WYIntegerResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        NSInteger count = [self countObjects:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(count,error);
            });
        }
    });
}

-(void)setLimit:(NSInteger)limit {
    _limit = limit;
}

-(void)setSkip:(NSInteger)skip {
    _skip = skip;
}

- (BOOL)hasCachedResult {
    OrderedDictionary *qBody = [self queryBody];
    if (_skip != -1) {
        qBody[@"$skip"] = [NSNumber numberWithInteger: _skip];
    }
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:qBody options:0 error:&jsonError];
    if (jsonError) {
        return NO;
    }
    
    NSString *queryString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    return [[EGOCache globalCache] hasCacheForKey:[self cacheIdWithQueryString:queryString]];
}

- (void)clearCachedResult {
    OrderedDictionary *qBody = [self queryBody];
    if (_skip != -1) {
        qBody[@"$skip"] = [NSNumber numberWithInteger: _skip];
    }
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:qBody options:0 error:&jsonError];
    if (jsonError) {
        return;
    }
    
    NSString *queryString = [[NSString alloc] initWithData:body encoding:NSUTF8StringEncoding];
    return [[EGOCache globalCache] removeCacheForKey:queryString];
}

//private methods

-(OrderedDictionary*)queryBody {
    
    if (_notInQuery) {
        WYQuery *query = _notInQuery[@"query"];
        NSString *key = _notInQuery[@"key"];
        NSString *otherKey = _notInQuery[@"otherKey"];
        [self commendsWithKey:key][@"$notInQuery"] = @{@"key":otherKey,@"query":[query queryBody],@"className":query.wyClassName};
    }
    
    if (_inQuery) {
        WYQuery *query = _inQuery[@"query"];
        NSString *key = _inQuery[@"key"];
        NSString *otherKey = _inQuery[@"otherKey"];
        [self commendsWithKey:key][@"$inQuery"] = @{@"key":otherKey,@"query":[query queryBody],@"className":query.wyClassName};
    }
    
    OrderedDictionary *query = [_query copy];
    
    for (NSString *key in [query allKeys]) {
        id val = query[key];
        if ([val isKindOfClass:[NSDate class]]) {
            NSDate *date = (NSDate*)val;
            query[key] = [NSNumber numberWithDouble:[date timeIntervalSince1970]];
        }
    }
    
    OrderedDictionary *qBody = nil;
    if (self.orQuerys && self.orQuerys.count > 0) {
        qBody = [[OrderedDictionary alloc] init];
        NSMutableArray *orQuerys = [[NSMutableArray alloc] init];
        if (_query.count > 0) {
            [orQuerys addObject:query];
        }
        for(WYQuery *wyQuery in self.orQuerys) {
            [orQuerys addObject:[wyQuery queryBody]];
        }
        qBody[@"$or"] = orQuerys;
    } else {
        qBody = query;
    }
    return qBody;
}

-(OrderedDictionary*)commendsWithKey:(NSString*)key {
    OrderedDictionary *commands = _query[key];
    if (commands == nil) {
        commands = [[OrderedDictionary alloc] init];
        _query[key] = commands;
    }
    return commands;
}

- (NSString *)makeRegexSafeString:(NSString *)string {
    // There are 11 special regex characters we need to escape!
    // 1: the opening square bracket [
    // 2: the backslash \
    // 3: the caret ^
    // 4: the dollar sign $
    // 5: the period or dot .
    // 6: the vertical bar or pipe symbol |
    // 7: the question mark ?
    // 8: the asterisk or star *
    // 9: the plus sign +
    // 10: the opening round bracket (
    // 11: and the closing round bracket )
    CFStringRef strIn = (__bridge CFStringRef)string;
    CFMutableStringRef accu = CFStringCreateMutable(NULL, string.length * 2);
    
    for (NSUInteger loc=0; loc<string.length; loc++) {
        unichar c =  CFStringGetCharacterAtIndex(strIn, loc);
        BOOL escape = NO;
        switch (c) {
            case '[':
            case '\\':
            case '^':
            case '$':
            case '.':
            case '|':
            case '?':
            case '*':
            case '+':
            case '(':
            case ')': escape = YES; break;
        }
        if (escape) {
            CFStringAppend(accu, CFSTR("\\"));
        }
        CFStringRef s = CFStringCreateWithCharacters(NULL, &c, 1);
        CFStringAppend(accu, s);
        CFRelease(s);
    };
    
    return CFBridgingRelease(accu);
}

-(NSData*)requestDataViaNetworkWithQueryString:(NSString*)queryString
                                         error:(NSError**)error {
    NSString *queryUrl = [NSString stringWithFormat:@"%@?%@",[[WYKit endpointForMethod:_wyClassName] absoluteString],[queryString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    
    NSURL *url = [NSURL URLWithString:queryUrl];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"GET";
    [request setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];
    
    [WYNetworkActivity begin];
    NSURLSession *session = [NSURLSession sharedSession];
    __block NSData *result = nil;
     dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    _task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *requestError) {
        result = data;
        if (requestError != nil) {
            if (error != NULL) {
                *error = requestError;
            }
        }
        
        
        dispatch_semaphore_signal(semaphore);
    }];
    [_task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    [WYNetworkActivity end];
    return result;
}

-(BOOL)requesting {
    return _task && _task.state == NSURLSessionTaskStateRunning;
}


@end
