//
//  WYGeoPoint.m
//  Whirl
//
//  Created by Zhong Fanglin on 9/22/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYGeoPoint.h"
#import "INTULocationManager.h"

@implementation WYGeoPoint

-(id)copyWithZone:(NSZone *)zone {
    WYGeoPoint *point = [[WYGeoPoint allocWithZone:zone] init];
    point.latitude = self.latitude;
    point.longitude = self.longitude;
    return point;
}

+ (WYGeoPoint *)geoPoint {
    return [self geoPointWithLatitude:0.0 longitude:0.0];
}

+ (WYGeoPoint *)geoPointWithLocation:(CLLocation *)location {
    return [self geoPointWithLatitude:location.coordinate.latitude longitude:location.coordinate.longitude];
}

+ (WYGeoPoint *)geoPointWithLatitude:(double)latitude longitude:(double)longitude {
    WYGeoPoint *point = [[WYGeoPoint alloc] init];
    point.latitude = latitude;
    point.longitude = longitude;
    return point;
}

+ (void)geoPointForCurrentLocationInBackground:(void(^)(WYGeoPoint *geoPoint, NSError *error))geoPointHandler {
    [[INTULocationManager sharedInstance] requestLocationWithDesiredAccuracy:INTULocationAccuracyBlock timeout:10.0 delayUntilAuthorized:YES block:^(CLLocation *currentLocation, INTULocationAccuracy achievedAccuracy, INTULocationStatus status) {
        if (currentLocation) {
            WYGeoPoint *point = [WYGeoPoint geoPointWithLatitude:currentLocation.coordinate.latitude longitude:currentLocation.coordinate.longitude];
            if (geoPointHandler) {
                geoPointHandler(point,nil);
            }
        } else {
            if (geoPointHandler) {
                geoPointHandler(nil,[NSError errorWithDomain:@"WYGeoPoint" code:status userInfo:nil]);
            }
        }
    }];
}

- (double)distanceInRadiansTo:(WYGeoPoint*)point {
    
    static const double DEG_TO_RAD = 0.017453292519943295769236907684886;
    static const double EARTH_RADIUS_IN_METERS = 6372797.560856;
    
    double latitudeArc  = (self.latitude - point.latitude) * DEG_TO_RAD;
    double longitudeArc = (self.longitude - point.longitude) * DEG_TO_RAD;
    double latitudeH = sin(latitudeArc * 0.5);
    latitudeH *= latitudeH;
    double lontitudeH = sin(longitudeArc * 0.5);
    lontitudeH *= lontitudeH;
    double tmp = cos(self.latitude*DEG_TO_RAD) * cos(point.latitude*DEG_TO_RAD);
    return EARTH_RADIUS_IN_METERS * 2.0 * asin(sqrt(latitudeH + tmp*lontitudeH));
    
}

- (double)distanceInMilesTo:(WYGeoPoint*)point {
    return [[self location] distanceFromLocation:[point location]]/1609.344;
}

- (double)distanceInKilometersTo:(WYGeoPoint*)point {
    return [[self location] distanceFromLocation:[point location]]/1000.0;
}

-(CLLocation*)location {
    return [[CLLocation alloc] initWithLatitude:_latitude longitude:_longitude];
}

// private mehtods
-(instancetype)initWithJsonObject:(id)jsonObject {
    return [WYGeoPoint geoPointWithLatitude:[jsonObject[@"latitude"] doubleValue] longitude:[jsonObject[@"longitude"] doubleValue]];
}

-(NSArray*)toJsonObject {
    return @[[NSNumber numberWithDouble:_latitude],[NSNumber numberWithDouble:_longitude]];
}

-(NSDictionary*)toGeometry {
    return @{@"type":@"Point",@"coordinates":@[[NSNumber numberWithDouble:_latitude],[NSNumber numberWithDouble:_longitude]]};
}


@end
