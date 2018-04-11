//
//  ViewController.m
//  SocketTest
//
//  Created by tangzhi on 2018/4/10.
//  Copyright © 2018年 candela. All rights reserved.
//

#import "ViewController.h"
#import "GCDAsyncSocket.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "GCDAsyncUdpSocket.h"
#import <arpa/inet.h>
#import <ifaddrs.h>

@interface ViewController ()<GCDAsyncSocketDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate,GCDAsyncUdpSocketDelegate>
{
    GCDAsyncSocket *_socket;
    GCDAsyncUdpSocket *_usocket;
    UIImageView *imgvw;
    UILabel *showLb;
    UITextView *contentTf;
    NSMutableData *imgdata;
    NSMutableArray *clientSockets;
    NSString *tcpServerIp;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    clientSockets = [NSMutableArray array];
    imgdata = [NSMutableData data];
    
    showLb = [[UILabel alloc]initWithFrame:CGRectMake(20, 40, self.view.frame.size.width - 40, 40)];
    showLb.backgroundColor = [UIColor colorWithWhite:.8 alpha:1];
    [self.view addSubview:showLb];
    
    contentTf = [[UITextView alloc]initWithFrame:CGRectMake(20, 90, self.view.frame.size.width - 190, 150)];
    contentTf.textColor = [UIColor blackColor];
    contentTf.layer.cornerRadius = 5;
    contentTf.font = [UIFont systemFontOfSize:14];
    contentTf.layer.masksToBounds = YES;
    contentTf.layer.borderWidth = 1;
    contentTf.layer.borderColor = [UIColor orangeColor].CGColor;
    [self.view addSubview:contentTf];
    
    imgvw = [[UIImageView alloc]initWithFrame:CGRectMake(self.view.frame.size.width - 160, 90, 150, 150)];
    imgvw.backgroundColor = [UIColor greenColor];
    [self.view addSubview:imgvw];
    
    UIButton *kvcUdp = [[UIButton alloc]initWithFrame:CGRectMake(20, 260, 120, 40)];
    [kvcUdp setTitle:@"监听UDP广播" forState:UIControlStateNormal];
    kvcUdp.backgroundColor = [UIColor orangeColor];
    [kvcUdp addTarget:self action:@selector(notifyUDPBroadCast) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:kvcUdp];
    
