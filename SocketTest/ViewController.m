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

@interface ViewController ()<GCDAsyncSocketDelegate,UIActionSheetDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
{
    GCDAsyncSocket *_socket;
    UIImageView *imgvw;
    UILabel *showLb;
}
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    showLb = [[UILabel alloc]initWithFrame:CGRectMake(20, 40, self.view.frame.size.width - 40, 40)];
    showLb.backgroundColor = [UIColor colorWithWhite:.8 alpha:1];
    [self.view addSubview:showLb];
    
    imgvw = [[UIImageView alloc]initWithFrame:CGRectMake((self.view.frame.size.width - 200)/2, 100, 200, 200)];
    imgvw.backgroundColor = [UIColor greenColor];
    [self.view addSubview:imgvw];
    
    UIButton *ljbutton = [[UIButton alloc]initWithFrame:CGRectMake(20, 340, 80, 40)];
    [ljbutton setTitle:@"连接" forState:UIControlStateNormal];
    ljbutton.backgroundColor = [UIColor orangeColor];
    [ljbutton addTarget:self action:@selector(ljAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:ljbutton];
    
    UIButton *button = [[UIButton alloc]initWithFrame:CGRectMake(120, 340, 80, 40)];
    [button setTitle:@"选择" forState:UIControlStateNormal];
    button.backgroundColor = [UIColor blueColor];
    [button addTarget:self action:@selector(btnAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    UIButton *send = [[UIButton alloc]initWithFrame:CGRectMake(220, 340, 80, 40)];
    [send setTitle:@"发送" forState:UIControlStateNormal];
    send.backgroundColor = [UIColor brownColor];
    [send addTarget:self action:@selector(sendAct) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:send];
}

- (void)ljAct {
    _socket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    NSLog(@"连接服务器");
    showLb.text = @"连接服务器";
    NSError *error = nil;
    [_socket connectToHost:@"192.168.112.183" onPort:2233 withTimeout:20 error:&error];
}

- (void)sendAct {
    if (!imgvw.image) {
        return ;
    }
    UIImage *img = imgvw.image;
    NSData *imageData = UIImagePNGRepresentation(img);
    NSData *data = [NSData dataWithBytes:"\0A" length:1];
    NSMutableData *msgData = [NSMutableData data];
    [msgData appendData:data];
    [msgData appendData:imageData];
    [_socket writeData:msgData withTimeout:20 tag:34];
}

- (void)btnAct {
    [self showActionSheet];
}

// wirte成功
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag
{
    NSLog(@"发送成功");
    dispatch_async(dispatch_get_main_queue(), ^{
        showLb.text = @"发送成功";
    });
    // 持续接收数据
    // 超时设置为附属，表示不会使用超时
    [_socket readDataWithTimeout:-1 tag:tag];
}

// socket成功连接回调
-(void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    NSLog(@"成功连接到%@:%d",host,port);
    dispatch_async(dispatch_get_main_queue(), ^{
        showLb.text = [NSString stringWithFormat:@"成功连接到%@:%d",host,port];
    });
//    NSMutableData *bufferData = [[NSMutableData alloc] init]; // 存储接收数据的缓存区
    [_socket readDataWithTimeout:-1 tag:99];
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
    imgvw.image = [info valueForKey:UIImagePickerControllerEditedImage];
    [aPicker dismissViewControllerAnimated:YES completion:nil];
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
