//
//  JMImageDownloader.m
//  ImageConvenienceDownloader
//
//  Created by Tony on 2019/7/25.
//  Copyright © 2019 Tony. All rights reserved.
//

#import "JMImageDownloader.h"
#import <pthread.h>

@interface JMImageDownloader () {
    AFURLSessionManager *m_manager;
    pthread_mutex_t     m_mutex;
}

@property (strong, nonatomic) NSMutableDictionary *downloadTasks;

@end

@implementation JMImageDownloader

+ (id)sharedInstance {
    static JMImageDownloader *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[JMImageDownloader alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {
        self.imageCache = [JMImageCache defaultCache];
        
        self.downloadTasks = @{}.mutableCopy;
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        m_manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        // 初始化互斥锁
        pthread_mutex_init(&m_mutex, NULL);
    }
    return self;
}

- (void)downloadImageWithURL:(NSURL *)url
                  completion:(DownloadCompletion)completionHandler {
    [self downloadImageWithURL:url
                 ForceDownload:NO
                    completion:completionHandler];
    
}

- (void)downloadImageWithURL:(NSURL *)url
               ForceDownload:(BOOL) forceDownload
                  completion:(DownloadCompletion)completionHandler {
    // 0、先检查url是否有在下载，如果有直接返回
    // 1、先在cache中查找是否存在已下载的图片，存在则直接调用completionHandler
    // 2、若不存在则使用AFN下载图片，并缓存到cache中
    // ps. 如果forceDownload为真，则跳过查找cache，并删除cache中对应的内容（若存在），再重新进行下载
    
    // 0、先检查url是否有在下载，如果有直接返回
    BOOL shouldProcess = NO;
    NSString *urlStr = [url absoluteString];
    
    pthread_mutex_lock(&m_mutex);
    if ([self.downloadTasks objectForKey:urlStr] == nil) {
        shouldProcess = YES;
    } else {
        NSLog(@"URL is Processing...");
        shouldProcess = NO;
    }
    pthread_mutex_unlock(&m_mutex);
    
    if (shouldProcess) {
        if (!forceDownload) {
            if ([self.imageCache existCacheWithKey:[url absoluteString]]) {
                // 缓存中存在文件地址
                NSString *pathStr = [self.imageCache getIamgePathWithKey:[url absoluteString]];
                NSURL *filePath = [NSURL fileURLWithPath:pathStr];
                NSData *data = [NSData dataWithContentsOfURL:filePath];
                NSLog(@"File already exist!");
                
                if (completionHandler) {
                    completionHandler(data, filePath, nil);
                } // if completionHanler
                return;
                
            } // if cache
        }
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        NSURLSessionDownloadTask *downloadTask = [m_manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            NSURL *fileURL = [self.imageCache createFullStoragePathWithFileName:[response suggestedFilename]];
            return fileURL;
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            // 任务完成后，将url从dic中去除
            [self.downloadTasks removeObjectForKey:[url absoluteString]];
            
            if (completionHandler) {
                if (error) {
                    completionHandler(nil, nil, error);
                } else {
                    [self.imageCache saveImagePath:filePath withKey:[url absoluteString]];
                    NSData *data = [NSData dataWithContentsOfURL:filePath];
                    completionHandler(data, filePath, nil);
                }// else
            }// if completion
            
        }];
        [self.downloadTasks setObject:downloadTask forKey:urlStr];
        [downloadTask resume];
    } // if should process
}

- (void)suspendTaskWithURL:(NSURL *)url {
    NSString *urlStr = [url absoluteString];
    NSURLSessionDownloadTask *downloadTask = [self.downloadTasks objectForKey:urlStr];
    if (downloadTask) {
        [downloadTask suspend];
    }
}

- (void)resumeTaskWithURL:(NSURL *)url {
    NSString *urlStr = [url absoluteString];
    NSURLSessionDownloadTask *downloadTask = [self.downloadTasks objectForKey:urlStr];
    if (downloadTask) {
        [downloadTask resume];
    }
}

@end