    UIButton *UDPBrodc = [[UIButton alloc]initWithFrame:CGRectMake(160, 260, 120, 40)];
    [UDPBrodc setTitle:@"UDP广播消息" forState:UIControlStateNormal];
    UDPBrodc.backgroundColor = [UIColor blueColor];
    [UDPBrodc addTarget:self action:@selector(udpBroadcast) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:UDPBrodc];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(300, 260, 100, 40)];
    [button setTitle:@"选择图片" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor blueColor];
    [button addTarget:self action:@selector(btnAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];

    UIButton *ljbutton = [[UIButton alloc]initWithFrame:CGRectMake(20, 320, 120, 40)];
    [ljbutton setTitle:@"TCP连接" forState:UIControlStateNormal];
    ljbutton.backgroundColor = [UIColor orangeColor];
    [ljbutton addTarget:self action:@selector(ljAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:ljbutton];
    
    UIButton *send = [[UIButton alloc]initWithFrame:CGRectMake(160, 320, 120, 40)];
    [send setTitle:@"TCP发送数据" forState:UIControlStateNormal];
    send.backgroundColor = [UIColor brownColor];
    [send addTarget:self action:@selector(sendDataAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:send];
    
    UIButton *startTcpServer = [[UIButton alloc]initWithFrame:CGRectMake(300, 320, 120, 40)];
    [startTcpServer setTitle:@"开启TCP服务" forState:UIControlStateNormal];
    startTcpServer.backgroundColor = [UIColor brownColor];
    [startTcpServer addTarget:self action:@selector(startTcpServerAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:startTcpServer];

    UIButton *deleteData = [[UIButton alloc]initWithFrame:CGRectMake(20, 380, 120, 40)];
    [deleteData setTitle:@"清空缓存" forState:UIControlStateNormal];
    deleteData.backgroundColor = [UIColor orangeColor];
    [deleteData addTarget:self action:@selector(deleteData) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:deleteData];
    
    UIButton *sendImg = [[UIButton alloc]initWithFrame:CGRectMake(160, 380, 120, 40)];
    [sendImg setTitle:@"TCP发送图片" forState:UIControlStateNormal];
    sendImg.backgroundColor = [UIColor brownColor];
    [sendImg addTarget:self action:@selector(sendAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:sendImg];
    
    _usocket = [[GCDAsyncUdpSocket alloc]initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
}

//情况imageData
- (void)deleteData {
    [imgdata resetBytesInRange:NSMakeRange(0, imgdata.length)];
    [imgdata setLength:0];
}

//开启tcp服务
- (void)startTcpServerAct {
    NSError *error = nil;
    [_socket acceptOnPort:7777 error:&error];
    
    //3.开启服务(实质第二步绑定端口的同时默认开启服务)
    if (error == nil)
    {
        NSLog(@"开启成功");
        showLb.text = @"服务器开启成功 端口：7777";
    }
    else
    {
        NSLog(@"开启失败");
        showLb.text = @"服务器开启失败";
    }
}

//连接tcp服务器
- (void)ljAct {
    NSLog(@"连接服务器");
    showLb.text = @"正在连接服务器";
    NSError *error = nil;
    [_socket connectToHost:tcpServerIp onPort:7777 withTimeout:20 error:&error];
}

//tcp发送数据
- (void)sendDataAct {
    if (contentTf.text.length == 0) {
        return ;
    }
    NSString *str = contentTf.text;;
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    [_socket writeData:data withTimeout:20 tag:35];
}

//tcp发送图片
- (void)sendAct {
    if (!imgvw.image) {
        return ;
    }
    UIImage *img = imgvw.image;
    NSData *imageData = UIImagePNGRepresentation(img);
//    NSData *data = [NSData dataWithBytes:"\0A" length:1];
//    NSMutableData *msgData = [NSMutableData data];
//    [msgData appendData:data];
//    [msgData appendData:imageData];
    [_socket writeData:imageData withTimeout:20 tag:34];
}

//UDP广播数据
- (void)udpBroadcast {
    NSString *str = contentTf.text;;
    NSData *data = [str dataUsingEncoding:NSUTF8StringEncoding];
    NSError *error1 = nil;
    [_usocket enableBroadcast:YES error:&error1];
    NSArray *strArr = [[self deviceIPAdress] componentsSeparatedByString:@"."];
    NSMutableArray *muArr = [NSMutableArray arrayWithArray:strArr];
    // 将数组的最后一位换成255
    [muArr replaceObjectAtIndex:(strArr.count-1) withObject:@"255"];
    // 将数组用.连接成目标IP地址字符串
    NSString *finalStr = [muArr componentsJoinedByString:@"."];// 目标ip
    [_usocket sendData:data toHost:finalStr port:3344 withTimeout:-1 tag:0];
}

//监听UDP广播
- (void)notifyUDPBroadCast {
    NSError * error1 = nil;
    BOOL ret = [_usocket bindToPort:3344 error:&error1];
    NSLog(@"%d",ret);
    if (error1) {//监听错误打印错误信息
        NSLog(@"error:%@",error1);
    }else {//监听成功则开始接收信息
        ret = [_usocket beginReceiving:&error1];
        NSLog(@"%d",ret);
        showLb.text = @"UDP监听成功，开使接收广播";
    }
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didSendDataWithTag:(long)tag
{
    NSLog(@"发送信息成功");
    dispatch_async(dispatch_get_main_queue(), ^{
        showLb.text = @"UDP广播成功";
    });
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didNotSendDataWithTag:(long)tag dueToError:(NSError *)error
{
    NSLog(@"发送信息失败");
    dispatch_async(dispatch_get_main_queue(), ^{
        showLb.text = @"UDP广播失败";
    });
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data fromAddress:(NSData *)address withFilterContext:(id)filterContext
{
    NSLog(@"接收到的消息");//自行转换格式吧
    NSString *addr = [GCDAsyncUdpSocket hostFromAddress:address];
    if ([GCDAsyncUdpSocket isIPv4Address:address]) {
        NSLog(@"%@ >>> this address is ipv4!",addr);
        tcpServerIp = addr;
        dispatch_async(dispatch_get_main_queue(), ^{
            showLb.text = [NSString stringWithFormat:@"UDP广播地址%@ 数据：%@",addr,[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]];
        });
    }
    if ([GCDAsyncUdpSocket isIPv6Address:address]) {
        NSLog(@"%@ >>> this address is ipv6!",addr);
    }
    NSLog(@"%@",[[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding]);
}

- (void)btnAct {
    [self showActionSheet];
}
#pragma mark GCDAsyncSocketDelegate
//连接到客户端socket
- (void)socket:(GCDAsyncSocket *)sock didAcceptNewSocket:(GCDAsyncSocket *)newSocket
{
    //sock 服务端的socket
    //newSocket 客户端连接的socket
    NSLog(@"%@----%@",sock, newSocket);
    
    //1.保存连接的客户端socket(否则newSocket释放掉后链接会自动断开)
    [clientSockets addObject:newSocket];
    
    //    //连接成功服务端立即向客户端提供服务
    //    NSMutableString *serviceContent = [NSMutableString string];
    //    [newSocket writeData:[serviceContent dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
    
    //2.监听客户端有没有数据上传
    //-1代表不超时
    //tag标示作用
    [newSocket readDataWithTimeout:-1 tag:0];
}

//接收到客户端数据
- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
    NSString *msg = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSLog(@"%@",msg);
    if (msg.length > 0) {
        dispatch_async(dispatch_get_main_queue(), ^{
            showLb.text = [NSString stringWithFormat:@"接收到tcp数据：%@",msg];
        });
    }
//    Byte b0 = ((Byte*)([data bytes]))[0];
//    if (b0 == 0x00) {
//        [imgdata resetBytesInRange:NSMakeRange(0, imgdata.length)];
//        [imgdata setLength:0];
//    }
    [imgdata appendData:data];
//    [NSThread sleepForTimeInterval:1];
//    if (b0 == 0x00) {
//        [imgdata replaceBytesInRange:NSMakeRange(0, 1) withBytes:NULL length:0];//删除索引0到索引1的数据
//    }
    dispatch_async(dispatch_get_main_queue(), ^{
        UIImage *img = [[UIImage alloc]initWithData:imgdata];
        if (img) {
            imgvw.image = img;
        }
    });
    NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    NSInteger code = [str integerValue];
    NSString *responseString = nil;
    
    //处理请求 返回数据
    [sock writeData:[responseString dataUsingEncoding:NSUTF8StringEncoding] withTimeout:-1 tag:0];
//    if (code == 0) {
//        [clientSockets removeObject:sock];
//    }
    //CocoaAsyncSocket每次读取完成后必须调用一次监听数据方法
    [sock readDataWithTimeout:-1 tag:0];
}

// wirte成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"发送成功");
    dispatch_async(dispatch_get_main_queue(), ^{
        showLb.text = @"tcp发送数据成功";
    });
    // 持续接收数据
    // 超时设置为附属，表示不会使用超时
    [_socket readDataWithTimeout:-1 tag:tag];
}

// socket成功连接回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"成功连接到%@:%d",host,port);
    dispatch_async(dispatch_get_main_queue(), ^{
        showLb.text = [NSString stringWithFormat:@"tcp成功连接到%@:%d",host,port];
    });
//    NSMutableData *bufferData = [[NSMutableData alloc] init]; // 存储接收数据的缓存区
    [_socket readDataWithTimeout:-1 tag:99];
}

- (NSString *)deviceIPAdress {
    NSString *address = @"an error occurred when obtaining ip address";
    struct ifaddrs *interfaces = NULL;
    struct ifaddrs *temp_addr = NULL;
    int success = 0;
    
    success = getifaddrs(&interfaces);
    
    if (success == 0) { // 0 表示获取成功
        
        temp_addr = interfaces;
        while (temp_addr != NULL) {
            if( temp_addr->ifa_addr->sa_family == AF_INET) {
                // Check if interface is en0 which is the wifi connection on the iPhone
                if ([[NSString stringWithUTF8String:temp_addr->ifa_name] isEqualToString:@"en0"]) {
                    // Get NSString from C String
                    address = [NSString stringWithUTF8String:inet_ntoa(((struct sockaddr_in *)temp_addr->ifa_addr)->sin_addr)];
                }
            }
            
            temp_addr = temp_addr->ifa_next;
        }
    }
    
    freeifaddrs(interfaces);
    return address;
}

- (void)showActionSheet {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: nil                                                                          message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    //添加Button
    [alertController addAction: [UIAlertAction actionWithTitle: @"拍照" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypeCamera;
            picker.allowsEditing = YES;
            picker.delegate = self;
            // 设置导航默认标题的颜色及字体大小
            picker.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor whiteColor], NSFontAttributeName:[UIFont boldSystemFontOfSize:18]};
            [self presentViewController:picker animated:YES completion:nil];
        }else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"用户提示" message:@"此设备没有摄像头" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }]];
    [alertController addAction: [UIAlertAction actionWithTitle: @"从相册选取" style: UIAlertActionStyleDefault handler:^(UIAlertAction *action){
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
            UIImagePickerController *picker = [[UIImagePickerController alloc] init];
            picker.delegate = self;
            picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            picker.allowsEditing = YES;
            picker.mediaTypes = [[NSArray alloc] initWithObjects:(NSString*)kUTTypeImage,nil];
            //            picker.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:picker.sourceType];
            // 设置导航默认标题的颜色及字体大小
            picker.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName:[UIColor blackColor],NSFontAttributeName:[UIFont boldSystemFontOfSize:18]};
            [self presentViewController:picker animated:YES completion:nil];
        } else {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"用户提示" message:@"此设备不能访问相册" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            }]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }]];
    [alertController addAction: [UIAlertAction actionWithTitle: @"取消" style: UIAlertActionStyleCancel handler:nil]];
    [self presentViewController: alertController animated: YES completion: nil];
}

#pragma mark - UIImagePickerControllerDelegate
// 选择了图片或者拍照了
- (void)imagePickerController:(UIImagePickerController *)aPicker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    CGSize size = CGSizeMake(300, 300);
    imgvw.image = [self imageWithImageSimple:[info valueForKey:UIImagePickerControllerEditedImage] scaledToSize:size];
    [aPicker dismissViewControllerAnimated:YES completion:nil];
}

//压缩图片
- (UIImage*)imageWithImageSimple:(UIImage*)image scaledToSize:(CGSize)newSize
{
    // Create a graphics image context
    UIGraphicsBeginImageContext(newSize);
    
    // Tell the old image to draw in this new context, with the desired
    // new size
    [image drawInRect:CGRectMake(0,0,newSize.width,newSize.height)];
    
    // Get the new image from the context
    UIImage* newImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // End the context
    UIGraphicsEndImageContext();
    
    // Return the new image.
    return newImage;
}

// 取消
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)aPicker {
    [aPicker dismissViewControllerAnimated:YES completion:nil];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
