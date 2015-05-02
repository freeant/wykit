//
//  WYQuery.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/21/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "WYObject.h"
#import "WYUser.h"

@class WYGeoPoint;

@interface WYQuery : NSObject

#pragma mark Query options

/** @name Creating a Query for a Class */

/*!
 Returns a WYQuery for a given class.
 @param className The class to query on.
 @return A WYQuery object.
 */
+ (WYQuery *)queryWithClassName:(NSString *)className;

/*!
 Creates a WYQuery with the constraints given by predicate.
 
 The following types of predicates are supported:
 * Simple comparisons such as =, !=, <, >, <=, >=, and BETWEEN with a key and a constant.
 * Containment predicates, such as "x IN {1, 2, 3}".
 * Key-existence predicates, such as "x IN SELF".
 * BEGINSWITH expressions.
 * Compound predicates with AND, OR, and NOT.
 * SubQueries with "key IN %@", subquery.
 
 The following types of predicates are NOT supported:
 * Aggregate operations, such as ANY, SOME, ALL, or NONE.
 * Regular expressions, such as LIKE, MATCHES, CONTAINS, or ENDSWITH.
 * Predicates comparing one key to another.
 * Complex predicates with many ORed clauses.
 
 */
//+ (WYQuery *)queryWithClassName:(NSString *)className predicate:(NSPredicate *)predicate;

/*!
 Initializes the query with a class name.
 @param newClassName The class name.
 */
- (id)initWithClassName:(NSString *)newClassName;

/*!
 The class name to query for
 */
@property (nonatomic, retain) NSString *wyClassName;

/** @name Adding Basic Constraints */

/*!
 Make the query include WYObjects that have a reference stored at the provided key.
 This has an effect similar to a join.  You can use dot notation to specify which fields in
 the included object are also fetch.
 @param key The key to load child WYObjects for.
 */
- (void)includeKey:(NSString *)key;

/*!
 Make the query restrict the fields of the returned WYObjects to include only the provided keys.
 If this is called multiple times, then all of the keys specified in each of the calls will be included.
 @param keys The keys to include in the result.
 */
- (void)selectKeys:(NSArray *)keys;

/*!
 Add a constraint that requires a particular key exists.
 @param key The key that should exist.
 */
- (void)whereKeyExists:(NSString *)key;

/*!
 Add a constraint that requires a key not exist.
 @param key The key that should not exist.
 */
- (void)whereKeyDoesNotExist:(NSString *)key;

/*!
 Add a constraint to the query that requires a particular key's object to be equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key equalTo:(id)object;

/*!
 Add a constraint to the query that requires a particular key's object to be less than the provided object.
 @param key The key to be constrained.
 @param object The object that provides an upper bound.
 */
- (void)whereKey:(NSString *)key lessThan:(id)object;

/*!
 Add a constraint to the query that requires a particular key's object to be less than or equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key lessThanOrEqualTo:(id)object;

/*!
 Add a constraint to the query that requires a particular key's object to be greater than the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key greaterThan:(id)object;

/*!
 Add a constraint to the query that requires a particular key's object to be greater than or equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must be equalled.
 */
- (void)whereKey:(NSString *)key greaterThanOrEqualTo:(id)object;

/*!
 Add a constraint to the query that requires a particular key's object to be not equal to the provided object.
 @param key The key to be constrained.
 @param object The object that must not be equalled.
 */
- (void)whereKey:(NSString *)key notEqualTo:(id)object;

/*!
 Add a constraint to the query that requires a particular key's object to be contained in the provided array.
 @param key The key to be constrained.
 @param array The possible values for the key's object.
 */
- (void)whereKey:(NSString *)key containedIn:(NSArray *)array;

/*!
 Add a constraint to the query that requires a particular key's object not be contained in the provided array.
 @param key The key to be constrained.
 @param array The list of values the key's object should not be.
 */
- (void)whereKey:(NSString *)key notContainedIn:(NSArray *)array;

/*!
 Add a constraint to the query that requires a particular key's array contains every element of the provided array.
 @param key The key to be constrained.
 @param array The array of values to search for.
 */
- (void)whereKey:(NSString *)key containsAllObjectsInArray:(NSArray *)array;

/** @name Adding Location Constraints */

