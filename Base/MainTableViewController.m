//
//  MainTableViewController.m
//  LearningCodes
//
//  Created by Tony on 2019/6/28.
//  Copyright © 2019 Tony. All rights reserved.
//

#import "MainTableViewController.h"



@interface MainTableViewController ()

@property (strong, nonatomic) NSArray *catagoryArray;

@end

@implementation MainTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.tableFooterView = [[UIView alloc] init];
    self.title = @"Image Downloader";
    
    self.catagoryArray = @[@"RunLoop", @"GCD", @"JS"];
    
    // test
    [self test];
    
}

#pragma mark - test
- (void)test {
    JMImageDownloader *downloader = [JMImageDownloader sharedInstance];
    NSArray *array = @[@"https://c-ssl.duitang.com/uploads/item/201701/16/20170116105642_a3EXe.jpeg", @"https://c-ssl.duitang.com/uploads/item/201702/04/20170204154039_iYy2k.thumb.700_0.jpeg", @"https://c-ssl.duitang.com/uploads/item/201701/16/20170116105642_a3EXe.jpeg", @"https://c-ssl.duitang.com/uploads/item/201702/04/20170204154039_iYy2k.thumb.700_0.jpeg", @"https://c-ssl.duitang.com/uploads/item/201701/16/20170116105642_a3EXe.jpeg", @"https://c-ssl.duitang.com/uploads/item/201702/04/20170204154039_iYy2k.thumb.700_0.jpeg", ];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_get_global_queue(0, 0);
    NSLog(@"Start download..");
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        for (NSString *urlStr in array) {
            dispatch_semaphore_t sema = dispatch_semaphore_create(0);
            dispatch_group_async(group, queue, ^{
                NSURL *url = [NSURL URLWithString:urlStr];
                [downloader downloadImageWithURL:url completion:^(NSData * _Nonnull data, NSURL * _Nonnull filePath, NSError * _Nullable error) {
                    NSLog(@"File downloaded to: %@", [filePath path]);
                    dispatch_semaphore_signal(sema);
                }];
            });
            dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
        }
        
        dispatch_group_notify(group, queue, ^{
            NSLog(@"All downloaded!");
//            NSLog(@"%@", downloader.imageCache.cachePathDic);
        });
    });
}

#pragma mark - Table view data source
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.catagoryArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainTableCell"];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"MainTableCell"];
    }
    
    cell.textLabel.text = self.catagoryArray[indexPath.row];
    
    
    return cell;
}



@end
