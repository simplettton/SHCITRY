//
//  HomeViewController.m
//  SHCITRY
//
//  Created by Macmini on 2017/12/25.
//  Copyright © 2017年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "HomeViewController.h"
#import "BackgroundViewController.h"
#import "FilterElementImageView.h"
#import "Pack.h"
#import "Unpack.h"
#import <SVProgressHUD.H>
#import "XLPasswordView.h"

#define LongPressMiniDurantion 1

#define IS_ONE(number, n) ((number >> n) & (0x1))
#define SERVICE_UUID           @"0000ffe0-0000-1000-8000-00805f9b34fb"
#define TX_CHARACTERISTIC_UUID @"0000ffe1-0000-1000-8000-00805f9b34fb"
#define RX_CHARACTERISTIC_UUID @"0000ffe1-0000-1000-8000-00805f9b34fb"
#define channelOnCharacteristicView @"CharacteristicView"
#define PasswordToEnterBackground @"123456"

////PM2.5
//static NSString* const BAD_PM2_5_DATA     = @"01";
//static NSString* const MIDDLE_PM2_5_DATA  = @"02";
//static NSString* const GOOD_PM2_5_DATA    = @"03";


//WATER Data
static NSString* const BOILED_WATER_DATA       = @"01";
static NSString* const WARM_WATER_DATA         = @"02";
static NSString* const COLD_WATER_DATA         = @"03";
static NSString* const TURN_OFF_WATER_DATA     = @"00";


//RUNNING STATE
static const int STATUS_UNRUNNING   = 0X00;
static const int STATUS_RUNNING     = 0X01;
static const int STATUS_FAULT       = 0X02;

//CONDENSATE STATE
static const int STATUS_WATER_PRODUCTION_FALSE = 0X00;
static const int STATUS_WATER_PRODUCTION_TRUE  = 0X01;

//UV STATE
static const int STATUS_UV_LAMP_OFF = 0X00;
static const int STATUS_UV_LAMP_ON  = 0X01;

//FILTERNET
static const int STATUS_FILTERNET_REGULAR       = 0X00;
static const int STATUS_FILTERNET_NEED_CHANGE   = 0X01;

//SSID


//3G
static const int STATUS_3G_CONNECT_FALSE = 0X00;
static const int STATUS_3G_CONNECT_TRUE  = 0X01;

typedef NS_ENUM(NSInteger,KCmdids)
{
    CMDID_STATUS                = 0X01,
    CMDID_POWER_ON              = 0X02,
    CMDID_POWER_OFF             = 0X03,
    CMDID_LOCK                  = 0X04,
    CMDID_UNLOCK                = 0X05,
    CMDID_PM2_5_DATA            = 0X06,
    CMDID_WATER_CONTROL         = 0X07,
    CMDID_TEMPERATURE_DATA      = 0X08,
    CMDID_RH_DATA               = 0X09,
    CMDID_TDS_DATA              = 0X0A,
    CMDID_FILTER_ELEMENT_DATA   = 0X0B,
    CMDID_STATUS_RUN_DATA       = 0X0C,
    CMDID_STATUS_CONDENSATE_DATA= 0X0D,
    CMDID_STATUS_UV_DATA        = 0X0E,
    CMDID_STATUS_FILTERNET_DATA = 0X0F,
    CMDID_SSID_DATA             = 0X10,
    CMDID_ACCOUNT               = 0X11,
    CMDID_PASSWORD              = 0X12,
    CMDID_STATUS_3G_CONNECT_DATA= 0X13
};

typedef NS_ENUM(NSInteger,SatusBarsTag)
{
    runningCircleTag = 1,
    runningLabelTag = 2,
    faultCircleTag  = 3,
    faultLabelTag   = 4,
    windTag         = 5,
    UVTag           = 6,
    filterNetTag    = 7,
    internetTag     = 8,
    BLETag          = 9
    
};
typedef NS_ENUM(NSInteger,PM2_5ViewTags)
{
    GoodPM2_5ImgViewTag   = 3,
    MiddlePM2_5ImgViewTag = 2,
    BadPM2_5ImGViewTag    = 1,

};
typedef NS_ENUM(NSInteger, WaterTemperatureViewTags)
{
    BoiledWaterTag        = 1,
    WarmWaterTag          = 2,
    ColdWaterTag          = 3
};


