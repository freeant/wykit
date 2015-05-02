
//
//  WYObject.m
//  Whirl
//
//  Created by Zhong Fanglin on 9/20/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYObject.h"
#import "WYSubclassing.h"
#import "WYQuery.h"
#import "WYObject+Subclass.h"
#import "WYKit-Private.h"
#import "WYGeoPoint-Private.h"
#import "WYFile-Private.h"
#import "WYConstants-Private.h"
#import "WYNetworkActivity.h"
#import "WYObject-Private.h"
#import "WYKit-Private.h"
#import "WYObject-Private.h"
#import <objc/runtime.h>
#import "EGOCache.h"
#import "AutoCoding.h"

@interface WYObject()<WYSubclassing>
@property(readonly) NSURLSessionDataTask* task;
@end

@implementation WYObject
WYSynthesize(wyClassName)
WYSynthesize(objectId)
WYSynthesize(updatedAt)
WYSynthesize(createdAt)
//WYSynthesize(ACL)
WYSynthesize(setMap)
WYSynthesize(unsetMap)
WYSynthesize(incMap)
WYSynthesize(pushMap)
WYSynthesize(pushAllMap)
WYSynthesize(pullMap)
WYSynthesize(pullAllMap)
WYSynthesize(addToSetMap)
WYSynthesize(resultMap)
WYSynthesize(task)


// WYSubclassing

+(NSString*)wyClassName {
    return @"WYObject";
}

-(id)init {
    return [self initWithClassName:[[self class] wyClassName]];
}

+ (instancetype)object {
    return [self objectWithClassName:[[self class] wyClassName]];
}

+ (instancetype)objectWithoutDataWithObjectId:(NSString *)objectId {
    return [self objectWithoutDataWithClassName:[[self class] wyClassName] objectId:objectId];
}

+ (void)registerSubclass {
    [WYKit registerWYObjectSubclass:[self class] className:[[self class] wyClassName]];
}

+ (WYQuery *)query {
    return [WYQuery queryWithClassName:[[self class] wyClassName]];
}

-(void)dealloc {
    
}

// private method
-(instancetype)initWithWYObject:(WYObject*)anotherObject {
    self = [super init];
    if (self) {
        _wyClassName = anotherObject.wyClassName;
        _setMap = anotherObject.setMap;
        _incMap = anotherObject.incMap;
        _unsetMap = anotherObject.unsetMap;
        _pushMap = anotherObject.pushMap;
        _pushAllMap = anotherObject.pushAllMap;
        _pullMap = anotherObject.pullMap;
        _pullAllMap = anotherObject.pullAllMap;
        _addToSetMap = anotherObject.addToSetMap;
        _resultMap = anotherObject.resultMap;
    }
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    WYObject *copy = [[[self class] allocWithZone:zone] initWithWYObject:self];
    return copy;
}

- (instancetype)initWithClassName:(NSString *)newClassName objectId:(NSString*)objectId{
    self = [self initWithClassName:newClassName];
    if (self) {
        _resultMap = @{@"id":objectId};
    }
    return self;
}

-(instancetype)initWithResultMap:(NSDictionary*)resultMap className:(NSString*)className {
    self = [self initWithClassName:className];
    if (self) {
        _resultMap = resultMap;
    }
    return self;
}


// implements
+ (instancetype)objectWithClassName:(NSString *)className {
    return [[self alloc] initWithClassName:className];
}

+ (instancetype)objectWithoutDataWithClassName:(NSString *)className
                                      objectId:(NSString *)objectId {
    return [[self alloc] initWithClassName:className objectId:objectId];
}

- (id)initWithClassName:(NSString *)newClassName {
    self = [super init];
    if (self) {
        _wyClassName = newClassName;
        _setMap = [[NSMutableDictionary alloc] init];
        _incMap = [[NSMutableDictionary alloc] init];
        _unsetMap = [[NSMutableDictionary alloc] init];
        _pushMap = [[NSMutableDictionary alloc] init];
        _pushAllMap = [[NSMutableDictionary alloc] init];
        _pullMap = [[NSMutableDictionary alloc] init];
        _pullAllMap = [[NSMutableDictionary alloc] init];
        _addToSetMap = [[NSMutableDictionary alloc] init];
        _resultMap = [[NSDictionary alloc] init];
    }
    return self;
}

