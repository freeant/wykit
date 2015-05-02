//
//  WYUser.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/21/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WYSubclassing.h"
#import "WYObject.h"

typedef NS_ENUM(NSInteger, VerificationCodeRequestType) {
    VerificationCodeRequestTypeSMS = 0,
    VerificationCodeRequestTypeCall = 1
};

@interface WYUser : WYObject<WYSubclassing>
+ (NSString *)wyClassName;
+ (instancetype)currentUser;
+ (WYUser *)user;

@property (nonatomic, copy) NSString *sessionToken;

/// The username for the WYUser.
@property (nonatomic, retain) NSString *username;

/**
 The password for the WYUser. This will not be filled in from the server with
 the password. It is only meant to be set.
 */
@property (nonatomic, retain) NSString *password;

/// The email for the WYUser.
@property (nonatomic, retain) NSString *email;

- (BOOL)isAuthenticated;

/*!
 Signs up the user. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 @result Returns true if the sign up was successful.
 */
- (BOOL)signUp;

/*!
 Signs up the user. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 @param error Error object to set on error.
 @result Returns whether the sign up was successful.
 */
- (BOOL)signUp:(NSError **)error;

/*!
 Signs up the user asynchronously. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 */
- (void)signUpInBackground;

/*!
 Signs up the user asynchronously. Make sure that password and username are set. This will also enforce that the username isn't already taken.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error)
 */
- (void)signUpInBackgroundWithBlock:(WYBooleanResultBlock)block;

// request mobile phone verification code
- (BOOL)requestVerificationCodeForPhoneNumber:(NSString *)phoneNumber
                                         type:(VerificationCodeRequestType)type;
- (BOOL)requestVerificationCodeForPhoneNumber:(NSString *)phoneNumber
                                         type:(VerificationCodeRequestType)type error:(NSError**)error;
- (void)requestVerificationCodeForPhoneNumberInBackground:(NSString *)phoneNumber
                                                     type:(VerificationCodeRequestType)type;
- (void)requestVerificationCodeForPhoneNumberInBackground:(NSString *)phoneNumber
                                                     type:(VerificationCodeRequestType)type
                                                    block:(WYBooleanResultBlock)block;

// verify the phone
- (BOOL)verifyPhoneNumber:(NSString*)phoneNumber
         verificationCode:(NSString*)verificationCode
              countryCode:(NSString*)countryCode;

- (BOOL)verifyPhoneNumber:(NSString*)phoneNumber
         verificationCode:(NSString*)verificationCode
              countryCode:(NSString*)countryCode error:(NSError**)error;

- (void)verifyPhoneNumberInBackground:(NSString*)phoneNumber
                     verificationCode:(NSString*)verificationCode
                          countryCode:(NSString*)countryCode;

- (void)verifyPhoneNumberInBackground:(NSString*)phoneNumber
                     verificationCode:(NSString*)verificationCode
                          countryCode:(NSString*)countryCode
                                block:(WYBooleanResultBlock)block;

// change the password
- (BOOL)changePassword:(NSString*)newPassword
       confirmPassword:(NSString*)confirmPassword
       currentPassword:(NSString*)currentPassword;

- (BOOL)changePassword:(NSString*)newPassword
       confirmPassword:(NSString*)confirmPassword
       currentPassword:(NSString*)currentPassword
                 error:(NSError**)error;

- (void)changePasswordInBackground:(NSString*)newPassword
                   confirmPassword:(NSString*)confirmPassword
                   currentPassword:(NSString*)currentPassword;

- (void)changePasswordInBackground:(NSString*)newPassword
                   confirmPassword:(NSString*)confirmPassword
                   currentPassword:(NSString*)currentPassword
                             block:(WYBooleanResultBlock)block;



/** @name Logging in */

/*!
 Makes a request to login a user with specified credentials. Returns an instance
 of the successfully logged in WYUser. This will also cache the user locally so
 that calls to currentUser will use the latest logged in user.
 @param username The username of the user.
 @param password The password of the user.
 @result Returns an instance of the WYUser on success. If login failed for either wrong password or wrong username, returns nil.
 */
+ (instancetype)logInWithUsername:(NSString *)username
                         password:(NSString *)password;

/*!
 Makes a request to login a user with specified credentials. Returns an
 instance of the successfully logged in WYUser. This will also cache the user
 locally so that calls to currentUser will use the latest logged in user.
 @param username The username of the user.
 @param password The password of the user.
 @param error The error object to set on error.
 @result Returns an instance of the WYUser on success. If login failed for either wrong password or wrong username, returns nil.
 */
