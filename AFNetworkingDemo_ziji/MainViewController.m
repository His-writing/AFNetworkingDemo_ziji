//
//  MainViewController.m
//  AFNetworkingDemo_ziji
//
//  Created by shuzhenguo on 15/5/19.
//  Copyright (c) 2015年 shuzhenguo. All rights reserved.
//

#import "MainViewController.h"
#import "AFNetworking.h"
#import "SSZipArchive.h"


@interface MainViewController ()<NSXMLParserDelegate>
@property (strong, nonatomic) AFHTTPClient *httpClient;
// 操作队列
@property (strong, nonatomic) NSOperationQueue *queue;

// UIImageView
@property (weak, nonatomic) UIImageView *imageView;
// 进度条
@property (weak, nonatomic) UIProgressView *progress;

@end

@implementation MainViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    self.queue = [[NSOperationQueue alloc]init];
    
    // 1. 检测联网状态
    UIButton *button1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button1 setFrame:CGRectMake(110, 200, 100, 40)];
    [button1 setTitle:@"连接状态" forState:UIControlStateNormal];
    [button1 addTarget:self action:@selector(reachability) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button1];
    
    // 2. JSON
    UIButton *button2 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button2 setFrame:CGRectMake(110, 250, 100, 40)];
    [button2 setTitle:@"JSON" forState:UIControlStateNormal];
    [button2 addTarget:self action:@selector(loadJSON) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button2];
    
    // 3. XML
    UIButton *button3 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button3 setFrame:CGRectMake(110, 300, 100, 40)];
    [button3 setTitle:@"XML" forState:UIControlStateNormal];
    [button3 addTarget:self action:@selector(loadXML) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button3];
    
    // 4. UIImageView
    UIButton *button4 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button4 setFrame:CGRectMake(110, 350, 100, 40)];
    [button4 setTitle:@"UIImageView" forState:UIControlStateNormal];
    [button4 addTarget:self action:@selector(loadImageView) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button4];
    
    UIImageView *imageView = [[UIImageView alloc]initWithFrame:CGRectMake(110, 50, 100, 100)];
    [self.view addSubview:imageView];
    self.imageView = imageView;
    
    // 5. 上传文件
    UIButton *button5 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button5 setFrame:CGRectMake(20, 400, 100, 40)];
    [button5 setTitle:@"上传图像" forState:UIControlStateNormal];
    [button5 addTarget:self action:@selector(uploadImage) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button5];
    
    UIProgressView *progress = [[UIProgressView alloc]initWithFrame:CGRectMake(20, 20, 280, 20)];
    [self.view addSubview:progress];
    // 进度条的数值是以百分比的形式体现的
    self.progress = progress;
    
    // 6. 断点续传
    UIButton *button6 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button6 setFrame:CGRectMake(180, 400, 100, 40)];
    [button6 setTitle:@"下载zip" forState:UIControlStateNormal];
    [button6 addTarget:self action:@selector(download) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:button6];

    
}
#pragma mark 断点续传
// AFN的文件下载，本身就是断点续传，不需要指定什么参数
- (void)download
{
    // 1. NSURL
    NSString *urlStr = @"http://localhost/~apple/itcast/download/10-iOS高级28-数据存取05-CoreData.mp4";
    // 如果有中文或者空格，需要加百分号
    
    NSURL *url = [NSURL URLWithString:[urlStr stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
    
    // 2. NSURLRequest
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    // 3. 定义Operation
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    
    // 下载文件—》要告诉op下载到哪里？
    // 输出流（数据在网络上都是以流的方式传输的）
    // 所谓输出流，就是让数据流流到哪里-》保存到沙箱
    NSArray *docs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    // 指定下载路径
    NSString *downloadPath = [docs[0]stringByAppendingPathComponent:@"download.zip"];
    
    [op setOutputStream:[NSOutputStream outputStreamToFileAtPath:downloadPath append:NO]];
    
    // 设置下载进度代码
    /**
     bytesRead      此次下载的字节数(5k)
     totalBytesRead 已经下载完成的字节数(80k)
     totalBytesExpectedToRead 文件总字节数(100k)
     */
    [op setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
        
        float percent = (float)totalBytesRead / totalBytesExpectedToRead;
        NSLog(@"%f", percent);
        
        [self.progress setProgress:percent animated:YES];
    }];
    
    // 设置下载完成块代码
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"下载完成");
        // 1. 进入沙箱检查下载文件
        
        // 2. 解压缩文件
        /*
         第一个参数：要解压缩的文件
         第二个参数：要将zip文件解压缩到的位置
         */
        [SSZipArchive unzipFileAtPath:downloadPath toDestination:docs[0]];
        
        // 3. 删除zip文件，替用户节省空间
        // 使用文件管理器，可以查找文件、可以删除文件
        [[NSFileManager defaultManager]removeItemAtPath:downloadPath error:nil];
        
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"下载失败");
    }];
    
    [op start];
    
}