+ (WYObject *)objectWithClassName:(NSString *)className dictionary:(NSDictionary *)dictionary {
    WYObject *object = [[WYObject alloc] initWithClassName:className];
    object.resultMap = dictionary;
    return object;
}


-(NSString*)objectId {
    return _resultMap[@"id"];
}

-(NSDate*)updatedAt {
    if (_resultMap[@"updatedAt"]) {
        return [NSDate dateWithTimeIntervalSince1970:[_resultMap[@"updatedAt"] doubleValue]/1000.0f];
    }
    return nil;
}

-(NSDate*)createdAt {
    if (_resultMap[@"createdAt"]) {
        return [NSDate dateWithTimeIntervalSince1970:[_resultMap[@"createdAt"] doubleValue]/1000.0f];
    }
    return nil;
}

- (NSArray *)allKeys {
    NSMutableArray *uniqueKeys = [[_resultMap allKeys] mutableCopy];
    for (NSString *key in [_setMap allKeys]) {
        if([uniqueKeys indexOfObject:key] == NSNotFound) {
            [uniqueKeys addObject:key];
        }
    }
    return uniqueKeys;
}

NSString *getPropertyType(objc_property_t property) {
    const char *type = property_getAttributes(property);
    
    NSString *typeString = [NSString stringWithUTF8String:type];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = [attributes objectAtIndex:0];
    const char * rawPropertyType = [typeAttribute UTF8String];
    
    if ([typeAttribute hasPrefix:@"T@"] && [typeAttribute length] > 3)
    {
        NSString * typeClassName = [typeAttribute substringWithRange:NSMakeRange(3, [typeAttribute length]-4)];
        return typeClassName;
    } else if (strcmp(rawPropertyType, @encode(int)) == 0) {
        return @"int";
    } else if(strcmp(rawPropertyType, @encode(float)) == 0) {
        return @"float";
    } else if([typeAttribute isEqualToString:@"TB"]) {
        return @"BOOL";
    }else {
        return @"";
    }
}

- (id)objectForKey:(NSString *)key {
    
    
    id object = _setMap[key];
    if (object == nil) {
        object = _resultMap[key];
    }
    
    objc_property_t theProperty = class_getProperty([WYKit wyObjectSubclassWithClassName:[self wyClassName]], [key UTF8String]);
    if (theProperty) {
        NSString *propertyType = getPropertyType(theProperty);
        if ([object isKindOfClass:[NSNumber class]] && [propertyType isEqualToString:@"NSDate"]) {
            object = [NSDate dateWithTimeIntervalSince1970:[object doubleValue]/1000.0f];
        } 
    }
    
    
    return object;
}

- (void)setObject:(id)object forKey:(NSString *)key {
    
    if (object == nil) {
        [self removeObjectForKey:key];
        return;
    }
    _setMap[key] = object;
    [_unsetMap removeObjectForKey:key];
    
}

- (void)removeObjectForKey:(NSString *)key {
    
    NSMutableDictionary *newResult = [[NSMutableDictionary alloc] initWithDictionary:_resultMap];
    [newResult removeObjectForKey:key];
    _resultMap = newResult;
    _unsetMap[key] = @1;
    [_setMap removeObjectForKey:key];
    [_incMap removeObjectForKey:key];
    [_pushAllMap removeObjectForKey:key];
    [_pushAllMap removeObjectForKey:key];
    [_pullMap removeObjectForKey:key];
    [_pullAllMap removeObjectForKey:key];
    [_addToSetMap removeObjectForKey:key];
}

- (void)addObject:(id)object forKey:(NSString *)key {
    _pushMap[key] = object;
}

- (void)addObjectsFromArray:(NSArray *)objects forKey:(NSString *)key {
    NSMutableArray *list = _pushAllMap[key];
    if (list == nil) {
        list = [objects mutableCopy];
        _pushAllMap[key] = list;
    } else {
        [list addObjectsFromArray:objects];
    }
}

- (void)addUniqueObject:(id)object forKey:(NSString *)key {
    [self addUniqueObjectsFromArray:@[object] forKey:key];
}

- (void)addUniqueObjectsFromArray:(NSArray *)objects forKey:(NSString *)key {
    NSMutableArray *list = _addToSetMap[key];
    if (list == nil) {
        list = [objects mutableCopy];
        _addToSetMap[key] = list;
    } else {
        for (id object in objects) {
            if (![list containsObject:objects]) {
                [list addObject:object];
            }
        }
    }
}

