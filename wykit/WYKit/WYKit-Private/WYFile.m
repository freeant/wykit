//
//  WYFile.m
//  Whirl
//
//  Created by Zhong Fanglin on 9/19/14.
//  Copyright (c) 2014 Whirl. All rights reserved.
//

#import "WYFile.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "WYConstants-Private.h"
#import "WYKit.h"
#import "WYKit-Private.h"
#import "AFNetworking.h"
#import "EGOCache.h"
#import "WYNetworkActivity.h"
#import "WYKit-Private.h"
#import "AutoCoding.h"

@interface WYFile()<NSCopying>

@property(nonatomic,assign) BOOL isLoading;
@property(nonatomic,retain) NSData *data;
@property(nonatomic,readonly) NSString *contentType;
@property(nonatomic,retain) AFHTTPRequestOperation *requestOperation;
@property(nonatomic,copy) NSString *localCacheId;

-(void)uploadSuccess:(id)responseObject;


@end

@implementation WYFile

+ (NSString*) fileMIMEType:(NSString*) file {
    CFStringRef UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)[file pathExtension], NULL);
    CFStringRef MIMEType = UTTypeCopyPreferredTagWithClass (UTI, kUTTagClassMIMEType);
    CFRelease(UTI);
    return (__bridge NSString *)(MIMEType);
}

+ (instancetype)fileWithData:(NSData *)data {
    return [[self alloc] initWithName:nil data:data contentType:nil];
}

+ (instancetype)fileWithName:(NSString *)name data:(NSData *)data {
    return [[self alloc] initWithName:name data:data contentType:nil];
}

+ (instancetype)fileWithName:(NSString *)name
              contentsAtPath:(NSString *)path {
    NSData *data = [NSData dataWithContentsOfFile:path];
    return [[self alloc] initWithName:name data:data contentType:[self fileMIMEType:path]];
}

+ (instancetype)fileWithName:(NSString *)name
                        data:(NSData *)data
                 contentType:(NSString *)contentType {
    return [[self alloc] initWithName:name data:data contentType:contentType];
}

+ (instancetype)fileWithData:(NSData *)data contentType:(NSString *)contentType {
    return [[self alloc] initWithName:nil data:data contentType:contentType];
}

- (id)copyWithZone:(NSZone *)zone {
    WYFile *copy = [[[self class] allocWithZone:zone] initWithFile:self];
    return copy;
}

-(instancetype)initWithFile:(WYFile*)wyFile {
    self = [super init];
    if (self) {
        _name = wyFile.name;
        _data = wyFile.data;
        _contentType = wyFile.contentType;
        _isDirty = wyFile.isDirty;
        _isDataAvailable = _data != nil;
        _url = wyFile.url;
        _localCacheId = wyFile.localCacheId;
        
        if (_name == nil || _url == nil) {
            _isDirty = YES;
            if (_localCacheId && _data == nil) {
                _data = [[EGOCache globalCache] dataForKey:_localCacheId];
            }
        }
    }
    return self;
}

-(void)afterDecoder {
    if (_name == nil || _url == nil) {
        _isDirty = YES;
        if (_localCacheId && _data == nil) {
            _data = [[EGOCache globalCache] dataForKey:_localCacheId];
        }
    }
}

+ (NSString *)generateUUID
{
    NSString *result = nil;
    
    CFUUIDRef uuid = CFUUIDCreate(NULL);
    if (uuid)
    {
        result = (__bridge_transfer NSString *)CFUUIDCreateString(NULL, uuid);
        CFRelease(uuid);
    }
    
    return result;
}

-(instancetype)initWithName:(NSString*)name data:(NSData*)data contentType:(NSString *)contentType {
    self = [super init];
    if (self) {
        _name = name;
        _data = data;
        _contentType = contentType;
        _isDirty = YES;
        _isDataAvailable = _data != nil;
        if (_data != nil) {
            _localCacheId = [NSString stringWithFormat:@"Local_WYFile_%@",[WYFile generateUUID]];
            [[EGOCache globalCache] setData:data forKey:_localCacheId withTimeoutInterval:60*60*24*30];
        }
    }
    return self;
}

- (BOOL)save {
    return [self save:NULL];
}