@interface HomeViewController ()<CALayerDelegate,XLPasswordViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *statusView;
@property (weak, nonatomic) IBOutlet UIView *PM2_5View;
@property (weak, nonatomic) IBOutlet UIView *waterTemperatureView;
@property (weak, nonatomic) IBOutlet UIView *filterElementView;


//control button
@property (weak, nonatomic) IBOutlet UIButton *switchButton;
@property (weak, nonatomic) IBOutlet UIButton *lockButton;
@property (weak, nonatomic) IBOutlet UIButton *boiledWaterButton;
@property (weak, nonatomic) IBOutlet UIButton *warmWaterButton;
@property (weak, nonatomic) IBOutlet UIButton *coldWaterButton;


@property (nonatomic,strong)CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong)CBCharacteristic *receiveCharacteristic;

//otherModel
@property (nonatomic,assign)BOOL BLEisConnected;
@property (nonatomic,assign)BOOL WIFIisConnected;
@property (nonatomic,assign)BOOL islocked;
@property (nonatomic,assign)BOOL isPowerOn;


//status bar data
@property (nonatomic,assign)NSInteger runningStatus;
@property (nonatomic,assign)NSInteger condensateStatus;
@property (nonatomic,assign)NSInteger UVStatus;
@property (nonatomic,assign)NSInteger filterNetStatus;
@property (nonatomic,assign)NSInteger internet3GStatus;


//filter element
@property (nonatomic,assign)NSInteger filterElementData;
//pm2.5
@property (nonatomic,assign)NSInteger PM2_5Data;
//水温
@property (nonatomic,assign)NSInteger waterTempuratureData;


//datamodel
@property (nonatomic,strong)NSString *TDSString;
@property (nonatomic,strong)NSString *temperatureString;
@property (nonatomic,strong)NSString *RHString;

//datadisplay
@property (weak, nonatomic) IBOutlet UILabel *TDSLabel;
@property (weak, nonatomic) IBOutlet UILabel *RHLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureLabel;

//LOCK mengban
@property (strong,nonatomic)CALayer *maskLayer;
@property (weak, nonatomic) IBOutlet UIImageView *backgroundEntry;

@end

@implementation HomeViewController
#pragma mark - viewcontroller lifecycle

-(BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    [self initAll];


}

-(void)initAll{
    
    self.BLEisConnected = NO;
    self.WIFIisConnected = NO;
    self.isPowerOn = NO;
    self.islocked = NO;
    
    [self configureButtonUI];
    //返回搜索调试界面
    [self setupSwipe];
    //进入后台手势
    [self setupLongPress];
    [self loadData];
    
    //配置svprogressHUD
//    [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeCustom];
//    [SVProgressHUD setBackgroundLayerColor:[UIColor colorWithWhite:0 alpha:0.7]];
    
    [SVProgressHUD setMinimumSize:CGSizeMake(200, 100)];
    [SVProgressHUD setCornerRadius:5];
    [SVProgressHUD showWithStatus:@"Connecting"];
    //    [Pack packetWithCmdid:0x90 dataEnabled:YES data:@"0102"];
}

- (void)viewWillAppear:(BOOL)animated {
    
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self addObserver:self forKeyPath:@"BLEisConnected" options:NSKeyValueObservingOptionNew context:nil];
    [self addObserver:self forKeyPath:@"WIFIisConnected" options:NSKeyValueObservingOptionNew context:nil];
    
    [self babyDelegate];

}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:YES];
    //ttttttttttttttttttttt
//    [self performSegueWithIdentifier:@"EnterBackground" sender:nil];

}

-(void)viewWillDisappear:(BOOL)animated {
    
    [super viewWillDisappear:YES];
    
    [self removeObserver:self forKeyPath:@"BLEisConnected" context:nil];
    [self removeObserver:self forKeyPath:@"WIFIisConnected" context:nil];
    
    
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    
//    [baby cancelNotify:self.currPeripheral characteristic:self.receiveCharacteristic];
    
}


