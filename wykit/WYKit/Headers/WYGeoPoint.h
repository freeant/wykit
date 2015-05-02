//
//  WYGeoPoint.h
//  WYKit
//
//  Created by Zhong Fanglin on 9/22/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
/*!
 Object which may be used to embed a latitude / longitude point as the value for a key in a WYObject.
 WYObjects with a WYGeoPoint field may be queried in a geospatial manner using PFQuery's whereKey:nearGeoPoint:.
 
 This is also used as a point specifier for whereKey:nearGeoPoint: queries.
 
 Currently, object classes may only have one key associated with a GeoPoint type.
 */

@interface WYGeoPoint : NSObject<NSCopying>

/** @name Creating a WYGeoPoint */
/*!
 Create a WYGeoPoint object.  Latitude and longitude are set to 0.0.
 @result Returns a new WYGeoPoint.
 */
+ (WYGeoPoint *)geoPoint;

/*!
 Creates a new WYGeoPoint object for the given CLLocation, set to the location's
 coordinates.
 @param location CLLocation object, with set latitude and longitude.
 @result Returns a new WYGeoPoint at specified location.
 */
+ (WYGeoPoint *)geoPointWithLocation:(CLLocation *)location;

/*!
 Creates a new WYGeoPoint object with the specified latitude and longitude.
 @param latitude Latitude of point in degrees.
 @param longitude Longitude of point in degrees.
 @result New point object with specified latitude and longitude.
 */
+ (WYGeoPoint *)geoPointWithLatitude:(double)latitude longitude:(double)longitude;

/*!
 Fetches the user's current location and returns a new WYGeoPoint object via the
 provided block.
 @param geoPointHandler A block which takes the newly created WYGeoPoint as an
 argument.
 */
+ (void)geoPointForCurrentLocationInBackground:(void(^)(WYGeoPoint *geoPoint, NSError *error))geoPointHandler;

/** @name Controlling Position */

/// Latitude of point in degrees.  Valid range (-90.0, 90.0).
@property (nonatomic) double latitude;
/// Longitude of point in degrees.  Valid range (-180.0, 180.0).
@property (nonatomic) double longitude;

/** @name Calculating Distance */

/*!
 Get distance in radians from this point to specified point.
 @param point WYGeoPoint location of other point.
 @result distance in radians
 */
- (double)distanceInRadiansTo:(WYGeoPoint*)point;

/*!
 Get distance in miles from this point to specified point.
 @param point WYGeoPoint location of other point.
 @result distance in miles
 */
- (double)distanceInMilesTo:(WYGeoPoint*)point;

/*!
 Get distance in kilometers from this point to specified point.
 @param point WYGeoPoint location of other point.
 @result distance in kilometers
 */
- (double)distanceInKilometersTo:(WYGeoPoint*)point;

-(CLLocation*)location;


@end
