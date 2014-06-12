//
//  AppDelegate.m
//  zhubao
//
//  Created by johnson on 14-5-27.
//  Copyright (c) 2014年 SUNYEARS___FULLUSERNAME. All rights reserved.
//

#import "AppDelegate.h"

@implementation AppDelegate
@synthesize window = _window;
@synthesize entityl;
@synthesize queue;


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    // Override point for customization after application launch.
    [application setStatusBarHidden:YES withAnimation:UIStatusBarAnimationFade];
    
    //初始化
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    //首次打开APP 创建缓存文件夹
    if ([[NSUserDefaults standardUserDefaults]objectForKey:@"firstLaunch"]==nil) {
        [[NSFileManager defaultManager] createDirectoryAtPath:pathInCacheDirectory(@"com.xmly") withIntermediateDirectories:YES attributes:nil error:nil];
        [[NSUserDefaults standardUserDefaults]setObject:[NSNumber numberWithBool:YES] forKey:@"firstLaunch"];
    }
    
    //判断系统是否已初始化
    sqlService * sqlSer = [[sqlService alloc] init];
    
    //复制数据库到指定的目录
    if(![self initializeDb]){
        
        NSLog(@"couldn't 复制数据库到指定的目录");
    }
    //真正初始化数据库
    if(![sqlSer openDB])
    {
        NSLog(@"couldn't 初始化数据库 ");
    }

    //初始化实体
    self.entityl=[[LoginEntity alloc] init];
    entityl.uId=@"0";
    
    //创建队列
    queue = [[ASINetworkQueue alloc] init];
    //[queue reset];//重置
    [queue setShowAccurateProgress:YES];//高精度进度
    [queue go];//启动
    
    //系统新安装未初始化
    login * lo = [[login alloc] init];
    //ceshi *lo = [[ceshi alloc] initWithNibName:@"ceshi" bundle:nil] ;
    
    UINavigationController * loginNav = [[UINavigationController alloc] initWithRootViewController:lo];
    
    self.window.rootViewController = loginNav;
    
    [self.window makeKeyAndVisible];
    return YES;
}
							
- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

//将根目录下面的数据库文件复制到sqlite的指定目录下面
-(BOOL)initializeDb{
    
	//NSLog(@"initializeDB");
    
	//look to see if DB is in known location (~/Documents/$DATABASE_FILE_NAME)
	//START:code.DatabaseShoppingList.findDocumentsDirectory
	NSArray*searchPaths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask,YES);
    
	NSString * documentFolderPath=[searchPaths objectAtIndex:0];
    
	//查看文件目录
    
	NSLog(@"查看文件目录:%@",documentFolderPath);
    
	NSString * dbFilePath=[documentFolderPath stringByAppendingPathComponent:kFileallname];
    
	//END:code.DatabaseShoppingList.findDocumentsDirectory
    
    //[dbFilePath retain];
    
    //START:code.DatabaseShoppingList.copyDatabaseFileToDocuments
    
    if(![[NSFileManager defaultManager] fileExistsAtPath:dbFilePath]){
        
        //didn't find db,need to copy
        
        NSString*backupDbPath=[[NSBundle mainBundle]pathForResource:kfilename ofType:kfiletype];
        
        if(backupDbPath==nil){
            
            //couldn't find backup db to copy,bail
            
            return NO;
            
        }else{
            
            BOOL copiedBackupDb=[[NSFileManager defaultManager] copyItemAtPath:backupDbPath toPath:dbFilePath error:nil];
            
            if(!copiedBackupDb){
                
                //copying backup db failed,bail
                
                return NO;
                
            }
            NSLog(@"数据库拷贝成功");
        }
        
    }
    
    //NSLog(@"bottomo finitialize Db");
    
    return YES;
    
    //END:code.DatabaseShoppingList.copyDatabaseFileToDocuments
}