-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    
    if ([keyPath isEqualToString:@"BLEisConnected"]) {
    UIImageView *BLEView         = [self.statusView viewWithTag:BLETag];
        if (self.BLEisConnected) {
//            BLEView.image = [UIImage imageNamed:@"bluetooth_white"];
            BLEView.highlighted = YES;
        } else {
            BLEView.highlighted = NO;
        }
    }else if ([keyPath isEqualToString:@"WIFIisConnected"]) {
        UIImageView *internetView = [self.statusView viewWithTag:internetTag];
        if (self.WIFIisConnected) {
            internetView.image = [UIImage imageNamed:@"Wi-Fi_white"];
        } else {
            internetView.image = nil;
        }
    }
    
}



#pragma mark    -   XLPasswordViewDelegate

/**
 *  输入密码位数已满时调用
 */
- (void)passwordView:(XLPasswordView *)passwordView didFinishInput:(NSString *)password
{
    if([password isEqualToString:PasswordToEnterBackground]){
        [passwordView removeFromSuperview];
        [self performSegueWithIdentifier:@"EnterBackground" sender:nil];
        
    }else{
        
    }
}

/**
 *  用户输入密码时调用
 *
 *  @param passwordView 视图
 *  @param password     输入的密码文本
 */
- (void)passwordView:(XLPasswordView *)passwordView passwordTextDidChange:(NSString *)password
{
    NSLog(@"%@",password);
}

/**
 *  点击了忘记密码时调用
 */
- (void)passwordViewClickForgetPassword:(XLPasswordView *)passwordView
{
    NSLog(@"点击了忘记密码");
}



#pragma mark - button clicked

- (IBAction)switchBtnClicked:(UIButton *)sender {
    
    
    if (self.isPowerOn) {
        [self powerOff];
    }else {
        [self isPowerOn];
    }
    self.isPowerOn = !self.isPowerOn;
    [self updateUI];
}


- (IBAction)lockBtnClicked:(UIButton *)sender {
    
    if (self.islocked) {

        [self unlock];

    }else{
        
        [self lock];
        //设置锁住按钮颜色
    }
    
    //获取状态
    self.islocked = !self.islocked;

    [self updateUI];
    
}
- (IBAction)boiledWaterBtnClicked:(UIButton *)button {

//    if (self.BLEisConnected && !self.islocked) {
        UIImageView * imageView = (UIImageView *)[self.waterTemperatureView viewWithTag:BoiledWaterTag];
    UIImageView * warmImageView = [self.waterTemperatureView viewWithTag:WarmWaterTag];
    UIImageView * coldImageView = [self.waterTemperatureView viewWithTag:ColdWaterTag];
        button.selected = !button.selected;
        if (button.selected) {
            [self boiledWaterFlow];
            imageView.highlighted  = YES;
            NSLog(@"出热水");
        }else{
            [self turnOffWater];
            imageView.highlighted = NO;
            NSLog(@"关水");
        }
    warmImageView.highlighted = NO;
    self.warmWaterButton.selected = NO;
    coldImageView.highlighted = NO;
    self.coldWaterButton.selected = NO;
    
        
//    }
}
- (IBAction)warmWaterBtnClicked:(UIButton *)button {
    
//    if (self.BLEisConnected && !self.islocked) {
        UIImageView * imageView = (UIImageView *)[self.waterTemperatureView viewWithTag:WarmWaterTag];
    UIImageView * boildImageView = [self.waterTemperatureView viewWithTag:BoiledWaterTag];
    UIImageView * coldImageView = [self.waterTemperatureView viewWithTag:ColdWaterTag];
        button.selected = !button.selected;
        if (button.selected) {
            [self warmWaterFlow];
            imageView.highlighted  = YES;
            
        }else{
            [self turnOffWater];
            imageView.highlighted = NO;
        }
    
    boildImageView.highlighted = NO;
    self.boiledWaterButton.selected = NO;
    coldImageView.highlighted = NO;
    self.coldWaterButton.selected = NO;
//    }
}
- (IBAction)coldWaterClicked:(UIButton *)button {
//    if (self.BLEisConnected && !self.islocked) {
        UIImageView * imageView = (UIImageView *)[self.waterTemperatureView viewWithTag:ColdWaterTag];
    UIImageView * boildImageView = [self.waterTemperatureView viewWithTag:BoiledWaterTag];
    UIImageView * warmImageView = [self.waterTemperatureView viewWithTag:WarmWaterTag];
        button.selected = !button.selected;
        if (button.selected) {
            [self coldWaterFlow];
            imageView.highlighted  = YES;
        }else{
            [self turnOffWater];
            imageView.highlighted = NO;
        }
//    }
    boildImageView.highlighted = NO;
    self.boiledWaterButton.selected = NO;
    
    warmImageView.highlighted = NO;
    self.warmWaterButton.selected = NO;
}



