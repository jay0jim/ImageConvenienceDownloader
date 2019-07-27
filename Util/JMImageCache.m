//
//  JMImageCache.m
//  ImageConvenienceDownloader
//
//  Created by Tony on 2019/7/26.
//  Copyright © 2019 Tony. All rights reserved.
//

#import "JMImageCache.h"

static NSString *dicFileName = @"pathDic.plist";

@interface JMImageCache ()

@property (strong, nonatomic) NSString *homeDir;
@property (strong, nonatomic) NSString *storageDir;

@property (strong, nonatomic) dispatch_queue_t ioQueue;

@property (strong, nonatomic) NSMutableDictionary *storageDic;

@end

@implementation JMImageCache

+ (id)defaultCache {
    static JMImageCache *defaultCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        defaultCache = [[JMImageCache alloc] init];
    });
    return defaultCache;
}

- (instancetype)init {
    if (self = [super init]) {
        self.storageGroup = @"default";
        // 储存组的名称
        self.storageDic = [[NSMutableDictionary alloc] initWithCapacity:10];
        [self.storageDic setObject:self.storageGroup forKey:self.storageGroup];
        
        //获取沙盒路径
        self.homeDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES) objectAtIndex:0];
//        NSLog(@"%@", homeDir);
        self.storageDir = [self.homeDir stringByAppendingPathComponent:self.storageGroup];
//        NSLog(@"%@", defaultPath);
        
        // 创建文件夹
        NSFileManager *fm = [NSFileManager defaultManager];
        if (![fm fileExistsAtPath:self.storageDir]) {
            [fm createDirectoryAtPath:self.storageDir withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        // 初始化串行队列
        self.ioQueue = dispatch_queue_create("ioQueue", DISPATCH_QUEUE_SERIAL);
        
        // 初始化地址字典
        NSString *dicPath = [self.homeDir stringByAppendingPathComponent:dicFileName];
        if ([fm fileExistsAtPath:dicPath]) {
            self.cachePathDic = [[NSMutableDictionary alloc] initWithContentsOfFile:dicPath];
        } else {
            self.cachePathDic = [[NSMutableDictionary alloc] initWithCapacity:100];
            [self.cachePathDic writeToFile:dicPath atomically:YES];
        }
    }
    return self;
}

#pragma mark - Setter
- (void)setStorageGroup:(NSString *)storageGroup {
    _storageGroup = storageGroup;
    self.storageDir = [self.homeDir stringByAppendingPathComponent:storageGroup];
    [self.storageDic setObject:self.storageGroup forKey:self.storageGroup];
    
    // 创建文件夹
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:self.storageDir]) {
        [fm createDirectoryAtPath:self.storageDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
}

#pragma mark - Public Method
- (NSURL *)createFullStoragePathWithFileName:(NSString *)fileName {
    NSString *fullPath = [self.storageDir stringByAppendingPathComponent:fileName];
    NSURL *fileURL = [NSURL fileURLWithPath:fullPath];
    return fileURL;
}

- (void)saveImagePath:(NSURL *)path withKey:(NSString *_Nonnull)key{
    dispatch_async(self.ioQueue, ^{
        NSArray *pathComponents = [path pathComponents];
        NSString *storePath = [NSString stringWithFormat:@"%@/%@", pathComponents[pathComponents.count-2], pathComponents[pathComponents.count-1]];
//        NSLog(@"%@", storePath);
        [self.cachePathDic setObject:storePath forKey:key];
        NSString *dicPath = [self.homeDir stringByAppendingPathComponent:dicFileName];
        [self.cachePathDic writeToFile:dicPath atomically:YES];
    });
}

- (NSString *)getIamgePathWithKey:(NSString *_Nonnull)key {
    NSString *storePath = [self.cachePathDic objectForKey:key];
    if (storePath == nil) {
        return nil;
    } else {
        NSString *fullPath = [self.homeDir stringByAppendingPathComponent:storePath];
        return fullPath;
    }
}

#pragma mark - Check Cache
- (BOOL)existCacheWithKey:(NSString *_Nonnull)key {
    NSString *pathStr = [self getIamgePathWithKey:key];
    if (pathStr == nil) {
        return NO;
    }
    BOOL e = [[NSFileManager defaultManager] fileExistsAtPath:pathStr];
    return e;
    
}

#pragma mark - Removing
- (void)removeAllCache {
    NSArray *keys = [self.storageDic allKeys];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    for (NSString *key in keys) {
        NSString *path = [self.homeDir stringByAppendingPathComponent:key];
        dispatch_sync(self.ioQueue, ^{
            if ([fm fileExistsAtPath:path]) {
                [fm removeItemAtPath:path error:nil];
                [self.storageDic removeObjectForKey:key];
            }
        });
    }
    
    // 删除地址字典
    NSString *dicPath = [self.homeDir stringByAppendingPathComponent:dicFileName];
    if ([fm fileExistsAtPath:dicPath]) {
        [fm removeItemAtPath:dicPath error:nil];
        [self.cachePathDic removeAllObjects];
    }
}

- (void)removeCacheWithKeys:(NSArray *)keys {

    NSFileManager *fm = [NSFileManager defaultManager];

    for (NSString *key in keys) {
        dispatch_sync(self.ioQueue, ^{
            NSString *path = [self.cachePathDic objectForKey:key];
            if (path != nil) {
                NSString *fullPath = [self.homeDir stringByAppendingPathComponent:path];
                if ([fm fileExistsAtPath:fullPath]) {
                    [fm removeItemAtPath:fullPath error:nil];
                    
                    [self.cachePathDic removeObjectForKey:key];
                    NSString *dicPath = [self.homeDir stringByAppendingPathComponent:dicFileName];
                    [self.cachePathDic writeToFile:dicPath atomically:YES];
                }
            } else {
                NSLog(@"No such file!");
            }
        });
    } // for
}

@end
