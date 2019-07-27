//
//  JMImageCache.h
//  ImageConvenienceDownloader
//
//  Created by Tony on 2019/7/26.
//  Copyright © 2019 Tony. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface JMImageCache : NSObject

/**
 文件管理，把图片缓存到指定的组（文件夹）中，默认组为default
 */
@property (strong, nonatomic) NSString *storageGroup;

/**
 保存成功下载的图片的文件地址
 */
@property (strong, nonatomic) NSMutableDictionary *cachePathDic;


+ (id)defaultCache;

/**
 生成完整的文件存储路径

 @param fileName 文件名
 @return 返回完整存储路径的fileURL
 */
- (NSURL *)createFullStoragePathWithFileName:(NSString *)fileName;

/**
 保存成功下载的文件的本地地址

 @param path 文件储存地址
 @param key key（推荐使用下载地址url作为key）
 */
- (void)saveImagePath:(NSURL *)path withKey:(NSString *_Nonnull)key;
- (NSString *)getIamgePathWithKey:(NSString *_Nonnull)key;

- (BOOL)existCacheWithKey:(NSString *_Nonnull)key;

/**
 删除所有缓存，在其他线程的串行队列中执行，耗时操作
 */
- (void)removeAllCache;

/**
 删除指定组中指定keys的文件，在其他线程的串行队列中执行，耗时操作

 @param keys 待删除文件的keys（一般为url string）
 */
- (void)removeCacheWithKeys:(NSArray *_Nonnull)keys;

@end

NS_ASSUME_NONNULL_END