#pragma mark - babyDelegate
-(void)loadData {
    if (baby)
    {
    baby.having(self.currPeripheral).then.connectToPeripherals().discoverServices().discoverCharacteristics().readValueForCharacteristic().discoverDescriptorsForCharacteristic().readValueForDescriptors().begin();
    }
    //    baby.connectToPeripheral(self.currPeripheral).begin();
}
-(void)babyDelegate {
    __weak typeof(self)weakSelf = self;
    [baby setBlockOnConnected:^(CBCentralManager *central, CBPeripheral *peripheral) {
        [SVProgressHUD setDefaultMaskType:SVProgressHUDMaskTypeNone];
        [SVProgressHUD setMinimumSize:CGSizeZero];
        [SVProgressHUD setCornerRadius:14];
        [SVProgressHUD showSuccessWithStatus:[NSString stringWithFormat:@"设备：%@--连接成功",peripheral.name]];
        [SVProgressHUD dismissWithDelay:0.9];
        weakSelf.BLEisConnected = YES;
    }];
    
    [baby setBlockOnFailToConnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        [SVProgressHUD showErrorWithStatus:[NSString stringWithFormat:@"设备：%@--连接失败",peripheral.name]];
        [SVProgressHUD dismissWithDelay:0.9];
        weakSelf.BLEisConnected = NO;
        [weakSelf swipeRight];
    }];
    
    
    
    
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@--断开连接",peripheral.name);
        //        [baby.centralManager connectPeripheral:peripheral options:nil];
        weakSelf.BLEisConnected = NO;
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@--断开连接",peripheral.name]];
        [SVProgressHUD dismissWithDelay:0.9];
//        [weakSelf swipeRight];
    }];
    
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        
    }];
    
    [baby setBlockOnDiscoverCharacteristics:^(CBPeripheral *peripheral, CBService *service, NSError *error)
     {
         if ([service.UUID isEqual:[CBUUID UUIDWithString:SERVICE_UUID]])
         {
             NSLog(@"characteristic = %@",service.characteristics);
             for(CBCharacteristic *characteristic in service.characteristics)
             {
                 if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:RX_CHARACTERISTIC_UUID]])
                 {
                     weakSelf.receiveCharacteristic = characteristic;
                     
                     if (![characteristic isNotifying])
                     {
                         [weakSelf setNotifiy:characteristic];
                     }
                     
                 }
                 if ([characteristic.UUID isEqual:[CBUUID UUIDWithString:TX_CHARACTERISTIC_UUID]])
                 {
                     weakSelf.sendCharacteristic = characteristic;
                 }
             }
         }
     }];
    
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        

    }];
    
    [baby setBlockOnDidUpdateNotificationStateForCharacteristic:^(CBCharacteristic *characteristic, NSError *error)
     {
         NSLog(@"didUpdata");
         
     }];
    
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    NSDictionary *connectOptions = @{CBConnectPeripheralOptionNotifyOnConnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnDisconnectionKey:@YES,
                                     CBConnectPeripheralOptionNotifyOnNotificationKey:@YES};
    
    
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions
                             connectPeripheralWithOptions:connectOptions
                           scanForPeripheralsWithServices:nil
                                     discoverWithServices:nil
                              discoverWithCharacteristics:nil];
}
#pragma mark - writeData
-(void)writeValueWithCmdid:(Byte)cmdid data:(NSString *)data{
    if (self.BLEisConnected) {
        if (self.currPeripheral) {
            if (self.sendCharacteristic) {
                [self.currPeripheral writeValue:[Pack packetWithCmdid:cmdid dataEnabled:YES data:data]
                              forCharacteristic:self.sendCharacteristic
                                           type:CBCharacteristicWriteWithResponse];
            }
        }
    }

}
-(void)writeData:(NSData *)data {
    if (self.BLEisConnected) {
        if (self.currPeripheral) {
            [self.currPeripheral writeValue:data
                          forCharacteristic:self.sendCharacteristic
                                       type:CBCharacteristicWriteWithResponse];
        }
    }
}

