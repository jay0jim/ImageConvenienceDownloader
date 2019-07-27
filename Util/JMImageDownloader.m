//
//  JMImageDownloader.m
//  ImageConvenienceDownloader
//
//  Created by Tony on 2019/7/25.
//  Copyright © 2019 Tony. All rights reserved.
//

#import "JMImageDownloader.h"

@interface JMImageDownloader ()

@property (strong, nonatomic) dispatch_queue_t processingQueue;
@property (strong, nonatomic) NSMutableDictionary *processingDic;

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
        
        self.processingQueue = dispatch_queue_create("ProcessingQueue", DISPATCH_QUEUE_SERIAL);
        self.processingDic = [[NSMutableDictionary alloc] initWithCapacity:10];
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
    
    // 把检测步骤放到串行队列中执行
    __block BOOL shouldProcess = NO;
    dispatch_sync(self.processingQueue, ^{
        NSString *urlStr = [url absoluteString];
        if ([self.processingDic objectForKey:urlStr] == nil) {
            [self.processingDic setObject:url forKey:urlStr];
            shouldProcess = YES;
        } else {
            NSLog(@"URL Processing...");
            shouldProcess = NO;
        }
    });
    
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
        
        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
        
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest:request progress:nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
            
            NSURL *fileURL = [self.imageCache createFullStoragePathWithFileName:[response suggestedFilename]];
            //        NSLog(@"desBlock -- %@", fileURL);
            
            return fileURL;
            
        } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
            
            // 任务完成后，将url从dic中去除
            dispatch_sync(self.processingQueue, ^{
                [self.processingDic removeObjectForKey:[url absoluteString]];
            });
            
            if (error == nil) {
                [self.imageCache saveImagePath:filePath withKey:[url absoluteString]];
                
                if (completionHandler) {
                    NSData *data = [NSData dataWithContentsOfURL:filePath];
                    completionHandler(data, filePath, error);
                }
            }
            
            
        }];
        [downloadTask resume];
    } // if should process
}

@end
