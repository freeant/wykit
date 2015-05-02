//
//  WYFile-Private.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/21/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "WYFile.h"

@interface WYFile(Private)
-(instancetype)initWithName:(NSString*)name url:(NSString*)url;
-(instancetype)initWithFile:(WYFile*)wyFile;
-(instancetype)initWithJsonObject:(id)jsonObject;
-(NSDictionary*)toJsonObject;
@end