/*!
 Add a constraint to the query that requires a particular key's coordinates (specified via WYGeoPoint) be near
 a reference point.  Distance is calculated based on angular distance on a sphere.  Results will be sorted by distance
 from reference point.
 @param key The key to be constrained.
 @param geopoint The reference point.  A WYGeoPoint.
 */
- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint;

/*!
 Add a constraint to the query that requires a particular key's coordinates (specified via WYGeoPoint) be near
 a reference point and within the maximum distance specified (in miles).  Distance is calculated based on
 a spherical coordinate system.  Results will be sorted by distance (nearest to farthest) from the reference point.
 @param key The key to be constrained.
 @param geopoint The reference point.  A WYGeoPoint.
 @param maxDistance Maximum distance in miles.
 */
- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint withinMiles:(double)maxDistance;

/*!
 Add a constraint to the query that requires a particular key's coordinates (specified via WYGeoPoint) be near
 a reference point and within the maximum distance specified (in kilometers).  Distance is calculated based on
 a spherical coordinate system.  Results will be sorted by distance (nearest to farthest) from the reference point.
 @param key The key to be constrained.
 @param geopoint The reference point.  A WYGeoPoint.
 @param maxDistance Maximum distance in kilometers.
 */
- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint withinKilometers:(double)maxDistance;

/*!
 Add a constraint to the query that requires a particular key's coordinates (specified via WYGeoPoint) be near
 a reference point and within the maximum distance specified (in radians).  Distance is calculated based on
 angular distance on a sphere.  Results will be sorted by distance (nearest to farthest) from the reference point.
 @param key The key to be constrained.
 @param geopoint The reference point.  A WYGeoPoint.
 @param maxDistance Maximum distance in radians.
 */
- (void)whereKey:(NSString *)key nearGeoPoint:(WYGeoPoint *)geopoint withinRadians:(double)maxDistance;

/*!
 Add a constraint to the query that requires a particular key's coordinates (specified via WYGeoPoint) be
 contained within a given rectangular geographic bounding box.
 @param key The key to be constrained.
 @param southwest The lower-left inclusive corner of the box.
 @param northeast The upper-right inclusive corner of the box.
 */
- (void)whereKey:(NSString *)key withinGeoBoxFromSouthwest:(WYGeoPoint *)southwest toNortheast:(WYGeoPoint *)northeast;

/** @name Adding String Constraints */

/*!
 Add a regular expression constraint for finding string values that match the provided regular expression.
 This may be slow for large datasets.
 @param key The key that the string to match is stored in.
 @param regex The regular expression pattern to match.
 */
- (void)whereKey:(NSString *)key matchesRegex:(NSString *)regex;

/*!
 Add a regular expression constraint for finding string values that match the provided regular expression.
 This may be slow for large datasets.
 @param key The key that the string to match is stored in.
 @param regex The regular expression pattern to match.
 @param modifiers Any of the following supported PCRE modifiers:<br><code>i</code> - Case insensitive search<br><code>m</code> - Search across multiple lines of input
 */
- (void)whereKey:(NSString *)key matchesRegex:(NSString *)regex modifiers:(NSString *)modifiers;

/*!
 Add a constraint for finding string values that contain a provided substring.
 This will be slow for large datasets.
 @param key The key that the string to match is stored in.
 @param substring The substring that the value must contain.
 */
- (void)whereKey:(NSString *)key containsString:(NSString *)substring caseInsensitive:(BOOL)caseInsensitive;

/*!
 Add a constraint for finding string values that start with a provided prefix.
 This will use smart indexing, so it will be fast for large datasets.
 @param key The key that the string to match is stored in.
 @param prefix The substring that the value must start with.
 */
- (void)whereKey:(NSString *)key hasPrefix:(NSString *)prefix;

/*!
 Add a constraint for finding string values that end with a provided suffix.
 This will be slow for large datasets.
 @param key The key that the string to match is stored in.
 @param suffix The substring that the value must end with.
 */
- (void)whereKey:(NSString *)key hasSuffix:(NSString *)suffix;

/** @name Adding Subqueries */

/*!
 Returns a WYQuery that is the or of the passed in WYQuerys.
 @param queries The list of queries to or together.
 @result a WYQuery that is the or of the passed in WYQuerys.
 */
+ (WYQuery *)orQueryWithSubqueries:(NSArray *)queries;

