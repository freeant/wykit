//
//  WYUser.m
//  Whirl
//
//  Created by Zhong Fanglin on 9/21/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYUser.h"
#import "WYObject+Subclass.h"
#import "EGOCache.h"
#import "WYObject-Private.h"
#import "WYKit-Private.h"
#import "AutoCoding.h"
#import "WYNetworkActivity.h"
#import "WYConstants-Private.h"

static NSString *const AutocodingException = @"AutocodingException";

static id currentUser = nil;
static dispatch_once_t onceT;

@interface WYUser()

@property(readonly) BOOL isAuthenticated;
+(instancetype)requestCurrentUserFromNetwork:(NSError**)error;
@end

@implementation WYUser
WYSynthesize(isAuthenticated)
WYSynthesize(sessionToken)

@dynamic username;
@dynamic email;
@dynamic password;

+ (NSString *)wyClassName {
    return @"users";
}

+(instancetype)user {
    return [[self class] objectWithClassName:[self wyClassName]];
}

+ (instancetype)currentUser {
    
    dispatch_once(&onceT, ^{
        
        if ([[EGOCache globalCache] hasCacheForKey:kCurrentUserCacheId]) {
            Class userClass = [WYKit wyObjectSubclassWithClassName:[self wyClassName]];
            currentUser = [[userClass alloc] init];
            WYUser *currentUserObj = (WYUser*)currentUser;
            
            WYUser *cachedUserObj = (WYUser*)[[EGOCache globalCache] objectForKey:kCurrentUserCacheId];
            currentUserObj.resultMap = cachedUserObj.resultMap;
            currentUserObj.setMap = cachedUserObj.setMap;
            currentUserObj.incMap = cachedUserObj.incMap;
            currentUserObj.unsetMap = cachedUserObj.unsetMap;
            currentUserObj.pushMap = cachedUserObj.pushMap;
            currentUserObj.pushAllMap = cachedUserObj.pushAllMap;
            currentUserObj.pullMap = cachedUserObj.pullMap;
            currentUserObj.pullAllMap = cachedUserObj.pullAllMap;
            currentUserObj.addToSetMap = cachedUserObj.addToSetMap;
            currentUserObj.sessionToken = cachedUserObj.sessionToken;
            currentUserObj.isAuthenticated = cachedUserObj.isAuthenticated;
            
//            currentUser = (WYUser*)[[EGOCache globalCache] objectForKey:kCurrentUserCacheId];
            if (currentUser != nil) {
                NSMutableDictionary *tokenProperties = [[NSMutableDictionary alloc] init];
                WYUser *user = (WYUser*)currentUser;
                if (user.sessionToken.length == 0) {
                    currentUser = nil;
                } else {
                    [tokenProperties setValue:user.sessionToken forKey:NSHTTPCookieValue];
                    [tokenProperties setValue:@"sid" forKey:NSHTTPCookieName];
                    [tokenProperties setValue:[WYKit getApplicationEndpointDomain] forKey:NSHTTPCookieDomain];
                    [tokenProperties setValue:@"/" forKey:NSHTTPCookiePath];
                    NSHTTPCookie *cookie = [[NSHTTPCookie alloc] initWithProperties:tokenProperties];
                    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookie:cookie];
                }
            }
        }
    });
    return currentUser;
}