#pragma mark - receiveData
-(void)setNotifiy:(CBCharacteristic *)characteristic {
    __weak typeof(self)weakSelf = self;
    
    //通知方式监听一个characteristic的值
    [baby notify:weakSelf.currPeripheral
           characteristic:characteristic
                    block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                       NSLog(@"----------------------------------------------");
                       NSData *data = characteristic.value;
                        
                        Byte *byte = (Byte *)[data bytes];
//                        if（byte[0]!=0x4f){
//                            [weakSelf updateModelWithData:data];
//                        }
                        for (int i = 0; i< [data length]; i ++) {
                            NSLog(@"receive--------------------------------------bytes[%d] = %x",i,byte[i]);
                        }
                        [weakSelf updateModelWithData:data];
                   }];
}


-(void)updateModelWithData:(NSData *)receivedData {
    
//    NSData *data = [Unpack unpackData:receivedData];
    NSData *data = receivedData;
    if (data) {
        Byte *bytes = (Byte *)[data bytes];
//        Byte cmdID = bytes[0];
//        Byte dataByte = bytes[1];
        
        Byte cmdID = bytes[3];
        Byte dataByte = bytes[4];
        
        
        
        NSString *singleFormat = @"%d.%d";
        NSString *doubleFormat = @"%d.%d";
        
        switch (cmdID) {
                
                //主机状态
            case CMDID_STATUS:
            {
                
                switch (dataByte) {
                    case 0xAA:
                    {
                        self.isPowerOn            = bytes [2];
                        self.islocked             = bytes [3];
                        self.PM2_5Data            = bytes [4];
                        self.waterTempuratureData = bytes [5];
                        self.filterElementData    = bytes [6];
                        self.runningStatus        = bytes [7];
                        self.condensateStatus     = bytes [8];
                        self.UVStatus             = bytes [9];
                        self.filterNetStatus      = bytes [10];
                        
                    }
                        break;
                        
                    case 0xAB:
                    {
                        
                        NSString *singleFormat = @"%d.%d";
                        NSString *doubleFormat = @"%d.%d";
                        

                        
                        self.temperatureString = [NSString stringWithFormat:(bytes[2]<10)?singleFormat:doubleFormat,bytes[2],bytes[3]];
    
                        self.RHString          = [NSString stringWithFormat:(bytes[4]<10)?singleFormat:doubleFormat,bytes[4],bytes[5]];
                        
                        self.TDSString         = [NSString stringWithFormat:(bytes[6]<10)?singleFormat:doubleFormat,bytes[6],bytes[7]];
                        
                    }
                        break;
                }
            }
                
                break;
                
                
                //PM2_5
            case CMDID_PM2_5_DATA:
                self.PM2_5Data = dataByte; break;
                
                //水温
            case CMDID_WATER_CONTROL:
                self.waterTempuratureData = dataByte; break;
                
                //更换滤芯
            case CMDID_FILTER_ELEMENT_DATA:         self.filterElementData = dataByte;  break;
                
                
                
                
                //三个数字显示
            case CMDID_TDS_DATA:
            {
                
//                Byte intergerPart = bytes[1];
//                Byte fractionalPart = bytes [2];
                Byte intergerPart = bytes[4];
                Byte fractionalPart = bytes [5];
                
                self.TDSString = [NSString stringWithFormat:(intergerPart<10)?singleFormat:doubleFormat,intergerPart,fractionalPart];
            }
                break;
                
            case CMDID_RH_DATA:
            {
//                Byte intergerPart = bytes[1];
//                Byte fractionalPart = bytes [2];
                Byte intergerPart = bytes[4];
                Byte fractionalPart = bytes [5];
                self.RHString = [NSString stringWithFormat:(intergerPart<10)?singleFormat:doubleFormat,intergerPart,fractionalPart];
            }
                break;
                
            case CMDID_TEMPERATURE_DATA:
            {
//                Byte intergerPart = bytes[1];
//                Byte fractionalPart = bytes [2];
                
                Byte intergerPart = bytes[4];
                Byte fractionalPart = bytes [5];
                self.temperatureString = [NSString stringWithFormat:(intergerPart<10)?singleFormat:doubleFormat,intergerPart,fractionalPart];
            }
                break;
                
                
                
                
                //**                               **//
                /**           status bars          **/
                /**                               **/
                
            case CMDID_STATUS_RUN_DATA:             self.runningStatus = dataByte;      break;
                
            case CMDID_STATUS_CONDENSATE_DATA:      self.condensateStatus = dataByte;   break;
                
            case CMDID_STATUS_UV_DATA:              self.UVStatus = dataByte;           break;
                
            case CMDID_STATUS_FILTERNET_DATA:       self.filterNetStatus = dataByte;    break;
                
            case CMDID_STATUS_3G_CONNECT_DATA:      self.internet3GStatus = dataByte;   break;
                
            case CMDID_SSID_DATA:
            {
                if (bytes[2] == 0x01) {//ssid+0x0d
                    
                } else if (bytes[2] == 0x02 && bytes[3] == 0x04f && bytes[4] == 0x4b){//ok ascii
                    self.WIFIisConnected = YES;
                }
            }
                break;
                
                
            default:
                break;
        }
    }

    
    //更新UI
    [self updateUI];
    
}
-(void)updateUI {
    
    UIImageView *runningCircle   = [self.statusView viewWithTag:runningCircleTag];
    UILabel *runningLabel        = [self.statusView viewWithTag:runningLabelTag];
    UIImageView *faultCircle     = [self.statusView viewWithTag:faultCircleTag];
    UILabel *faultLabel          = [self.statusView viewWithTag:faultLabelTag];
    UIImageView *windView        = [self.statusView viewWithTag:windTag];
    UIImageView *UVView          = [self.statusView viewWithTag:UVTag];
    UIImageView *filterNetView   = [self.statusView viewWithTag:filterNetTag];
    UIImageView *internectView   = [self.statusView viewWithTag:internetTag];

    
    
    //**                               **//
    /**            状态ui              **/
    /**                               **/
    
    //运行状态
    switch (self.runningStatus) {
            
        case STATUS_RUNNING:

            runningCircle.highlighted = YES;
            runningLabel.highlighted  = YES;
            
            faultLabel.highlighted  = NO;
            faultCircle.highlighted = NO;
            
            
            
            break;
            
        case STATUS_UNRUNNING:
        
            runningCircle.highlighted = NO;
            runningLabel.highlighted  = NO;
            
            faultLabel.highlighted  = NO;
            faultCircle.highlighted = NO;
            
            break;
            
        case STATUS_FAULT:

            runningCircle.highlighted = NO;
            runningLabel.highlighted  = NO;
            
            faultLabel.highlighted  = YES;
            faultCircle.highlighted = YES;
            
            break;
            
        default:
            break;
    }
    //治水状态(冷凝)
    switch (self.condensateStatus) {
        case STATUS_WATER_PRODUCTION_TRUE:
            
            windView.highlighted = YES;
            
            break;
            
        case STATUS_WATER_PRODUCTION_FALSE:
            
            windView.highlighted = NO;
            
            break;
    }

    //uv紫外灯
    switch (self.UVStatus) {
            
        case STATUS_UV_LAMP_ON:
            
            UVView.highlighted = YES;
            
            break;
        case STATUS_UV_LAMP_OFF:
            
            UVView.highlighted = NO;
            
            break;
            
    }
    
    //过滤网
    switch (self.filterNetStatus) {
            
        case STATUS_FILTERNET_NEED_CHANGE:
            
            filterNetView.highlighted = YES;
            
            break;
            
        case STATUS_FILTERNET_REGULAR:
            
            filterNetView.highlighted = NO;
            
            break;
    }
    
    //3g状态
    switch (self.internet3GStatus) {
            
        case STATUS_3G_CONNECT_TRUE:
            
            internectView.image = [UIImage imageNamed:@"3G_white"];
            
            break;
            
        case STATUS_3G_CONNECT_FALSE:
            
            internectView.image = nil;
            
            break;
    }
    
    //**                               **//
    /**            数字ui              **/
    /**                               **/
    
    if (self.TDSString) {
        self.TDSLabel.text = self.TDSString;
    }
    if (self.temperatureString) {
        self.temperatureLabel.text = self.temperatureString;
    }
    if (self.RHString) {
        self.RHLabel.text = self.RHString;
    }
    
    //**                               **//
    /**            更换滤芯              **/
    /**                               **/
    switch (self.filterElementData) {
        case 0x00:
            for (UIView* view in self.filterElementView.subviews) {
                if ([view isKindOfClass:[FilterElementImageView class]]) {
                    FilterElementImageView *imageView = (FilterElementImageView *)view;
                    if (imageView.changeColorTimer) {
                        [imageView deallocTimer];
                    }
                    imageView.highlighted = NO;
                }
            }
            break;
        
        default:
        {
            char temp = 0x01;
            char lastTempt = 0x00;
            
            //判断低4位某一位是否为1(从1开始)
            for (int i = 1; i < 5; i++) {
                
                lastTempt = self.filterElementData >> (i-1);
                if (lastTempt & temp) {
                    FilterElementImageView *imageView = [self.filterElementView viewWithTag:i];
                    [self startTimerToChangeColorOfFilterElement:imageView];
                }
            }
        }
            break;
    }
    
    
    //pm2.5数据
    for (UIView *subView in self.PM2_5View.subviews) {
        if ([subView isKindOfClass:[UIImageView class]]) {
            UIImageView *lightImageView = (UIImageView *)subView;
            if (subView.tag == self.PM2_5Data) {
                lightImageView.highlighted = YES;
            }else {
                lightImageView.highlighted = NO;
            }
        }
    }
    
    //水温数据
//    UIImageView *boiledImageView = [self.waterTemperatureView viewWithTag:BoiledWaterTag];
//    UIImageView *warmImageView = [self.waterTemperatureView viewWithTag:WarmWaterTag];
//    UIImageView *coldImageView = [self.waterTemperatureView viewWithTag:ColdWaterTag];
//    NSArray *waterImageViewArray = @[boiledImageView,warmImageView,coldImageView];
    
    switch (self.waterTempuratureData) {

        case 0x00:
            
            for (UIView* view in self.waterTemperatureView.subviews) {
                if ([view isKindOfClass:[UIImageView class]]) {
                    
                    UIImageView *imageView = (UIImageView *)view;
                    
                    imageView.highlighted = NO;
                }
            }
            
//            for (UIImageView *imageView in waterImageViewArray) {
//                imageView.highlighted = NO;
//            }
            break;
            
//        case 0X01:
//
//            boiledImageView.highlighted = YES;      break;
//
//        case 0X02:
//
//            warmImageView.highlighted = YES;        break;
//
//        case 0x03:
//
//            coldImageView.highlighted  = YES;       break;
//

            
        default:
            for (UIView *subView in self.waterTemperatureView.subviews) {
                if ([subView isKindOfClass:[UIImageView class]]) {
                    UIImageView *lightImageView = (UIImageView *)subView;
                    if (subView.tag == self.waterTempuratureData) {
                        lightImageView.highlighted = YES;
                    }else {
                        lightImageView.highlighted = NO;
                    }
                }
            }
            break;
    }
    
    
    //**                               **//
    /**           开关和按钮             **/
    /**                               **/
    
    //按钮
    if (self.islocked) {
        
        self.lockButton.selected = YES;
        
        self.switchButton.enabled      = NO;
        self.boiledWaterButton.enabled = NO;
        self.warmWaterButton.enabled   = NO;
        self.coldWaterButton.enabled   = NO;
        
        if (!self.maskLayer) {
            CALayer *maskLayer = [[CALayer alloc]init];
            maskLayer.frame = self.view.bounds;
            maskLayer.backgroundColor = [UIColor colorWithRed:0.1 green:0.1 blue:0.1 alpha:0.4].CGColor;
            maskLayer.delegate = self;
            [self.view.layer addSublayer:maskLayer];
            
            //让代理方法调用 将周围的蒙版颜色加深
            [maskLayer setNeedsDisplay];
            self.maskLayer = maskLayer;
        }
        
    }else{
        //highted是蓝色状态
        
        
        self.lockButton.selected = NO;
        
        self.switchButton.enabled      = YES;
        self.boiledWaterButton.enabled = YES;
        self.warmWaterButton.enabled   = YES;
        self.coldWaterButton.enabled   = YES;
        
        if (self.maskLayer) {
            
            [self.maskLayer removeFromSuperlayer];
            self.maskLayer = nil;
        }
        
    }
    //开关
    if (self.isPowerOn) {
        self.switchButton.selected = YES;
    }else {
        self.switchButton.selected = NO;
    }
    
    
}
#pragma mark - gesture
- (void)setupSwipe {
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    [self.view addGestureRecognizer:swipe];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
}

