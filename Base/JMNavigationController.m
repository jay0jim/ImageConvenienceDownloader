//
//  JMNavigationController.m
//  JMBaseNavigation
//
//  Created by Tony Lee on 2019/5/29.
//  Copyright © 2019 Tony. All rights reserved.
//

#import "JMNavigationController.h"

@interface JMNavigationController ()

@end

@implementation JMNavigationController

+ (void)initialize {
    //appearance方法返回一个导航栏的外观对象
    //修改了这个外观对象，相当于修改了整个项目中的外观
    UINavigationBar *navigationBar = [UINavigationBar appearance];
    //设置导航栏背景颜色
    [navigationBar setBarTintColor:JMHexColorRGB(0xFBFBFB)];
    // 去掉下方黑色阴影线
    navigationBar.shadowImage = [[UIImage alloc] init];
//    [navigationBar setBackgroundImage:[[UIImage alloc] init] forBarPosition:UIBarPositionAny barMetrics:UIBarMetricsDefault];
    navigationBar.tintColor = [UIColor blackColor];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}


@end