+(void)setCurrentUser:(id)user {
    Class userClass = [WYKit wyObjectSubclassWithClassName:[self wyClassName]];
    if (user == currentUser && [user isKindOfClass:userClass]) {
        // just save
        [[EGOCache globalCache] setObject:user forKey:kCurrentUserCacheId withTimeoutInterval:60*60*24*30];
    } else {
        currentUser = [[userClass alloc] init];
        WYUser *currentUserObj = (WYUser*)currentUser;
        
        WYUser *newUser = (WYUser*)user;
        currentUserObj.resultMap = newUser.resultMap;
        currentUserObj.setMap = newUser.setMap;
        currentUserObj.incMap = newUser.incMap;
        currentUserObj.unsetMap = newUser.unsetMap;
        currentUserObj.pushMap = newUser.pushMap;
        currentUserObj.pushAllMap = newUser.pushAllMap;
        currentUserObj.pullMap = newUser.pullMap;
        currentUserObj.pullAllMap = newUser.pullAllMap;
        currentUserObj.addToSetMap = newUser.addToSetMap;
        currentUserObj.sessionToken = newUser.sessionToken;
        currentUserObj.isAuthenticated = newUser.isAuthenticated;
        
        [[EGOCache globalCache] setObject:currentUserObj forKey:kCurrentUserCacheId withTimeoutInterval:60*60*24*30];
    }
    /*
    Class userClass = [WYKit wyObjectSubclassWithClassName:[self wyClassName]];
    currentUser = [[userClass alloc] init];
    WYUser *currentUserObj = (WYUser*)currentUser;
    
    WYUser *cachedUserObj = (WYUser*)[[EGOCache globalCache] objectForKey:kCurrentUserCacheId];
    currentUserObj.resultMap = cachedUserObj.resultMap;
    currentUserObj.setMap = cachedUserObj.setMap;
    currentUserObj.incMap = cachedUserObj.incMap;
    currentUserObj.unsetMap = cachedUserObj.unsetMap;
    currentUserObj.pushMap = cachedUserObj.pushMap;
    currentUserObj.pushAllMap = cachedUserObj.pushAllMap;
    currentUserObj.pullMap = cachedUserObj.pullMap;
    currentUserObj.pullAllMap = cachedUserObj.pullAllMap;
    currentUserObj.addToSetMap = cachedUserObj.addToSetMap;
    currentUserObj.sessionToken = cachedUserObj.sessionToken;
    currentUserObj.isAuthenticated = cachedUserObj.isAuthenticated;
    */
}

- (id)copyWithZone:(NSZone *)zone {
    WYUser *copy = [[[self class] allocWithZone:zone] initWithWYObject:self];
    copy.isAuthenticated = self.isAuthenticated;
    copy.sessionToken = self.sessionToken;
    return copy;
}

-(BOOL)signUp {
    return [self signUp:NULL];
}

-(BOOL)signUp:(NSError **)error {
    
    if (![WYUser isValidEmail:self.email]) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Email is invalid", @"")}];
        }
        return NO;
    }
    
    if (![WYUser isSecurityPassword:self.password error:error]) {
        return NO;
    }
    
    
    NSDictionary *requestDict = @{@"email":self.email,@"password":self.password};
    
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return NO;
    }
    
    NSURL *url = [WYKit endpointForMethod:@"users"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
    
    if (resultJSONObject[@"uid"]) {
        NSError *meError = nil;
        WYUser *me = [WYUser requestCurrentUserFromNetwork:&meError];
        me.sessionToken = resultJSONObject[@"id"];
        if (meError) {
            if (error != NULL) {
                *error = meError;
            }
            return NO;
        }
        if (me) {
            [me setIsAuthenticated:YES];
            
        }
        [WYUser setCurrentUser:me];
        [self setResultMap:me.resultMap];
        [self setIsAuthenticated:YES];
        self.sessionToken = me.sessionToken;
        return YES;
    }
    return NO;
}

- (void)signUpInBackground {
    [self signUpInBackgroundWithBlock:NULL];
}

- (void)signUpInBackgroundWithBlock:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        BOOL success = [self signUp:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(success,error);
            });
        }
        
    });
}