- (void)removeObject:(id)object forKey:(NSString *)key {
    _pullMap[key] = object;
}

- (void)removeObjectsInArray:(NSArray *)objects forKey:(NSString *)key {
    _pullAllMap[key] = objects;
}

- (void)incrementKey:(NSString *)key {
    [self incrementKey:key byAmount:@1];
}

- (void)incrementKey:(NSString *)key byAmount:(NSNumber *)amount {
    _incMap[key] = amount;
}

- (BOOL)save {
    return [self save:NULL];
}

- (BOOL)save:(NSError **)error {
    
    if (_task && _task.state == NSURLSessionTaskStateRunning) {
        [_task cancel];
    }
    
    [self validateAllKeys];
    
    NSMutableDictionary *requestDict = [[NSMutableDictionary alloc] init];
    
    for (NSString *key in [_setMap allKeys]) {
        id val = _setMap[key];
        NSError *cError = nil;
        id cVal = [self convertToRequestObject:val error:&cError];
        if (cError) {
            if (error != NULL) {
                *error = cError;
            }
            return NO;
        }
        if (cVal == nil) {
            continue;
        }
        requestDict[key] = cVal;
    }
    
    // update comments
    if ([self objectId] != nil) {
        requestDict[@"id"] = [self objectId];
        // $unset commands
        for (NSString *key in [_unsetMap allKeys]) {
            requestDict[key] = @{@"$unset":@1};
        }
        
        // $inc commands
        for (NSString *key in [_incMap allKeys]) {
            requestDict[key] = @{@"$inc":_incMap[key]};
        }
        
        // $push commands
        for (NSString *key in _pushMap) {
            id val = _pushMap[key];
            NSError *cError = nil;
            id cVal = [self convertToRequestObject:val error:&cError];
            if (cError) {
                if (error != NULL) {
                    *error = cError;
                }
                return NO;
            }
            requestDict[key] = @{@"$push":cVal};
        }
        
        // $pushAll commands
        for (NSString *key in _pushAllMap) {
            id val = _pushAllMap[key];
            NSError *cError = nil;
            id cVal = [self convertToRequestObject:val error:&cError];
            if (cError) {
                if (error != NULL) {
                    *error = cError;
                }
                return NO;
            }
            requestDict[key] = @{@"$pushAll":cVal};
        }
        
        // $pull commands
        for (NSString *key in _pullMap) {
            id val = _pullMap[key];
            NSError *cError = nil;
            id cVal = [self convertToRequestObject:val error:&cError];
            if (cError) {
                if (error != NULL) {
                    *error = cError;
                }
                return NO;
            }
            requestDict[key] = @{@"$pull":cVal};
        }
        
        // $pullAll commands
        for (NSString *key in _pullAllMap) {
            id val = _pullAllMap[key];
            NSError *cError = nil;
            id cVal = [self convertToRequestObject:val error:&cError];
            if (cError) {
                if (error != NULL) {
                    *error = cError;
                }
                return NO;
            }
            requestDict[key] = @{@"$pullAll":cVal};
        }
        
        // $addToSet commands
        for (NSString *key in _addToSetMap) {
            id val = _addToSetMap[key];
            NSError *cError = nil;
            id cVal = [self convertToRequestObject:val error:&cError];
            if (cError) {
                if (error != NULL) {
                    *error = cError;
                }
                return NO;
            }
            requestDict[key] = @{@"$addToSet":cVal};
        }
    }
    
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return NO;
    }
    
    NSURL *url = [WYKit endpointForMethod:_wyClassName];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    if ([self objectId]) {
        request.HTTPMethod = @"PUT";
    } else {
        request.HTTPMethod = @"POST";
    }
    if (body.length > 0) {
        request.HTTPBody = body;
    }
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];
    
    [WYNetworkActivity begin];
    __block NSError *requestError = nil;
    NSURLSession *session = [NSURLSession sharedSession];
    __block NSData *result = nil;
    NSHTTPURLResponse *response = nil;
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    _task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *rep, NSError *reqError) {
        result = data;
        if (reqError != nil) {
            requestError = reqError;
        }
        
        dispatch_semaphore_signal(semaphore);
    }];
    [_task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    response = (NSHTTPURLResponse*)_task.response;
    [WYNetworkActivity end];
    
    /*
    [WYNetworkActivity begin];
    
     NSError *requestError = nil;
     NSHTTPURLResponse *response = nil;
     NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    
    [WYNetworkActivity end];
    */
    
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
        return NO;
    }
    
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return NO;
    }
    
    if (response.statusCode != 200) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:response.statusCode userInfo:resultJSONObject[@"errors"]];
        }
        return NO;
    }
    
    _setMap = [[NSMutableDictionary alloc] init];
    _unsetMap = [[NSMutableDictionary alloc] init];
    _incMap = [[NSMutableDictionary alloc] init];
    _pushMap = [[NSMutableDictionary alloc] init];
    _pushAllMap = [[NSMutableDictionary alloc] init];
    _pullMap = [[NSMutableDictionary alloc] init];
    _pullAllMap = [[NSMutableDictionary alloc] init];
    _addToSetMap = [[NSMutableDictionary alloc] init];
    
    id parseResponse = [WYObject parseReponse:resultJSONObject];
    if ([parseResponse isKindOfClass:[WYObject class]]) {
        WYObject *resultObject = (WYObject*)parseResponse;
        _resultMap = resultObject.resultMap;
    } else {
        _resultMap = parseResponse;
    }
    
    return YES;
}