/*!
 Adds a constraint that requires that a key's value matches a value in another key
 in objects returned by a sub query.
 @param key The key that the value is stored
 @param otherKey The key in objects in the returned by the sub query whose value should match
 @param query The query to run.
 */
- (void)whereKey:(NSString *)key matchesKey:(NSString *)otherKey inQuery:(WYQuery *)query;

/*!
 Adds a constraint that requires that a key's value NOT match a value in another key
 in objects returned by a sub query.
 @param key The key that the value is stored
 @param otherKey The key in objects in the returned by the sub query whose value should match
 @param query The query to run.
 */
- (void)whereKey:(NSString *)key doesNotMatchKey:(NSString *)otherKey inQuery:(WYQuery *)query;

/*!
 Add a constraint that requires that a key's value matches a WYQuery constraint.
 This only works where the key's values are WYObjects or arrays of WYObjects.
 @param key The key that the value is stored in
 @param query The query the value should match
 */
- (void)whereKey:(NSString *)key matchesQuery:(WYQuery *)query;

/*!
 Add a constraint that requires that a key's value to not match a WYQuery constraint.
 This only works where the key's values are WYObjects or arrays of WYObjects.
 @param key The key that the value is stored in
 @param query The query the value should not match
 */
- (void)whereKey:(NSString *)key doesNotMatchQuery:(WYQuery *)query;

#pragma mark -
#pragma mark Sorting

/** @name Sorting */

/*!
 Sort the results in ascending order with the given key.
 @param key The key to order by.
 */
- (void)orderByAscending:(NSString *)key;

/*!
 Also sort in ascending order by the given key.  The previous keys provided will
 precedence over this key.
 @param key The key to order bye
 */
- (void)addAscendingOrder:(NSString *)key;

/*!
 Sort the results in descending order with the given key.
 @param key The key to order by.
 */
- (void)orderByDescending:(NSString *)key;
/*!
 Also sort in descending order by the given key.  The previous keys provided will
 precedence over this key.
 @param key The key to order bye
 */
- (void)addDescendingOrder:(NSString *)key;

/*!
 Sort the results in descending order with the given descriptor.
 @param sortDescriptor The NSSortDescriptor to order by.
 */
- (void)orderBySortDescriptor:(NSSortDescriptor *)sortDescriptor;

/*!
 Sort the results in descending order with the given descriptors.
 @param sortDescriptors An NSArray of NSSortDescriptor instances to order by.
 */
- (void)orderBySortDescriptors:(NSArray *)sortDescriptors;

#pragma mark -
#pragma mark Get methods

/** @name Getting Objects by ID */

/*!
 Returns a WYObject with a given class and id.
 @param objectClass The class name for the object that is being requested.
 @param objectId The id of the object that is being requested.
 @result The WYObject if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (WYObject *)getObjectOfClass:(NSString *)objectClass
                      objectId:(NSString *)objectId;

/*!
 Returns a WYObject with a given class and id and sets an error if necessary.
 @param error Pointer to an NSError that will be set if necessary.
 @result The WYObject if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (WYObject *)getObjectOfClass:(NSString *)objectClass
                      objectId:(NSString *)objectId
                         error:(NSError **)error;

/*!
 Returns a WYObject with the given id.
 
 This mutates the WYQuery.
 
 @param objectId The id of the object that is being requested.
 @result The WYObject if found. Returns nil if the object isn't found, or if there was an error.
 */
- (WYObject *)getObjectWithId:(NSString *)objectId;

/*!
 Returns a WYObject with the given id and sets an error if necessary.
 
 This mutates the WYQuery
 
 @param error Pointer to an NSError that will be set if necessary.
 @result The WYObject if found. Returns nil if the object isn't found, or if there was an error.
 */
- (WYObject *)getObjectWithId:(NSString *)objectId error:(NSError **)error;

/*!
 Gets a WYObject asynchronously and calls the given block with the result.
 
 This mutates the WYQuery
 
 @param block The block to execute. The block should have the following argument signature: (NSArray *object, NSError *error)
 */
- (void)getObjectInBackgroundWithId:(NSString *)objectId
                              block:(WYObjectResultBlock)block;


#pragma mark -
#pragma mark Getting Users

/*! @name Getting User Objects */