- (BOOL)requestVerificationCodeForPhoneNumber:(NSString *)phoneNumber
                                         type:(VerificationCodeRequestType)type; {
    return [self requestVerificationCodeForPhoneNumber:phoneNumber type:type error:NULL];
}
- (BOOL)requestVerificationCodeForPhoneNumber:(NSString *)phoneNumber
                                         type:(VerificationCodeRequestType)type
                                        error:(NSError**)error {
    
    NSDictionary *requestDict = @{@"mobileNumber":phoneNumber,@"type":type == VerificationCodeRequestTypeCall?@"call":@"sms" };
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return NO;
    }
    
    NSURL *url = [WYKit endpointForMethod:@"users/requestPhoneVerificationCode"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
    return [resultJSONObject[@"status"] isEqualToString:@"OK"];
}

- (void)requestVerificationCodeForPhoneNumberInBackground:(NSString *)phoneNumber
                                                     type:(VerificationCodeRequestType)type {
    [self requestVerificationCodeForPhoneNumberInBackground:phoneNumber type:type block:NULL];
}
- (void)requestVerificationCodeForPhoneNumberInBackground:(NSString *)phoneNumber
                                                     type:(VerificationCodeRequestType)type
                                                    block:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        BOOL result = [self requestVerificationCodeForPhoneNumber:phoneNumber type:type error:&error];;
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(result,error);
            });
        }
    });
}

//verify phone number
- (BOOL)verifyPhoneNumber:(NSString*)phoneNumber
         verificationCode:(NSString*)verificationCode
              countryCode:(NSString*)countryCode {
    return [self verifyPhoneNumber:phoneNumber verificationCode:verificationCode countryCode:countryCode error:NULL];
}

- (BOOL)verifyPhoneNumber:(NSString*)phoneNumber
         verificationCode:(NSString*)verificationCode
              countryCode:(NSString*)countryCode error:(NSError**)error {
    
    NSDictionary *requestDict = @{@"mobileNumber":phoneNumber,@"mobileNumberVerificationCode":verificationCode,@"mobileNumberCountryCode": countryCode};
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return NO;
    }
    
    NSURL *url = [WYKit endpointForMethod:@"users/verifyPhone"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
    
    self.resultMap = [WYObject parseReponse:resultJSONObject];
    return YES;
}

- (void)verifyPhoneNumberInBackground:(NSString*)phoneNumber
                     verificationCode:(NSString*)verificationCode
                          countryCode:(NSString*)countryCode {
    [self verifyPhoneNumberInBackground:phoneNumber verificationCode:verificationCode countryCode:countryCode block:NULL];
}

- (void)verifyPhoneNumberInBackground:(NSString*)phoneNumber
                     verificationCode:(NSString*)verificationCode
                          countryCode:(NSString*)countryCode
                                block:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        BOOL result = [self verifyPhoneNumber:phoneNumber verificationCode:verificationCode countryCode:countryCode error:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(result,error);
            });
        }
    });
}

// change the password
- (BOOL)changePassword:(NSString*)newPassword
       confirmPassword:(NSString*)confirmPassword
       currentPassword:(NSString*)currentPassword {
    return [self changePassword:newPassword confirmPassword:confirmPassword currentPassword:currentPassword error:NULL];
}

- (BOOL)changePassword:(NSString*)newPassword
       confirmPassword:(NSString*)confirmPassword
       currentPassword:(NSString*)currentPassword
                 error:(NSError**)error {
    NSDictionary *requestDict = @{@"newPassword":newPassword,@"newPasswordConfirm":confirmPassword,@"currentPassword":currentPassword };
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return NO;
    }
    
    NSURL *url = [WYKit endpointForMethod:@"users/changePassword"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
    
    return [resultJSONObject[@"status"] isEqualToString:@"OK"];
}

- (void)changePasswordInBackground:(NSString*)newPassword
                   confirmPassword:(NSString*)confirmPassword
                   currentPassword:(NSString*)currentPassword {
    [self changePasswordInBackground:newPassword confirmPassword:confirmPassword currentPassword:currentPassword block:NULL];
}