- (void)saveInBackground {
    [self saveInBackgroundWithBlock:NULL];
}

- (void)saveInBackgroundWithBlock:(WYBooleanResultBlock)block {
    __weak __typeof(self) weakSelf = self;
    dispatch_async([WYKit queue], ^{
        __strong __typeof(weakSelf) strongSelf = weakSelf;
        NSError *error = nil;
        [strongSelf save:&error];
        if (block && error.code != -999) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    block(NO,error);
                } else {
                    block(YES,nil);
                }
            });
        }
    });
}


-(BOOL)isDirty {
    return (_setMap.count+
            _unsetMap.count+
            _pushMap.count+
            _pushAllMap.count+
            _pullMap.count+
            _pullAllMap.count+
            _addToSetMap.count)>0;
}

-(BOOL)isDirtyForKey:(NSString *)key {
    return (_setMap[key] ||
            _unsetMap[key] ||
            _pushMap[key] ||
            _pushAllMap[key] ||
            _pullMap[key] ||
            _pullAllMap[key] ||
            _addToSetMap[key]
            );
}


// generic getter
BOOL isClassPropertyDynamic(Class theClass, NSString *propertyName)
{
    BOOL isDynamic = NO;
    objc_property_t property = class_getProperty(theClass, [propertyName UTF8String]);
    char *dynamicAttributeValue = property_copyAttributeValue(property, "D");
    if (dynamicAttributeValue != NULL) {
        isDynamic = YES;
        free(dynamicAttributeValue);
    }
    return isDynamic;
}

// generic getter for NSObject
static id propertyIMP(id self, SEL _cmd) {
    return [self objectForKey:NSStringFromSelector(_cmd)];
}


// generic setter for NSObject
static void setPropertyIMP(id self, SEL _cmd, id aValue) {
    
    id value = [aValue copy];
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:value forKey:key];
}

// generic getter for BOOL type B
static BOOL propertyIMP4BOOL(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] boolValue];
}


// generic setter for NSObject, type B
static void setPropertyIMP4BOOL(id self, SEL _cmd, BOOL aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithBool:aValue] forKey:key];
}

// generic getter for  type i
static int propertyIMP4Int(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] intValue];
}


// generic setter for type i i
static void setPropertyIMP4Int(id self, SEL _cmd, int aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithInt:aValue] forKey:key];
}

// generic getter for  type s
static  short propertyIMP4Short(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] shortValue];
}


// generic setter for type s
static void setPropertyIMP4Short(id self, SEL _cmd, short aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithShort:aValue] forKey:key];
}

// generic getter for  type l
static  long propertyIMP4Long(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] longValue];
}


// generic setter for type l
static void setPropertyIMP4Long(id self, SEL _cmd, long aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithLong:aValue] forKey:key];
}

// generic getter for  type q (long long)
static  long long propertyIMP4LongLong(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] longLongValue];
}


// generic setter for type q (long long)
static void setPropertyIMP4LongLong(id self, SEL _cmd, long long aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithLongLong:aValue] forKey:key];
}

// generic getter for  type C（unsigned char）
static  unsigned char propertyIMP4UnsignedChar(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] unsignedCharValue];
}