-(void)beginRequest:(NSString *)fileurl fileName:(NSString *)fileName version:(NSString *)version
{
    AppDelegate *myDelegate = [[UIApplication sharedApplication] delegate];
    
    //如果不存在则创建临时存储目录
    NSFileManager *fileManager=[NSFileManager defaultManager];
    if(![fileManager fileExistsAtPath:[Tool getTempFolderPath]])
    {
        [fileManager createDirectoryAtPath:[Tool getTempFolderPath] withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    NSLog(@"创建请求----文件名：%@------请求路径：%@",fileName,fileurl);
    //初始化Documents路径
    NSString *downloadPath = [[Tool getTargetFloderPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",fileName]];
    NSString *tempPath = [[Tool getTempFolderPath] stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.temp",fileName]];
    NSURL *url = [NSURL URLWithString:fileurl];
    
    //创建请求
    ASIHTTPRequest *request = [ASIHTTPRequest requestWithURL:url];
    request.delegate = self;//代理
    [request setDownloadDestinationPath:downloadPath];//下载路径
    [request setTemporaryFileDownloadPath:tempPath];//缓存路径
    [request setAllowResumeForFileDownloads:YES];//断点续传
    [request setNumberOfTimesToRetryOnTimeout:5];//设置请求超时时，设置重试的次数
    [request setTimeOutSeconds:60.0f];//设置超时的时间
    request.downloadProgressDelegate = self;//下载进度代理
    
    [request setUserInfo:[NSDictionary dictionaryWithObjectsAndKeys:downloadPath, @"downloadPath", version, @"version", nil]];//设置上下文的文件基本信息
    
    [queue addOperation:request];//添加到队列，队列启动后不需重新启动
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        NSLog(@"有了--------");
    }
    else {
        NSLog(@"没有--------");
    }
}

#pragma ASIHttpRequest回调委托

//出错了，如果是等待超时，则继续下载
-(void)requestFailed:(ASIHTTPRequest *)request
{
    NSError *error=[request error];
    NSLog(@"ASIHttpRequest出错了!%@",error);
    //[request cancel];
    //request=nil;
}

-(void)requestStarted:(ASIHTTPRequest *)request
{
    NSLog(@"开始了!");
}

-(void)requestReceivedResponseHeaders:(ASIHTTPRequest *)request
{
    
    NSLog(@"收到回复了！------:%@",[[request responseHeaders] objectForKey:@"Content-Length"]);
    
}

//将下载完成了
-(void)requestFinished:(ASIHTTPRequest *)request
{
    NSLog(@"将下载完成了!");//
    
    NSString *downloadPath=(NSString *)[request.userInfo objectForKey:@"downloadPath"];
    //NSString *version=(NSString *)[request.userInfo objectForKey:@"version"];
    
    NSLog(@"downloadPath======:%@",downloadPath);
    
    //    NSString *string = [[NSString alloc]initWithContentsOfFile:downloadPath encoding:NSUTF8StringEncoding error:nil];
    //
    //    NSLog(@"------------- this is :%@",string);
    //    NSArray  * array= [string componentsSeparatedByString:@"\r\n"];//换行符
    //
    //    //运行下载的内容（正常下是sql）
    //    sqlService * ser=[[sqlService alloc] init];
    
    //解压文件
    ZipArchive *zip = [[ZipArchive alloc] init];
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *dcoumentpath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
    // 压缩文件路径
    NSString* zipFilePath = downloadPath;//[dcoumentpath stringByAppendingString:@"/1.zip"];
    // 解压缩文件夹路径
    NSString* unzipPath = [dcoumentpath stringByAppendingString:@"/images"];
    
    NSLog(@"解压后的路径------%@",unzipPath);
    
    // 开始解压缩
    if([zip UnzipOpenFile:zipFilePath])
    {
        if(![zip UnzipFileTo:unzipPath overWrite:YES])
        {
            NSLog(@"-----------:解压失败");
        }
        [zip UnzipCloseFile];
    }
    
    
    [request cancel];
    request=nil;
}
@end