- (void)swipeRight {
    [self.navigationController popViewControllerAnimated:YES];
    [SVProgressHUD dismiss];
}

-(void)setupLongPress{
    self.backgroundEntry.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longPressGR =
    [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                  action:@selector(handleLongPress:)];
    longPressGR.allowableMovement=NO;
    longPressGR.minimumPressDuration = LongPressMiniDurantion;
    longPressGR.allowableMovement = 30;
    [self.backgroundEntry addGestureRecognizer:longPressGR];
}

-(IBAction)handleLongPress:(UILongPressGestureRecognizer *)longPressGesture {
    
    //    UIButton *button=(UIButton*)[(UILongPressGestureRecognizer *)sender view];
    //    NSInteger ttag=[button tag];
    if (longPressGesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"ended");
        XLPasswordView *passwordView = [XLPasswordView passwordView];
        passwordView.delegate = self;
        [passwordView showPasswordInView:self.view];
    }
    if (longPressGesture.state == UIGestureRecognizerStateEnded) {
        
    }
    
}

#pragma mark - private method
-(void)configureButtonUI {
    
    //开关和童锁按钮
    self.switchButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    self.lockButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.switchButton setTitleEdgeInsets:UIEdgeInsetsMake(self.switchButton.imageView.frame.size.height+20 ,-self.switchButton.imageView.frame.size.width, 0.0,0.0)];//文字距离上边框的距离增加imageView的高度，距离左边框减少imageView的宽度，距离下边框和右边框距离不变
    [self.switchButton setImageEdgeInsets:UIEdgeInsetsMake(-20, 0.0,0.0, -self.switchButton.titleLabel.bounds.size.width)];//图片距离右边框距离减少图片的宽度，其它不边
    [self.lockButton setTitleEdgeInsets:UIEdgeInsetsMake(self.lockButton.imageView.frame.size.height+20, -self.lockButton.imageView.frame.size.width, 0.0, 0.0)];
    [self.lockButton setImageEdgeInsets:UIEdgeInsetsMake(-20, 0.0, 0.0, -self.lockButton.titleLabel.bounds.size.width)];
    
}