- (BOOL)save:(NSError **)error {
    if (!_isDirty && _url != nil) {
        return YES;
    }
    // Check if data is set
    if (self.data.length == 0) {
        [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Cannot save file with no data set", nil)];
        return NO;
    }
    
    NSURL *URL = [WYKit endpointForMethod:kWYFileMethod];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    req.HTTPBody = self.data;
    req.HTTPMethod = @"POST";
    
    NSString *contentLen = [NSString stringWithFormat:@"%lu", (unsigned long)self.data.length];
    [req setValue:contentLen forHTTPHeaderField:@"Content-Length"];
    if (_contentType) {
        [req setValue:_contentType forHTTPHeaderField:@"Content-Type"];
    } else {
        [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    }
    
    [req setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];
    if (_name.length > 0) {
        [req setValue:_name forHTTPHeaderField:kWYKitRequestHeaderFileName];
    }
    
    NSError *reqError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&reqError];
    
    // End network activity
    _isLoading = NO;
    [WYNetworkActivity end];
    if (reqError == nil && data.length >0 ) {
        NSError *JSONError = nil;
        id fileResponse = [NSJSONSerialization JSONObjectWithData:data
                                        options:NSJSONReadingAllowFragments
                                          error:&JSONError];
        if (fileResponse) {
            [self uploadSuccess:fileResponse];
            return YES;
        } else if(error != NULL) {
            *error = JSONError;
        }
        
    }
    if (error != NULL) {
        *error = reqError;
    }
    return NO;
}

- (void)saveInBackground {
    [self saveInBackgroundWithBlock:NULL progressBlock:NULL];
}

- (void)saveInBackgroundWithBlock:(WYBooleanResultBlock)block {
    [self saveInBackgroundWithBlock:block progressBlock:NULL];
}

-(void)saveInBackgroundWithBlock:(WYBooleanResultBlock)block progressBlock:(WYProgressBlock)progressBlock {
    _saveResultBlock = block;
    if (!_isDirty && _url != nil) {
        if (_saveResultBlock) {
            _saveResultBlock(YES,nil);
        }
        if (progressBlock) {
            progressBlock(100);
        }
        return;
    }
    // Check if data is set
    if (self.data.length == 0) {
        [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Cannot save file with no data set", nil)];
        return;
    }
    
    NSURL *URL = [WYKit endpointForMethod:kWYFileMethod];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    req.HTTPBody = self.data;
    req.HTTPMethod = @"POST";
    
    NSString *contentLen = [NSString stringWithFormat:@"%lu", (unsigned long)self.data.length];
    [req setValue:contentLen forHTTPHeaderField:@"Content-Length"];
    if (_contentType) {
        [req setValue:_contentType forHTTPHeaderField:@"Content-Type"];
    } else {
        [req setValue:@"application/octet-stream" forHTTPHeaderField:@"Content-Type"];
    }
    
    [req setValue:[WYKit getClientKey] forHTTPHeaderField:kWYKitRequestHeaderSecret];
    if (_name.length > 0) {
        [req setValue:_name forHTTPHeaderField:kWYKitRequestHeaderFileName];
    }
    

    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    _requestOperation = op;
    op.responseSerializer = [AFJSONResponseSerializer serializer];
    __weak __typeof(self) weakSelf = self;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf) strongWeakSelf = weakSelf;
        strongWeakSelf.isLoading = NO;
        [WYNetworkActivity end];
        [strongWeakSelf uploadSuccess:responseObject];
        strongWeakSelf.requestOperation = nil;
        if (strongWeakSelf.saveResultBlock) {
            strongWeakSelf.saveResultBlock(YES,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        __strong __typeof(weakSelf) strongWeakSelf = weakSelf;
        strongWeakSelf.isLoading = NO;
        [WYNetworkActivity end];
        strongWeakSelf.requestOperation = nil;
        if (strongWeakSelf.saveResultBlock) {
            strongWeakSelf.saveResultBlock(NO,error);
        }
    }];
    [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        if (progressBlock) {
            progressBlock((int)(totalBytesWritten/totalBytesExpectedToWrite)*100);
        }
    }];
    _isLoading = YES;
    [WYNetworkActivity begin];
    [[NSOperationQueue mainQueue] addOperation:op];
}

- (NSData *)getData {
    return [self getData:NULL];
}