+ (instancetype)logInWithUsername:(NSString *)username
                         password:(NSString *)password
                            error:(NSError **)error;

/*!
 Makes an asynchronous request to login a user with specified credentials.
 Returns an instance of the successfully logged in WYUser. This will also cache
 the user locally so that calls to currentUser will use the latest logged in user.
 @param username The username of the user.
 @param password The password of the user.
 */
+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password;


/*!
 Makes an asynchronous request to log in a user with specified credentials.
 Returns an instance of the successfully logged in WYUser. This will also cache
 the user locally so that calls to currentUser will use the latest logged in user.
 @param username The username of the user.
 @param password The password of the user.
 @param block The block to execute. The block should have the following argument signature: (WYUser *user, NSError *error)
 */
+ (void)logInWithUsernameInBackground:(NSString *)username
                             password:(NSString *)password
                                block:(WYUserResultBlock)block;


/** @name Logging Out */

/*!
 Logs out the currently logged in user on disk.
 */
+ (void)logOut;

/** @name Requesting a Password Reset */

/*!
 Send a password reset request for a specified email. If a user account exists with that email,
 an email will be sent to that address with instructions on how to reset their password.
 @param email Email of the account to send a reset password request.
 @result Returns true if the reset email request is successful. False if no account was found for the email address.
 */
//+ (BOOL)requestPasswordResetForEmail:(NSString *)email;

/*!
 Send a password reset request for a specified email and sets an error object. If a user
 account exists with that email, an email will be sent to that address with instructions
 on how to reset their password.
 @param email Email of the account to send a reset password request.
 @param error Error object to set on error.
 @result Returns true if the reset email request is successful. False if no account was found for the email address.
 */
/*
+ (BOOL)requestPasswordResetForEmail:(NSString *)email
                               error:(NSError **)error;
*/

/*!
 Send a password reset request asynchronously for a specified email and sets an
 error object. If a user account exists with that email, an email will be sent to
 that address with instructions on how to reset their password.
 @param email Email of the account to send a reset password request.
 */
//+ (void)requestPasswordResetForEmailInBackground:(NSString *)email;

/*!
 Send a password reset request asynchronously for a specified email.
 If a user account exists with that email, an email will be sent to that address with instructions
 on how to reset their password.
 @param email Email of the account to send a reset password request.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error)
 */
//+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
//                                           block:(WYBooleanResultBlock)block;

+ (BOOL) isValidUsername:(NSString *)username error:(NSError**)error;
+ (BOOL) isValidEmail:(NSString *)email;
+ (BOOL) isSecurityPassword:(NSString*)password error:(NSError**)error;

/*!
 Send a password reset request for a specified email. If a user account exists with that email,
 an email will be sent to that address with instructions on how to reset their password.
 @param email Email of the account to send a reset password request.
 @result Returns true if the reset email request is successful. False if no account was found for the email address.
 */
+ (BOOL)requestPasswordResetForEmail:(NSString *)email;

/*!
 Send a password reset request for a specified email and sets an error object. If a user
 account exists with that email, an email will be sent to that address with instructions
 on how to reset their password.
 @param email Email of the account to send a reset password request.
 @param error Error object to set on error.
 @result Returns true if the reset email request is successful. False if no account was found for the email address.
 */
+ (BOOL)requestPasswordResetForEmail:(NSString *)email
                               error:(NSError **)error;

/*!
 Send a password reset request asynchronously for a specified email and sets an
 error object. If a user account exists with that email, an email will be sent to
 that address with instructions on how to reset their password.
 @param email Email of the account to send a reset password request.
 */
+ (void)requestPasswordResetForEmailInBackground:(NSString *)email;

/*!
 Send a password reset request asynchronously for a specified email.
 If a user account exists with that email, an email will be sent to that address with instructions
 on how to reset their password.
 @param email Email of the account to send a reset password request.
 @param block The block to execute. The block should have the following argument signature: (BOOL succeeded, NSError *error)
 */
+ (void)requestPasswordResetForEmailInBackground:(NSString *)email
                                           block:(WYBooleanResultBlock)block;









/** @name Querying for Users */

/*!
 Creates a query for WYUser objects.
 */
+ (WYQuery *)query;
@end
