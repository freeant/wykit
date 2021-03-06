//
//  WYFile.h
//  Whirl
//
//  Created by Zhong Fanglin on 9/19/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "WYConstants.h"

@interface WYFile : NSObject


@property(nonatomic,copy) WYBooleanResultBlock saveResultBlock;
@property(nonatomic,copy) WYDataResultBlock fetchDataResultBlock;

/*!
 Creates a file with given data. A name will be assigned to it by the server.
 @param data The contents of the new WYFile.
 @result A WYFile.
 */
+ (instancetype)fileWithData:(NSData *)data;

/*!
 Creates a file with given data and name.
 @param name The name of the new WYFile. The file name must begin with and
 alphanumeric character, and consist of alphanumeric characters, periods,
 spaces, underscores, or dashes.
 @param data The contents of hte new WYFile.
 @result A WYFile.
 */
+ (instancetype)fileWithName:(NSString *)name data:(NSData *)data;

/*!
 Creates a file with the contents of another file.
 @param name The name of the new WYFile. The file name must begin with and
 alphanumeric character, and consist of alphanumeric characters, periods,
 spaces, underscores, or dashes.
 @param path The path to the file that will be uploaded to Parse
 */
+ (instancetype)fileWithName:(NSString *)name
              contentsAtPath:(NSString *)path;

/*!
 Creates a file with given data, name and content type.
 @param name The name of the new WYFile. The file name must begin with and
 alphanumeric character, and consist of alphanumeric characters, periods,
 spaces, underscores, or dashes.
 @param data The contents of the new WYFile.
 @param contentType Represents MIME type of the data.
 @result A WYFile.
 */
+ (instancetype)fileWithName:(NSString *)name
                        data:(NSData *)data
                 contentType:(NSString *)contentType;

/*!
 Creates a file with given data and content type.
 @param data The contents of the new WYFile.
 @param contentType Represents MIME type of the data.
 @result A WYFile.
 */
+ (instancetype)fileWithData:(NSData *)data contentType:(NSString *)contentType;

/*!
 The name of the file. Before save is called, this is the filename given by
 the user. After save is called, that name gets prefixed with a unique
 identifier.
 */
@property (nonatomic, retain, readonly) NSString *name;

/*!
 The url of the file.
 */
@property (nonatomic, retain, readonly) NSString *url;

/** @name Storing Data with Parse */

/*!
 Whether the file has been uploaded for the first time.
 */
@property (nonatomic, assign, readonly) BOOL isDirty;

/*!
 Saves the file.
 @result Returns whether the save succeeded.
 */
- (BOOL)save;

/*!
 Saves the file and sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 @result Returns whether the save succeeded.
 */
- (BOOL)save:(NSError **)error;

/*!
 Saves the file asynchronously.
 */
- (void)saveInBackground;

/*!
 Saves the file asynchronously and executes the given block.
 @param block The block should have the following argument signature: (BOOL succeeded, NSError *error)
 */
- (void)saveInBackgroundWithBlock:(WYBooleanResultBlock)block;

/*!
 Saves the file asynchronously and executes the given resultBlock. Executes the progressBlock periodically with the percent
 progress. progressBlock will get called with 100 before resultBlock is called.
 @param block The block should have the following argument signature: (BOOL succeeded, NSError *error)
 @param progressBlock The block should have the following argument signature: (int percentDone)
 */
- (void)saveInBackgroundWithBlock:(WYBooleanResultBlock)block
                    progressBlock:(WYProgressBlock)progressBlock;


/** @name Getting Data from Parse */

/*!
 Whether the data is available in memory or needs to be downloaded.
 */
@property (readonly) BOOL isDataAvailable;

/*!
 Gets the data from cache if available or fetches its contents from the Parse
 servers.
 @result The data. Returns nil if there was an error in fetching.
 */
- (NSData *)getData;

/*!
 This method is like getData but avoids ever holding the entire WYFile's
 contents in memory at once. This can help applications with many large WYFiles
 avoid memory warnings.
 @result A stream containing the data. Returns nil if there was an error in
 fetching.
 */
//- (NSInputStream *)getDataStream;

/*!
 Gets the data from cache if available or fetches its contents from the Parse
 servers. Sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 @result The data. Returns nil if there was an error in fetching.
 */
- (NSData *)getData:(NSError **)error;

/*!
 This method is like getData: but avoids ever holding the entire WYFile's
 contents in memory at once. This can help applications with many large WYFiles
 avoid memory warnings. Sets an error if it occurs.
 @param error Pointer to an NSError that will be set if necessary.
 @result A stream containing the data. Returns nil if there was an error in
 fetching.
 */
//- (NSInputStream *)getDataStream:(NSError **)error;

/*!
 Asynchronously gets the data from cache if available or fetches its contents
 from the Parse servers. Executes the given block.
 @param block The block should have the following argument signature: (NSData *result, NSError *error)
 */
- (void)getDataInBackgroundWithBlock:(WYDataResultBlock)block;

/*!
 This method is like getDataInBackgroundWithBlock: but avoids ever holding the
 entire WYFile's contents in memory at once. This can help applications with
 many large WYFiles avoid memory warnings.
 @param block The block should have the following argument signature: (NSInputStream *result, NSError *error)
 */
//- (void)getDataStreamInBackgroundWithBlock:(WYDataStreamResultBlock)block;

/*!
 Asynchronously gets the data from cache if available or fetches its contents
 from the Parse servers. Executes the resultBlock upon
 completion or error. Executes the progressBlock periodically with the percent progress. progressBlock will get called with 100 before resultBlock is called.
 @param resultBlock The block should have the following argument signature: (NSData *result, NSError *error)
 @param progressBlock The block should have the following argument signature: (int percentDone)
 */
- (void)getDataInBackgroundWithBlock:(WYDataResultBlock)resultBlock
                       progressBlock:(WYProgressBlock)progressBlock;

/*!
 This method is like getDataInBackgroundWithBlock:progressBlock: but avoids ever
 holding the entire WYFile's contents in memory at once. This can help
 applications with many large WYFiles avoid memory warnings.
 @param resultBlock The block should have the following argument signature: (NSInputStream *result, NSError *error)
 @param progressBlock The block should have the following argument signature: (int percentDone)
 */
/*
- (void)getDataStreamInBackgroundWithBlock:(WYDataStreamResultBlock)resultBlock
                             progressBlock:(WYProgressBlock)progressBlock;
*/


/** @name Interrupting a Transfer */

/*!
 Cancels the current request (whether upload or download of file data).
 */
- (void)cancel;

-(void)afterDecoder;

@end