// generic setter for type C(unsigned char)
static void setPropertyIMP4UnsignedChar(id self, SEL _cmd, unsigned char aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithUnsignedChar:aValue] forKey:key];
}

// generic getter for  type I( unsigned int)
static  unsigned int propertyIMP4UnsignedInt(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] unsignedIntValue];
}


// generic setter for type C(unsigned char)
static void setPropertyIMP4UnsignedInt(id self, SEL _cmd, unsigned int aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithUnsignedInt:aValue] forKey:key];
}

// generic getter for  type S( unsigned short)
static  unsigned short propertyIMP4UnsignedShort(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] unsignedShortValue];
}


// generic setter for type S( unsigned short)
static void setPropertyIMP4UnsignedShort(id self, SEL _cmd, unsigned short aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithUnsignedShort:aValue] forKey:key];
}


// generic getter for  type L( unsigned long)
static  unsigned long propertyIMP4UnsignedLong(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] unsignedLongValue];
}


// generic setter for type L( unsigned long)
static void setPropertyIMP4UnsignedLong(id self, SEL _cmd, unsigned long aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithUnsignedLong:aValue] forKey:key];
}

// generic getter for  type Q( unsigned long long)
static  unsigned long long propertyIMP4UnsignedLongLong(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] unsignedLongLongValue];
}


// generic setter for type Q( unsigned long long)
static void setPropertyIMP4UnsignedLongLong(id self, SEL _cmd, unsigned long long aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithUnsignedLongLong:aValue] forKey:key];
}

// generic getter for  type f( float)
static  float propertyIMP4Float(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] floatValue];
}


// generic setter for type f( float)
static void setPropertyIMP4Float(id self, SEL _cmd, float aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithFloat:aValue] forKey:key];
}

// generic getter for  type d( double)
static  double propertyIMP4Double(id self, SEL _cmd) {
    return [[self objectForKey:NSStringFromSelector(_cmd)] doubleValue];
}


// generic setter for d( double)
static void setPropertyIMP4Double(id self, SEL _cmd, double aValue) {
    
    NSMutableString *key = [NSStringFromSelector(_cmd) mutableCopy];
    
    // delete "set" and ":" and lowercase first letter
    [key deleteCharactersInRange:NSMakeRange(0, 3)];
    [key deleteCharactersInRange:NSMakeRange([key length] - 1, 1)];
    NSString *firstChar = [key substringToIndex:1];
    [key replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
    
    [self setObject:[NSNumber numberWithDouble:aValue] forKey:key];
}




NSString *getPropertyTypeEncoding(objc_property_t property) {
    const char *type = property_getAttributes(property);
    
    NSString *typeString = [NSString stringWithUTF8String:type];
    NSArray *attributes = [typeString componentsSeparatedByString:@","];
    NSString *typeAttribute = [attributes objectAtIndex:0];
    return [typeAttribute substringWithRange:NSMakeRange(1,1)];
}



+ (BOOL)resolveInstanceMethod:(SEL)aSEL {
    if ([NSStringFromSelector(aSEL) hasPrefix:@"set"]) {
        NSMutableString *property = [NSStringFromSelector(aSEL) mutableCopy];
        [property deleteCharactersInRange:NSMakeRange(0, 3)];
        [property deleteCharactersInRange:NSMakeRange([property length] - 1, 1)];
        NSString *firstChar = [property substringToIndex:1];
        [property replaceCharactersInRange:NSMakeRange(0, 1) withString:[firstChar lowercaseString]];
        objc_property_t theProperty = class_getProperty([WYKit wyObjectSubclassWithClassName:[self wyClassName]], [property UTF8String]);
        if (theProperty) {
            NSString *typeEncoding = getPropertyTypeEncoding(theProperty);
            NSString *types = [NSString stringWithFormat:@"v@:%@",typeEncoding];
            if ([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(id)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(BOOL)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4BOOL, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(int)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4Int, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(short)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4Short, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4Long, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(long long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4LongLong, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned char)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4UnsignedChar, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4UnsignedInt, [types UTF8String]);
                    return YES;
                } 
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4UnsignedShort, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4UnsignedLong, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4UnsignedLongLong, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(float)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4Float, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(double)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL, (IMP)setPropertyIMP4Double, [types UTF8String]);
                    return YES;
                }
            } 
            
        } else {
            if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                class_addMethod([self class], aSEL, (IMP)setPropertyIMP, "v@:@");
                return YES;
            }
        }
        
        
    } else {
        NSString *property = NSStringFromSelector(aSEL);
        objc_property_t theProperty = class_getProperty([WYKit wyObjectSubclassWithClassName:[self wyClassName]], [property UTF8String]);
        if (theProperty) {
            NSString *typeEncoding = getPropertyTypeEncoding(theProperty);
            NSString *types = [NSString stringWithFormat:@"%@@:",typeEncoding];
            if ([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(id)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(BOOL)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4BOOL, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(int)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4Int, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(short)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4Short, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4Long, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(long long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4LongLong, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned char)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4UnsignedChar, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned int)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4UnsignedInt, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned short)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4UnsignedShort, [types UTF8String]);
                    return YES;
                } 
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4UnsignedLong, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(unsigned long long)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4UnsignedLongLong, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(float)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4Float, [types UTF8String]);
                    return YES;
                }
            } else if([typeEncoding isEqualToString:[NSString stringWithUTF8String:@encode(double)]]) {
                if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                    class_addMethod([self class], aSEL,(IMP)propertyIMP4Double, [types UTF8String]);
                    return YES;
                }
            }
            
        } else {
            if (isClassPropertyDynamic([WYKit wyObjectSubclassWithClassName:[self wyClassName]],property)) {
                class_addMethod([self class], aSEL,(IMP)propertyIMP, "@@:");
                return YES;
            }
        }
        
    }
    return [super resolveInstanceMethod:aSEL];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:[NSString stringWithFormat:@"%@",key]];
}