- (void)changePasswordInBackground:(NSString*)newPassword
                   confirmPassword:(NSString*)confirmPassword
                   currentPassword:(NSString*)currentPassword
                             block:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        BOOL result = [self changePassword:newPassword confirmPassword:confirmPassword currentPassword:currentPassword error:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(result,error);
            });
        }
    });
}

- (BOOL)save:(NSError **)error {
    if (self == currentUser) {
        [WYUser setCurrentUser:self];
    }
    BOOL success = [super save:error];
    if (self == currentUser && success) {
        [WYUser setCurrentUser:self];
    }
    return success;
}

+ (WYQuery *)query {
    return [WYQuery queryWithClassName:[self wyClassName]];
}

// Logging in */

+ (instancetype)logInWithUsername:(NSString *)username
                         password:(NSString *)password {
    return [self logInWithUsername:username password:password error:NULL];
}

+ (instancetype)logInWithUsername:(NSString *)username
                         password:(NSString *)password
                            error:(NSError **)error {
    NSDictionary *requestDict = @{@"username":username,@"password":password};
    
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return nil;
    }
    
    NSURL *url = [WYKit endpointForMethod:@"users/login"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
        return nil;
    }
    
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return nil;
    }
    
    if (response.statusCode != 200) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:response.statusCode userInfo:resultJSONObject[@"errors"]];
        }
        return nil;
    }
    
    if (resultJSONObject[@"uid"]) {
        NSError *meError = nil;
        WYUser *me = [self requestCurrentUserFromNetwork:&meError];
        me.sessionToken = resultJSONObject[@"id"];
        
        if (meError) {
            if (error != NULL) {
                *error = meError;
            }
            return nil;
        }
        if (me) {
            [me setIsAuthenticated:YES];
            [WYUser setCurrentUser:me];
            
        }
        return me;
    }
    
    return nil;
}

+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password {
    [self logInWithUsernameInBackground:username password:password block:NULL];
}

+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                                block:(WYUserResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        WYUser *user = [self logInWithUsername:username password:password error:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(user,error);
            });
        }
    });
}

+ (void)logOut {
    NSURL *url = [WYKit endpointForMethod:@"users/logout"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"POST";
    [request setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];
    [NSURLConnection sendAsynchronousRequest:request queue:[[NSOperationQueue alloc] init] completionHandler:NULL];
    [[EGOCache globalCache] removeCacheForKey:kCurrentUserCacheId];
    currentUser = nil;
    NSHTTPCookieStorage *storage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for(NSHTTPCookie *cookie in [storage cookies])
    {
        if ([cookie.domain isEqualToString:[WYKit getApplicationEndpointDomain]]) {
            [storage deleteCookie:cookie];
        }
    }
    onceT = 0;
}

+ (BOOL) isValidEmail:(NSString *)email
{
    BOOL stricterFilter = NO; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    NSString *stricterFilterString = @"[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}";
    NSString *laxString = @".+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
    /*
    BOOL stricterFilter = YES; // Discussion http://blog.logichigh.com/2010/09/02/validating-an-e-mail-address/
    static NSString *stricterFilterString = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
    static NSString *laxString = @".+@.+\\.[A-Za-z]{2}[A-Za-z]*";
    NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
    NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
    return [emailTest evaluateWithObject:email];
    */
}

+ (BOOL) isSecurityPassword:(NSString*)password
                      error:(NSError**)error {
    if (password.length < 6) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"You password must be at least 6 characters!", @"")}];
        }
        return NO;
    }
    
    if ([password rangeOfCharacterFromSet:[NSCharacterSet decimalDigitCharacterSet]].location == NSNotFound) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"You password is too simple, please enter at least one digit to make it more secure.", @"")}];
        }
        return NO;
    }
    
    if ([password rangeOfCharacterFromSet:[NSCharacterSet letterCharacterSet]].location == NSNotFound) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"You password is too simple, please enter at least one character to make it more secure.", @"")}];
        }
        return NO;
    }
    
    return YES;
}

