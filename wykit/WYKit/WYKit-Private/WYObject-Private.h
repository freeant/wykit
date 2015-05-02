//
//  WYObject-Private.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/22/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//
#import "WYObject.h"

@interface WYObject()

@property (nonatomic, strong) NSMutableDictionary *setMap;
@property (nonatomic, strong) NSMutableDictionary *unsetMap;
@property (nonatomic, strong) NSMutableDictionary *incMap;
@property (nonatomic, strong) NSMutableDictionary *pushMap;
@property (nonatomic, strong) NSMutableDictionary *pushAllMap;
@property (nonatomic, strong) NSMutableDictionary *pullMap;
@property (nonatomic, strong) NSMutableDictionary *pullAllMap;
@property (nonatomic, strong) NSMutableDictionary *addToSetMap;
@property (nonatomic, strong) NSDictionary *resultMap;

+(id)parseReponse:(id)response;
-(NSDictionary*)toPointerObject;
-(instancetype)initWithResultMap:(NSDictionary*)resultMap className:(NSString*)className;
-(void)setResultMap:(NSDictionary*)resultMap;
-(instancetype)initWithWYObject:(WYObject*)anotherObject;




@end
