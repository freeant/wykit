//
//  WYSubclassing.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/20/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import <Foundation/Foundation.h>

@class WYQuery;

/*!
 If a subclass of WYObject conforms to WYSubclassing and calls registerSubEntity, Parse will be able to use that class as the native class for a WYKit object.
 
 Classes conforming to this protocol should subclass WYObject and include WYObject+Subclass.h in their implementation file. This ensures the methods in the Subclass category of WYObject are exposed in its subclasses only.
 */

@protocol WYSubclassing

/*!
 Constructs an object of the most specific class known to implement entity name.
 This method takes care to help WYObject subclasses be subclassed themselves.
 For example, [WYUser object] returns a WYUser by default but will return an
 object of a registered subclass instead if one is known.
 A default implementation is provided by WYObject which should always be sufficient.
 @result Returns the object that is instantiated.
 */
+ (instancetype)object;

/*!
 Creates a reference to an existing WYObject for use in creating associations between WYObjects.  Calling isDataAvailable on this
 object will return NO until fetchIfNeeded or refresh has been called.  No network request will be made.
 A default implementation is provided by WYObject which should always be sufficient.
 @param objectId The object id for the referenced object.
 @result A WYObject without data.
 */
+ (instancetype)objectWithoutDataWithObjectId:(NSString *)objectId;

/*! The name of the class as seen in the REST API. */
+ (NSString *)wyClassName;

/*!
 Create a query which returns objects of this type.
 A default implementation is provided by WYObject which should always be sufficient.
 */
+ (WYQuery *)query;

/*!
 Lets WYKit know this class should be used to instantiate all objects with class type entityName.
 This method must be called before [WYKit setApplicationEndpoint:clientKey:]
 */
+ (void)registerSubclass;
@end
