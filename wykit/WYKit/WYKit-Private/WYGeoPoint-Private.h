//
//  WYGeoPoint-Private.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/22/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYGeoPoint.h"

@interface WYGeoPoint(Private)

-(instancetype)initWithJsonObject:(id)jsonObject;
-(NSArray*)toJsonObject;
-(NSDictionary*)toGeometry;

@end