-(void)startTimerToChangeColorOfFilterElement:(FilterElementImageView *)imageView{
    NSTimer *timer = [NSTimer timerWithTimeInterval:0.5
                                             target:imageView
                                           selector:@selector(changeColor)
                                           userInfo:nil
                                            repeats:YES];
   [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
}

-(void)configureButton:(UIButton *)button WithTitle:(NSString *)title imageName:(NSString*)imageName {
    button.titleLabel.text = title;
    [button setTitle:title forState:UIControlStateNormal];
    [button setImage:[UIImage imageNamed:imageName] forState:UIControlStateNormal];
}


#pragma mark - App Command
-(void)askForStatus {
    [self writeData:[Pack packetWithCmdid:CMDID_STATUS
                              dataEnabled:NO
                                     data:@"AA"]];
}
-(void)powerOn {
    [self writeValueWithCmdid:CMDID_POWER_ON data:@"AA"];
}
-(void)powerOff {
    [self writeValueWithCmdid:CMDID_POWER_OFF data:@"AA"];
    
}
-(void)lock {
    [self writeValueWithCmdid:CMDID_LOCK data:@"AA"];
}
-(void)unlock {
    [self writeValueWithCmdid:CMDID_UNLOCK data:@"AA"];
}
-(void)boiledWaterFlow {
    [self writeValueWithCmdid:CMDID_WATER_CONTROL data:BOILED_WATER_DATA];
}
-(void)warmWaterFlow {
    [self writeValueWithCmdid:CMDID_WATER_CONTROL data:WARM_WATER_DATA];
}
-(void)coldWaterFlow {
    [self writeValueWithCmdid:CMDID_WATER_CONTROL data:COLD_WATER_DATA];

}
-(void)turnOffWater {
    [self writeValueWithCmdid:CMDID_WATER_CONTROL data:TURN_OFF_WATER_DATA];
}

#pragma mark - segue
-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"EnterBackground"]) {
        BackgroundViewController *vc = (BackgroundViewController *)segue.destinationViewController;
        vc -> baby = self -> baby;
        vc.currPeripheral = self.currPeripheral;
        vc.receiveCharacteristic = self.receiveCharacteristic;
        vc.sendCharacteristic = self.sendCharacteristic;
    }
}
@end
