//
//  WYObject+Subclass.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/21/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYObject.h"

@class WYQuery;

@interface WYObject (Subclass)
/*! @name Methods for Subclasses */

/*!
 Designated initializer for subclasses.
 This method can only be called on subclasses which conform to WYSubclassing.
 This method should not be overridden.
 */
- (id)init;

/*!
 Creates an instance of the registered subclass with this class's parseClassName.
 This helps a subclass ensure that it can be subclassed itself. For example, [WYUser object] will
 return a MyUser object if MyUser is a registered subclass of WYUser. For this reason, [MyClass object] is
 preferred to [[MyClass alloc] init].
 This method can only be called on subclasses which conform to WYSubclassing.
 A default implementation is provided by WYObject which should always be sufficient.
 */
+ (instancetype)object;

/*!
 Creates a reference to an existing WYObject for use in creating associations between WYObjects.  Calling isDataAvailable on this
 object will return NO until fetchIfNeeded or refresh has been called.  No network request will be made.
 This method can only be called on subclasses which conform to WYSubclassing.
 A default implementation is provided by WYObject which should always be sufficient.
 @param objectId The object id for the referenced object.
 @result A WYObject without data.
 */
+ (id)objectWithoutDataWithObjectId:(NSString *)objectId;

/*!
 Registers an Objective-C class for Parse to use for representing a given Parse class.
 Once this is called on a WYObject subclass, any WYObject Parse creates with a class
 name matching [self parseClassName] will be an instance of subclass.
 This method can only be called on subclasses which conform to WYSubclassing.
 A default implementation is provided by WYObject which should always be sufficient.
 */
+ (void)registerSubclass;

/*!
 Returns a query for objects of type +parseClassName.
 This method can only be called on subclasses which conform to WYSubclassing.
 A default implementation is provided by WYObject which should always be sufficient.
 */
+ (WYQuery *)query;

@end