- (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key
{
    [self setObject:object forKey:[NSString stringWithFormat:@"%@",key]];
}




// private methods
-(void)validateKeys:(id)obj {
    static NSCharacterSet *forbiddenChars;
    if (forbiddenChars == nil) {
        forbiddenChars = [NSCharacterSet characterSetWithCharactersInString:@"$."];
    }
    if ([obj isKindOfClass:[NSDictionary class]]) {
        for (NSString *key in [obj allKeys]) {
            NSRange range = [key rangeOfCharacterFromSet:forbiddenChars];
            if (range.location != NSNotFound) {
                [NSException raise:NSInvalidArgumentException
                            format:@"Invalid object key '%@'. Keys may not contain '$' or '.'", key];
            }
            id obj2 = [obj objectForKey:key];
            [self validateKeys:obj2];
        }
    }
    else if ([obj isKindOfClass:[NSArray class]]) {
        for (id obj2 in obj) {
            [self validateKeys:obj2];
        }
    }
    return;
}

-(void)validateAllKeys {
    [self validateKeys:_setMap];
    [self validateKeys:_unsetMap];
    [self validateKeys:_incMap];
    [self validateKeys:_pushMap];
    [self validateKeys:_pushAllMap];
    [self validateKeys:_pullMap];
    [self validateKeys:_pullAllMap];
    [self validateKeys:_addToSetMap];
}

-(NSDictionary*)toPointerObject {
    return @{@"__type":@"Pointer",@"className":_wyClassName,@"id":[self objectId]};
}

-(id)convertToRequestObject:(id)object error:(NSError**)error {
    
    if ([object isKindOfClass:[WYGeoPoint class]]) {
        WYGeoPoint *pVal = (WYGeoPoint*)object;
        return [pVal toJsonObject];
    } else if([object isKindOfClass:[WYFile class]]) {
        WYFile *fVal = (WYFile*)object;
        if ([fVal isDirty]) {
            NSError *fError = nil;
            [fVal save:&fError];
            if (fError) {
                if (error != NULL) {
                    *error = fError;
                }
                return nil;
            }
        }
        return [fVal toJsonObject];
    } else if([object isKindOfClass:[WYObject class]]) {
        // it's a pointer object, don't save object already have id
        WYObject *objVal = (WYObject*)object;
        if ([objVal objectId] == nil) {
            NSError *objError = nil;
            [objVal save:&objError];
            if (objError) {
                if (error != NULL) {
                    *error = objError;
                }
                return nil;
            }
        }
        return [objVal toPointerObject];
    } else if([object isKindOfClass:[NSArray class]]){
        NSMutableArray *results = [[NSMutableArray alloc] init];
        for (id val in object) {
            NSError *e = nil;
            id cVal = [self convertToRequestObject:val error:&e];
            if (e) {
                if (error != NULL) {
                    *error = e;
                }
                return nil;
            }
            [results addObject:cVal];
        }
        return results;
    } else if([object isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *results = [[NSMutableDictionary alloc] init];
        for (NSString *key in object) {
            NSError *e = nil;
            id cVal = [self convertToRequestObject:object[key] error:&e];
            if (e) {
                if (error != NULL) {
                    *error = e;
                }
                return nil;
            }
            results[key] = cVal;
        }
        return results;
    } else if([object isKindOfClass:[NSDate class]]) {
        NSDate *date = (NSDate*)object;
        return [NSNumber numberWithDouble:[date timeIntervalSince1970]];
    } else {
        return object;
    }
}

-(void)setResultMap:(NSDictionary*)resultMap {
    _resultMap = resultMap;
}

+(id)parseReponse:(id)response {
    
    if ([response isKindOfClass:[NSArray class]]) {
        
        NSMutableArray *results = [[NSMutableArray alloc] init];
        for (id val in response) {
            [results addObject:[self parseReponse:val]];
        }
        return results;
        
    } else if([response isKindOfClass:[NSDictionary class]]) {
        NSString *type = response[@"__type"];
        if (type) {
            if ([type isEqualToString:@"GeoPoint"]) {
                return [[WYGeoPoint alloc] initWithJsonObject:response];
            } else if([type isEqualToString:@"File"]) {
                return [[WYFile alloc] initWithJsonObject:response];
            } else if([type isEqualToString:@"Pointer"]) {
                NSMutableDictionary *parsedReponse = [[NSMutableDictionary alloc] init];
                for (NSString *key in [response allKeys]) {
                    parsedReponse[key] = [self parseReponse:response[key]];
                }
                
                NSString *className = [response objectForKey:@"className"];
                Class class;
                if (className) {
                    class = [WYKit wyObjectSubclassWithClassName:className];
                }
                if (class) {
                    WYObject *instance = [[class alloc] init];
                    [parsedReponse removeObjectForKey:@"__type"];
                    [parsedReponse removeObjectForKey:@"className"];
                    [instance setResultMap:parsedReponse];
                    return instance;
                } else {
                    return parsedReponse;
                }
            } else {
                NSMutableDictionary *parsedReponse = [[NSMutableDictionary alloc] init];
                for (NSString *key in [response allKeys]) {
                    parsedReponse[key] = [self parseReponse:response[key]];
                }
                return parsedReponse;
            }
        } else {
            NSMutableDictionary *parsedReponse = [[NSMutableDictionary alloc] init];
            for (NSString *key in [response allKeys]) {
                parsedReponse[key] = [self parseReponse:response[key]];
            }
            return parsedReponse;
        }
    } else {
        return response;
    }
}

+ (BOOL)saveAll:(NSArray *)objects {
    return [self saveAll:objects error:NULL];
}

+ (BOOL)saveAll:(NSArray *)objects error:(NSError **)error {
    for (WYObject *object in objects) {
        NSError *sError = nil;
        [object save:&sError];
        if (sError) {
            if (error != NULL) {
                *error = sError;
            }
            return NO;
        }
    }
    return YES;
}

+ (void)saveAllInBackground:(NSArray *)objects {
    [self saveAllInBackground:objects block:NULL];
}

+ (void)saveAllInBackground:(NSArray *)objects
                      block:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        [self saveAll:objects error:&error];
        if (block) {
            if (error) {
                block(NO,error);
            } else {
                block(YES,nil);
            }
        }
    });
}