/*!
 Returns a WYUser with a given id.
 @param objectId The id of the object that is being requested.
 @result The WYUser if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (WYUser *)getUserObjectWithId:(NSString *)objectId;

/*!
 Returns a WYUser with a given class and id and sets an error if necessary.
 @param error Pointer to an NSError that will be set if necessary.
 @result The WYUser if found. Returns nil if the object isn't found, or if there was an error.
 */
+ (WYUser *)getUserObjectWithId:(NSString *)objectId
                          error:(NSError **)error;


#pragma mark -
#pragma mark Find methods

/** @name Getting all Matches for a Query */

/*!
 Finds objects based on the constructed query.
 @result Returns an array of WYObjects that were found.
 */
- (NSArray *)findObjects;

/*!
 Finds objects based on the constructed query and sets an error if there was one.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns an array of WYObjects that were found.
 */
- (NSArray *)findObjects:(NSError **)error;

/*!
 Finds objects asynchronously and calls the given block with the results.
 @param block The block to execute. The block should have the following argument signature:(NSArray *objects, NSError *error)
 */
- (void)findObjectsInBackgroundWithBlock:(WYArrayResultBlock)block;


/** @name Getting the First Match in a Query */

/*!
 Gets an object based on the constructed query.
 
 This mutates the WYQuery.
 
 @result Returns a WYObject, or nil if none was found.
 */
- (WYObject *)getFirstObject;

/*!
 Gets an object based on the constructed query and sets an error if any occurred.
 
 This mutates the WYQuery.
 
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns a WYObject, or nil if none was found.
 */
- (WYObject *)getFirstObject:(NSError **)error;

/*!
 Gets an object asynchronously and calls the given block with the result.
 
 This mutates the WYQuery.
 
 @param block The block to execute. The block should have the following argument signature:(WYObject *object, NSError *error) result will be nil if error is set OR no object was found matching the query. error will be nil if result is set OR if the query succeeded, but found no results.
 */
- (void)getFirstObjectInBackgroundWithBlock:(WYObjectResultBlock)block;


#pragma mark -
#pragma mark Count methods

/** @name Counting the Matches in a Query */

/*!
 Counts objects based on the constructed query.
 @result Returns the number of WYObjects that match the query, or -1 if there is an error.
 */
- (NSInteger)countObjects;

/*!
 Counts objects based on the constructed query and sets an error if there was one.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns the number of WYObjects that match the query, or -1 if there is an error.
 */
- (NSInteger)countObjects:(NSError **)error;

/*!
 Counts objects asynchronously and calls the given block with the counts.
 @param block The block to execute. The block should have the following argument signature:
 (int count, NSError *error)
 */
- (void)countObjectsInBackgroundWithBlock:(WYIntegerResultBlock)block;


#pragma mark -
#pragma mark Cancel methods

/** @name Cancelling a Query */

/*!
 Cancels the current network request (if any). Ensures that callbacks won't be called.
 */
- (void)cancel;


#pragma mark -
#pragma mark Pagination properties

/** @name Paginating Results */
/*!
 A limit on the number of objects to return. The default limit is 100, with a
 maximum of 1000 results being returned at a time.
 
 Note: If you are calling findObject with limit=1, you may find it easier to use getFirst instead.
 */
@property (nonatomic) NSInteger limit;

@property(readonly) BOOL requesting;

/*!
 The number of objects to skip before returning any.
 */
@property (nonatomic) NSInteger skip;

#pragma mark -
#pragma mark Cache methods

/** @name Controlling Caching Behavior */

/*!
 The cache policy to use for requests.
 */
@property (readwrite, assign) WYCachePolicy cachePolicy;

/* !
 The age after which a cached value will be ignored
 */
@property (readwrite, assign) NSTimeInterval maxCacheAge;

/*!
 Returns whether there is a cached result for this query.
 @result YES if there is a cached result for this query, and NO otherwise.
 */
- (BOOL)hasCachedResult;

/*!
 Clears the cached result for this query.  If there is no cached result, this is a noop.
 */
- (void)clearCachedResult;

#pragma mark - Advanced Settings

/** @name Advanced Settings */

/*!
 Whether or not performance tracing should be done on the query.
 This should not be set in most cases.
 */
@property (nonatomic, assign) BOOL trace;

@end