+ (BOOL) isValidUsername:(NSString *)username error:(NSError **)error {
    if(username.length > 12) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"You username must be less than 12 characters!", @"")}];
        }
        return NO;
    }
    
    NSCharacterSet *s = [NSCharacterSet characterSetWithCharactersInString:@"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890_"];
    s = [s invertedSet];
    NSRange r = [username rangeOfCharacterFromSet:s];
    if (r.location != NSNotFound) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:0 userInfo:@{NSLocalizedDescriptionKey:NSLocalizedString(@"Username can only contain letters and numbers!", @"")}];
        }
        return NO;
    }

    
    return YES;
}

+ (BOOL)requestPasswordResetForEmail:(NSString *)email {
    return [self requestPasswordResetForEmail:email error:NULL];
}

+ (BOOL)requestPasswordResetForEmail:(NSString *)email error:(NSError *__autoreleasing *)error {
    
    
    NSDictionary *requestDict = @{@"email":email};
    NSError *jsonError = nil;
    NSData *body = [NSJSONSerialization dataWithJSONObject:requestDict options:0 error:&jsonError];
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return NO;
    }
    
    NSURL *url = [WYKit endpointForMethod:@"users/requestPasswordResetForEmail"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"POST";
    request.HTTPBody = body;
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
    
    return [resultJSONObject[@"status"] isEqualToString:@"OK"];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email {
    [self requestPasswordResetForEmailInBackground:email block:NULL];
}

+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
                                           block:(WYBooleanResultBlock)block {
    dispatch_async([WYKit queue], ^{
        NSError *error = nil;
        BOOL result = [self requestPasswordResetForEmail:email error:&error];
        if (block) {
            dispatch_async(dispatch_get_main_queue(), ^{
                block(result,error);
            });
        }
    });
}


// private method

-(void)setIsAuthenticated:(BOOL)isAuthenticated {
    _isAuthenticated = isAuthenticated;
}

+(instancetype)requestCurrentUserFromNetwork:(NSError**)error {
    NSURL *url = [WYKit endpointForMethod:@"users/me"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPMethod = @"GET";
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
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
        return nil;
    }
    
    if (jsonError) {
        if (error != NULL) {
            *error = jsonError;
        }
        return nil;
    }
    
    if (response.statusCode != 200) {
        if (error != NULL) {
            *error = [NSError errorWithDomain:@"WYKit" code:response.statusCode userInfo:resultJSONObject[@"errors"]];
        }
        return nil;
    }
    
    id parsedResponse = [self parseReponse:resultJSONObject];
    WYUser *me = [[WYUser alloc] initWithResultMap:parsedResponse className:[WYUser wyClassName]];
    return me;
}

// I don't know why the coder will enccode the user name and email starndalong, what the fuck
/*
- (void)setWithCoder:(NSCoder *)aDecoder
{
    BOOL secureAvailable = [aDecoder respondsToSelector:@selector(decodeObjectOfClass:forKey:)];
    BOOL secureSupported = [[self class] supportsSecureCoding];
    NSDictionary *properties = [self codableProperties];
    for (NSString *key in properties)
    {
        if ([key isEqualToString:@"username"] || [key isEqualToString:@"email"] ) {
            continue;
        }
        id object = nil;
        Class propertyClass = properties[key];
        if (secureAvailable)
        {
            object = [aDecoder decodeObjectOfClass:propertyClass forKey:key];
        }
        else
        {
            object = [aDecoder decodeObjectForKey:key];
        }
        if (object)
        {
            if (secureSupported && ![object isKindOfClass:propertyClass])
            {
                [NSException raise:AutocodingException format:@"Expected '%@' to be a %@, but was actually a %@", key, propertyClass, [object class]];
            }
            [self setValue:object forKey:key];
        }
    }
}
*/
-(NSArray*)excludeProperties {
    return @[@"username",@"email",@"task"];
}

@end