// delete objects
+ (BOOL)deleteAll:(NSArray *)objects {
    return [self deleteAll:objects error:NULL];
}

+ (BOOL)deleteAll:(NSArray *)objects error:(NSError **)error {
    for (WYObject *object in objects) {
        NSError *dError = nil;
        [object delete:&dError];
        if (dError) {
            if (error != NULL) {
                *error = dError;
            }
            return NO;
        }
    }
    return YES;
}

+ (void)deleteAllInBackground:(NSArray *)objects {
    [self deleteAllInBackground:objects block:NULL];
}

+ (void)deleteAllInBackground:(NSArray *)objects
                        block:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *dError = nil;
        [self deleteAll:objects error:&dError];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (dError) {
                    block(NO,dError);
                } else {
                    block(YES,nil);
                }
            });
        }
    });
}

- (BOOL)isDataAvailable {
    if ([self objectId].length == 0) {
        return NO;
    }
    
    if (_resultMap.count<2) {
        return NO;
    }
    
    return YES;
}

- (void)refresh {
    [self refresh:NULL];
}

- (void)refresh:(NSError **)error {
    if ([self objectId].length == 0) {
        NSError *e = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{@"error":@"no id provide"}];
        if (error!=NULL) {
            *error = e;
        }
    }
    
    NSURL *url = [WYKit endpointForMethod:_wyClassName objectId:[self objectId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"GET";
    [request setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];

    
    [WYNetworkActivity begin];
    
    NSError *requestError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    [WYNetworkActivity end];
    
    NSError *jsonError = nil;
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
        return;
    }
    
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return;
    }
    
    if (response.statusCode != 200) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:response.statusCode userInfo:resultJSONObject[@"errors"]];
        }
        return;
    }
    id parseResponse = [WYObject parseReponse:resultJSONObject];
    if ([parseResponse isKindOfClass:[WYObject class]]) {
        WYObject *resultObject = (WYObject*)parseResponse;
        _resultMap = resultObject.resultMap;
    } else {
        _resultMap = parseResponse;
    }
}