-(NSData *)getData:(NSError *__autoreleasing *)error {
    if (_data) {
        return _data;
    }
    
    if (_localCacheId != nil) {
        _data = [[EGOCache globalCache] dataForKey:_localCacheId];
        if (_data ) {
            return _data;
        }
    }
    
    _data = [[EGOCache globalCache] dataForKey:keyForURL(_url,nil)];
    if (_data) {
        return _data;
    }
    
    if (_url == nil || _url.length == 0) {
        [NSException raise:NSInternalInconsistencyException format:NSLocalizedString(@"Cannot get file data with no url", nil)];
        return nil;
    }
    
    NSURL *URL = [NSURL URLWithString:_url];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    NSError *reqError = nil;
    NSHTTPURLResponse *response = nil;
    NSData *data = [NSURLConnection sendSynchronousRequest:req returningResponse:&response error:&reqError];
    // End network activity
    self.isLoading = NO;
    [WYNetworkActivity end];
    
    if (response.statusCode == 200) {
        [self downloadSuccess:data];
        return data;
    }
    else {
        if (error != NULL) {
            *error = reqError;
        }
    }
    return nil;
}

- (void)getDataInBackgroundWithBlock:(WYDataResultBlock)block {
    [self getDataInBackgroundWithBlock:block progressBlock:NULL];
}

- (void)getDataInBackgroundWithBlock:(WYDataResultBlock)resultBlock
                       progressBlock:(WYProgressBlock)progressBlock {
    
    _fetchDataResultBlock = resultBlock;
    if (_data == nil) {
        _data = [[EGOCache globalCache] dataForKey:keyForURL(_url,nil)];
    }
    
    if (_data == nil &&  _localCacheId != nil) {
        _data = [[EGOCache globalCache] dataForKey:_localCacheId];
    }
    
    if (_data) {
        if (_fetchDataResultBlock) {
            _fetchDataResultBlock(_data,nil);
        }
        if (progressBlock) {
            progressBlock(100);
        }
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:_url];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:URL];
    req.cachePolicy = NSURLRequestReloadIgnoringLocalAndRemoteCacheData;
    
    
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc] initWithRequest:req];
    _requestOperation = op;
    __weak __typeof(self) weakSelf = self;
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        __strong __typeof(weakSelf) strongWeakSelf = weakSelf;
        strongWeakSelf.isLoading = NO;
        [WYNetworkActivity end];
        [strongWeakSelf downloadSuccess:responseObject];
        strongWeakSelf.requestOperation = nil;
        if (strongWeakSelf.fetchDataResultBlock) {
            strongWeakSelf.fetchDataResultBlock(responseObject,nil);
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        if (error.code == -999) {
            return;
        }
        __strong __typeof(weakSelf) strongWeakSelf = weakSelf;
        strongWeakSelf.isLoading = NO;
        [WYNetworkActivity end];
        strongWeakSelf.requestOperation = nil;
        if (strongWeakSelf.fetchDataResultBlock) {
            strongWeakSelf.fetchDataResultBlock(nil,error);
        }
    }];
    
    [op setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        if (progressBlock) {
            progressBlock((int)(totalBytesRead/totalBytesExpectedToRead)*100);
        }
    }];
    _isLoading = YES;
    [WYNetworkActivity begin];
    [[NSOperationQueue mainQueue] addOperation:op];
}

-(void)cancel {
    if (_requestOperation && [_requestOperation isExecuting]) {
        [_requestOperation cancel];
        _requestOperation = nil;
    }
}

// private implements
-(void)uploadSuccess:(id)responseObject {
    _isDirty = NO;
    _name =  [responseObject valueForKey:@"name"];
    _url = [responseObject valueForKey:@"url"];
}

-(void)downloadSuccess:(NSData*)data {
    _isDirty = NO;
    _isDataAvailable = YES;
    _data = data;
    [[EGOCache globalCache] setData:_data forKey:keyForURL(_url,nil) withTimeoutInterval:60*60*24*30];
    
}

-(instancetype)initWithName:(NSString*)name url:(NSString*)url {
    self = [super init];
    if (self) {
        _name = name;
        _url = url;
        _isDataAvailable = NO;
        _isDirty = NO;
    }
    return self;
}

-(instancetype)initWithJsonObject:(id)jsonObject {
    return [self initWithName:[jsonObject valueForKey:@"name"] url:[jsonObject valueForKey:@"url"]];
}

-(NSDictionary*)toJsonObject {
    return @{@"__type":@"File",@"name":_name,@"url":_url};
}

inline static NSString* keyForURL(NSString* url, NSString* style) {
    if(style) {
        return [NSString stringWithFormat:@"WYFile-%lu-%lu", (unsigned long)[url hash], (unsigned long)[style hash]];
    } else {
        return [NSString stringWithFormat:@"WYFile-%lu", (unsigned long)[url hash]];
    }
}

-(NSArray*)excludeProperties {
    return @[@"requestOperation",@"isLoading",@"data",@"contentType",@"isDirty"];
}


@end
