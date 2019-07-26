//
//  JMImageDownloader.h
//  ImageConvenienceDownloader
//
//  Created by Tony on 2019/7/25.
//  Copyright © 2019 Tony. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "JMImageCache.h"

NS_ASSUME_NONNULL_BEGIN

typedef void(^DownloadCompletion)(NSData *data, NSURL *filePath, NSError *_Nullable error);

@interface JMImageDownloader : NSObject

/**
 缓存文件管理器，当使用单例模式创建ImageDownloader时，默认使用JMImageCache的默认单例
 */
@property (strong, nonatomic) JMImageCache *imageCache;

+ (id)sharedInstance;


- (void)downloadImageWithURL:(NSURL *)url
                  completion:(DownloadCompletion)completionHandler;
- (void)downloadImageWithURL:(NSURL *)url
               ForceDownload:(BOOL) forceDownload
                  completion:(DownloadCompletion)completionHandler;

@end

NS_ASSUME_NONNULL_END