- (void)refreshInBackgroundWithBlock:(WYObjectResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *e = nil;
        [self refresh:&e];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (e) {
                    block(nil,e);
                } else {
                    block(self,nil);
                }
            });
        }
    });
}

- (void)fetch {
    [self fetch:NULL];
}

- (void)fetch:(NSError **)error {
    if ([self isDataAvailable]) {
        return;
    }
    [self refresh:error];
}

- (void)fetchInBackgroundWithBlock {
    [self fetchInBackgroundWithBlock:NULL];
}

- (void)fetchInBackgroundWithBlock:(WYObjectResultBlock)block {
    if ([self isDataAvailable]) {
        if (block) {
            block(self,nil);
        }
    }
    
    [self refreshInBackgroundWithBlock:block];
}

+ (void)fetchAll:(NSArray *)objects {
    [self fetchAll:objects error:NULL];
}

+ (void)fetchAll:(NSArray *)objects error:(NSError **)error {
    for (WYObject *object in objects) {
        NSError *fError = nil;
        [object fetch:&fError];
        if (fError) {
            if (error != NULL) {
                *error = fError;
            }
            
            return;
        }
    }
}

+ (void)fetchAllInBackground:(NSArray *)objects {
    [self fetchAllInBackground:objects block:NULL];
}

+ (void)fetchAllInBackground:(NSArray *)objects
                       block:(WYArrayResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        [self fetchAll:objects error:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error) {
                    block(nil,error);
                } else {
                    block(objects,nil);
                }
            });
        }
        
    });
}

- (BOOL)delete {
    return [self delete:NULL];
}

-(BOOL)delete:(NSError **)error {
    if ([self objectId].length == 0) {
        NSError *e = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{@"error":@"no id provide"}];
        if (error != NULL) {
            *error = e;
        }
        return NO;
    }
    
    NSURL *url = [WYKit endpointForMethod:_wyClassName objectId:[self objectId]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"DELETE";
    [request setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];
    
    
    [WYNetworkActivity begin];
    
    NSError *requestError = nil;
    NSHTTPURLResponse *response = nil;
    [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&requestError];
    [WYNetworkActivity end];
    
    if(requestError) {
        if (error != NULL) {
            *error = requestError;
        }
        return NO;
    }
    
    return YES;
}

- (void)deleteInBackground {
    [self deleteInBackgroundWithBlock:NULL];
}

- (void)deleteInBackgroundWithBlock:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        [self delete:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(error==nil,error);
            });
        }
    });
}



- (id)valueForUndefinedKey:(NSString *)key {
    return [self objectForKey:key];
}

-(void)setValue:(id)value forUndefinedKey:(NSString *)key {
    [self setObject:value forKey:key];
}

-(void)setResultObject:(id)object forKey:(NSString*)key {
    if (object == nil) {
        return;
    }
    NSMutableDictionary *newResult = [[NSMutableDictionary alloc] initWithDictionary:_resultMap];
    [newResult setObject:object forKey:key];
    _resultMap = newResult;
}

-(void)initMaps {
    
}

-(NSArray*)excludeProperties {
    return @[@"task"];
}


@end
