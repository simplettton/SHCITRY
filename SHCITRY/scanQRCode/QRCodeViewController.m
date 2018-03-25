//
//  QRCodeViewController.m
//  MQTTClientDemo
//
//  Created by Binger Zeng on 2017/12/27.
//  Copyright © 2017年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "QRCodeViewController.h"

#import <AVFoundation/AVFoundation.h>
@interface QRCodeViewController ()<CALayerDelegate,AVCaptureMetadataOutputObjectsDelegate>
/**
 *  五个类
 */
@property (strong,nonatomic)AVCaptureDevice * device;
@property (strong,nonatomic)AVCaptureDeviceInput * input;
@property (strong,nonatomic)AVCaptureMetadataOutput * output;
@property (strong,nonatomic)AVCaptureSession * session;
@property (strong,nonatomic)AVCaptureVideoPreviewLayer * previewLayer;
/**
 *  遮罩层
 */
@property (strong,nonatomic)CALayer *maskLayer;
/**
 *  两个layout属性
 */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanViewH;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *scanlineTop;

/**
 *  UI
 */
@property (weak, nonatomic) IBOutlet UILabel *result;
@property (weak, nonatomic) IBOutlet UIImageView *scanAreaImageView;
@property (weak, nonatomic) IBOutlet UIImageView *scanline;
@property (weak, nonatomic) IBOutlet UIView *scanView;
@end

@implementation QRCodeViewController
#pragma mark - lazy load

-(AVCaptureDevice *)device{
    if (_device == nil) {
        
        _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        
    }
    return _device;
    
}

-(AVCaptureDeviceInput *)input{
    
    if (_input == nil) {
        
        _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
        
    }
    
    return  _input;
    
}

-(AVCaptureMetadataOutput *)output{
    
    if (_output == nil) {
        
        _output = [[AVCaptureMetadataOutput alloc]init];
        
        [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
        
    }
    
    return  _output;
}
#pragma mark - viewController lifecycle
/**
 *  执行扫描动画
 */
-(void)viewDidAppear:(BOOL)animated{

    [super viewDidAppear:animated];

    [self startAnim];

}

/**
 *  注册进入前台通知 保证下次进来还有扫描动画
 */
-(void)viewWillAppear:(BOOL)animated{

    [super viewWillAppear:animated];

    //注册程序进入前台通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector (startAnim) name: UIApplicationWillEnterForegroundNotification object:nil];
}

/**
 *  移除通知
 */
-(void)viewWillDisappear:(BOOL)animated{

    [super viewWillDisappear:animated];
    //解除程序进入前台通知

    [[NSNotificationCenter defaultCenter] removeObserver:self name: UIApplicationWillEnterForegroundNotification object:nil];
}
-(void)dealloc {
        self.maskLayer.delegate = nil;
}
- (void)viewDidLoad {
    [super viewDidLoad];
//    // Device
//    _device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//
//    // Input
//    _input = [AVCaptureDeviceInput deviceInputWithDevice:self.device error:nil];
//
//    // Output
//    _output = [[AVCaptureMetadataOutput alloc]init];
//    [_output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
    //1、创建会话
    self.session = [[AVCaptureSession alloc]init];
    if ([self.session canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        [self.session setSessionPreset:AVCaptureSessionPresetHigh];
    }
    
    //2、添加输入和输出设备
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    if ([self.session canAddOutput:self.output]) {
        [self.session addOutput:self.output];
    }
    
    //3、设置这次扫描的数据类型
    self.output.metadataObjectTypes = @[AVMetadataObjectTypeQRCode,AVMetadataObjectTypeEAN13Code,  AVMetadataObjectTypeEAN8Code, AVMetadataObjectTypeCode128Code];
    
    //4.创建预览层
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.session];
    self.previewLayer.frame = self.view.bounds;
    self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer insertSublayer:self.previewLayer atIndex:0];
    
    //5.创建周围遮罩
    CALayer *maskLayer = [[CALayer alloc]init];
    maskLayer.frame = self.view.bounds;
    //此时设置的颜色就是中间扫描区域最终的颜色
    maskLayer.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.2].CGColor;
    maskLayer.delegate = self;
    [self.view.layer insertSublayer:maskLayer above:self.previewLayer];
    
    //让代理方法调用 将周围的蒙版颜色加深
    [maskLayer setNeedsDisplay];
    
    //6.设置扫描的区域
    self.output.rectOfInterest = self.scanView.bounds;
    [self.session startRunning];
    

    self.maskLayer = maskLayer;
}
/**
 *   蒙版中间一块要空出来
 */

-(void)drawLayer:(CALayer *)layer inContext:(CGContextRef)ctx{

    if (layer == self.maskLayer) {
        UIGraphicsBeginImageContextWithOptions(self.maskLayer.frame.size, NO, 1.0);
        //蒙版新颜色
        CGContextSetFillColorWithColor(ctx, [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.5].CGColor);
        CGContextFillRect(ctx, self.maskLayer.frame);
        //转换坐标
        CGRect scanFrame = [self.view convertRect:self.scanView.frame fromView:self.scanView.superview];
        //空出中间一块
        CGContextClearRect(ctx, scanFrame);
    }
}
#pragma mark - delegate
/**
 *  扫描到二维码回调该代理方法
 */
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    
    if(metadataObjects.count > 0 && metadataObjects != nil){
        
//        [self.previewLayer removeFromSuperlayer];
//        [self.session stopRunning];
        AVMetadataMachineReadableCodeObject *metadataObject = [metadataObjects lastObject];
        
        NSString *result = metadataObject.stringValue;
        if (result) {
            NSLog(@"二维码的内容 %@",result);
            self.result.text = result;
//            ScanResultViewController *resultvc = [[ScanResultViewController alloc]init];
//            resultvc.result = result;
            
//            [self performSegueWithIdentifier:@"ShowResult" sender:result];
        }
//        [self.scanline removeFromSuperview];
        
    }
}

#pragma mark - private Method
/**
 *  扫描线动画
 */
-(void)startAnim{

    //如果是第二次进来 那么动画已经执行完毕 要重新开始动画的话 必须让约束归位
    if(self.scanlineTop.constant == self.scanViewH.constant - 4){

        self.scanlineTop.constant -= self.scanViewH.constant - 4;
        [self.view layoutIfNeeded];

    }
    //执行动画
    [UIView animateWithDuration:3.0 delay:0 options:UIViewAnimationOptionRepeat animations:^{
        
        self.scanlineTop.constant = self.scanViewH.constant - 4;
        [self.view layoutIfNeeded];
        
        
    } completion:nil];
    
}

@end