#pragma mark 上传图像
- (void)uploadImage
{
    // 1. 定义httpClient
    // 所谓baseURL就是此后所有的请求都基于此地址
    NSURL *url = [NSURL URLWithString:@"http://localhost"];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:url];
    
    // 2. 根据httpClient生成post请求
    NSMutableURLRequest *request = [httpClient multipartFormRequestWithMethod:@"POST" path:@"/~apple/itcast/upload.php" parameters:nil constructingBodyWithBlock:^(id<AFMultipartFormData> formData) {
        
        // 提示：UIImage不能为空
        NSData *data = UIImagePNGRepresentation(self.imageView.image);
        
        /**
         参数说明：
         
         1. fileData:   要上传文件的数据
         2. name:       负责上传文件的远程服务中接收文件使用的字段名称
         3. fileName：   要上传文件的文件名
         4. mimeType：   要上传文件的文件类型
         
         提示，在日常开发中，如果要上传图片到服务器，一定记住不要出现文件重名的问题！
         这个问题，通常涉及到前端程序员和后端程序员的沟通。
         
         通常解决此问题，可以使用系统时间作为文件名！
         */
        // 1) 取当前系统时间
        NSDate *date = [NSDate date];
        // 2) 使用日期格式化工具
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        // 3) 指定日期格式
        [formatter setDateFormat:@"yyyyMMddHHmmss"];
        NSString *dateStr = [formatter stringFromDate:date];
        // 4) 使用系统时间生成一个文件名
        NSString *fileName = [NSString stringWithFormat:@"%@.png", dateStr];
        
        [formData appendPartWithFileData:data name:@"file" fileName:fileName mimeType:@"image/png"];
    }];
    
    // 准备做上传的工作！
    // 3. operation
    AFHTTPRequestOperation *op = [[AFHTTPRequestOperation alloc]initWithRequest:request];
    
    // 显示上传进度
    /*
     bytesWritten   本次上传的字节数(本次上传了5k)
     totalBytesWritten  已经上传的字节数(已经上传了80k)
     totalBytesExpectedToWrite  文件总字节数（100k）
     */
    [op setUploadProgressBlock:^(NSUInteger bytesWritten, long long totalBytesWritten, long long totalBytesExpectedToWrite) {
        
        [self.progress setProgress:(float)(totalBytesWritten / totalBytesExpectedToWrite)];
        
        NSLog(@"上传 %f", (float)(totalBytesWritten / totalBytesExpectedToWrite));
    }];
    
    [op setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        
        NSLog(@"上传文件成功");
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        NSLog(@"上传文件失败 %@", error);
    }];
    
    // 4. operation start
    [op start];
}

#pragma mark 加载UIImageView
// 提示：如果是异步加载表格图像，不建议使用此方法
// 还是需要使用图像的内存缓存或者磁盘缓存的方式处理
// 此方法，仅适用于单张独立的图像，而不要在表格中使用
- (void)loadImageView
{
    UIImage *image = [UIImage imageNamed:@"头像1.png"];
    
    NSURL *url = [NSURL URLWithString:@"http://localhost/~apple/itcast/images/head2.png"];
    
    [self.imageView setImageWithURL:url placeholderImage:image];
}

#pragma mark 加载XML
// 使用AFN加载XML，XML解析器的方法一个都不能少，还需要自己进行解析！
- (void)loadXML
{
    // 1. URL
    NSURL *url = [NSURL URLWithString:@"http://localhost/~apple/itcast/videos.php?format=xml"];
    
    // 2. Request
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:1.0f];
    
    // 3. 加载XML
    [self.queue setMaxConcurrentOperationCount:4];
    
    AFXMLRequestOperation *op = [AFXMLRequestOperation XMLParserRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, NSXMLParser *XMLParser) {
        
        // 1. 实例化解析器，并传入数据 AFN已经做了 XMLParser
        // 2. 设置代理
        [XMLParser setDelegate:self];
        // 3. 解析器解析
        [XMLParser parse];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, NSXMLParser *XMLParser) {
        
        NSLog(@"%@", error.localizedDescription);
    }];
    
    // 启动操作
    // 提示，因为都是后台的数据处理，这些任务是可以放在后台线程中实现的
    [self.queue addOperation:op];
}

#pragma mark - XML解析器代理方法
// 1. 开始
- (void)parserDidStartDocument:(NSXMLParser *)parser
{
    NSLog(@"解析文档开始 %@", [NSThread currentThread]);
}

// 2. 开始节点
// 3. 发现节点元素
// 4. 结束节点
// 5. 结束
// 6. 出错

#pragma mark 加载JSON
- (void)loadJSON
{
    // 1. URL
    NSURL *url = [NSURL URLWithString:@"http://10.0.0.1/~apple/itcast/videos.php?format=json"];
    
    // 2. Request
    NSURLRequest *request = [NSURLRequest requestWithURL:url cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:1.0f];
    
    // 原生的方法
    //    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse * response, NSData *data, NSError *error) {
    //
    //        // 1) 出错判断
    //
    //        // 2) 反序列化
    //        NSArray *array = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
    //    }];
    
    // 3. Connection
    // 实例化操作对象
    AFJSONRequestOperation *op = [AFJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        
        NSLog(@"%@", JSON);
        NSArray *array = JSON;
        
        // 将加载的数组写入plist
        [array writeToFile:@"/users/apple/Desktop/123.plist" atomically:YES];
        
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        
        NSLog(@"%@ %@", error.localizedDescription, JSON);
    }];
    
    // 启动操作
    [op start];
}

#pragma mark 检测联网状态
- (void)reachability
{
    // BaseURL在检测网络连接状态时，可以使用一些门户网站，例如：www.baidu.com
    NSURL *url = [NSURL URLWithString:@"http://www.baidu.com"];
    AFHTTPClient *httpClient = [AFHTTPClient clientWithBaseURL:url];
    self.httpClient = httpClient;
    
    [httpClient setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status) {
        
        switch (status) {
            case AFNetworkReachabilityStatusNotReachable:
                NSLog(@"无连接");
                break;
            case AFNetworkReachabilityStatusReachableViaWiFi:
                NSLog(@"WIFI连接");
                break;
            case AFNetworkReachabilityStatusReachableViaWWAN:
                NSLog(@"3G连接");
                break;
            case AFNetworkReachabilityStatusUnknown:
                NSLog(@"连接状态未知");
                break;
        }
    }];
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)click:(id)sender {
    
    
}
@end
