    //
//  ViewController.m
//  BabyBluetoothAppDemo
//
//  Created by simplettton on 2017/7/31.
//  Copyright © 2017年 Simplettton. All rights reserved.
//

#import "SearchBLEViewController.h"
#import "HomeViewController.h"
#import "SVProgressHUD.h"
#define width [UIScreen mainScreen].bounds.size.width
#define height [UIScreen mainScreen].bounds.size.height
#define UIColorFromHex(s) [UIColor colorWithRed:(((s & 0xFF0000) >> 16 )) / 255.0 green:((( s & 0xFF00 ) >> 8 )) / 255.0 blue:(( s & 0xFF )) / 255.0 alpha:1.0]
@interface SearchBLEViewController ()
{
    NSMutableArray *peripheralDataArray;
    BabyBluetooth *baby;
}
- (IBAction)stopScan:(id)sender;
- (IBAction)startScan:(id)sender;
@property (strong, nonatomic)UIActivityIndicatorView *activityIndicatorView;
@end
@implementation SearchBLEViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"设备列表";
    [self initAll];
    
    
    //ttttttttttttttttttttttttttttttt
//    HomeViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"HomeViewController"];
//    [self.navigationController pushViewController:vc animated:YES];
    
//    NSData *data = [self hexStringToBytes:hexString];
//    Byte *dataByte = (Byte *)[data bytes];
//    for (int i =0; i<[data length]; i++) {
//        NSLog(@"data[%d] = %x",i,dataByte[i] );
//    }
    
}
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
    
    //停止之前的连接
    [baby cancelAllPeripheralsConnection];
    //设置委托后直接可以使用，无需等待CBCentralManagerStatePoweredOn状态。
    [self babyDelegate];
    
    peripheralDataArray = [[NSMutableArray alloc]init];
    [self.tableView reloadData];
    
    baby.scanForPeripherals().begin();
    [self.activityIndicatorView startAnimating];
}

-(void)viewWillDisappear:(BOOL)animated
{
    [baby cancelScan];
    [self.activityIndicatorView stopAnimating];
}

-(void)initAll{
    
    peripheralDataArray = [[NSMutableArray alloc]init];
    baby = [BabyBluetooth shareBabyBluetooth];
    
    self.navigationController.navigationBar.barTintColor = UIColorFromHex(0X212121);
    self.navigationController.navigationBar.barStyle = UIBarStyleBlack;
    self.navigationItem.rightBarButtonItem.tintColor = UIColorFromHex(0xFFFFFF);
    self.navigationItem.leftBarButtonItem.tintColor = UIColorFromHex(0xffffff);
    //    [self setupSwipe];
    self.tableView.tableFooterView = [[UIView alloc]init];
    //stopButton
    UIButton *btn = [[UIButton alloc]initWithFrame:CGRectMake(0, 0, 50 , 30)];
    [btn setTitle:@"stop" forState:UIControlStateNormal];
    [btn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
    [btn addTarget:self action:@selector(stopScan:) forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem *stopButton = [[UIBarButtonItem alloc]initWithCustomView:btn];
    //activityIndicatorView
    self.activityIndicatorView = [[UIActivityIndicatorView alloc]initWithFrame:CGRectMake(0, 0, 40, 30)];
    [self.activityIndicatorView setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhite];
    self.activityIndicatorView.hidesWhenStopped = YES;
    //[self.activityIndicatorView startAnimating];
    UIBarButtonItem *barButton = [[UIBarButtonItem alloc]initWithCustomView:self.activityIndicatorView];
    self.navigationItem.rightBarButtonItems = @[stopButton,barButton];

}
//- (NSData *) hexStringToBytes:(NSString *)hexString {
//    NSMutableData* data = [NSMutableData data];
//    int idx;
//    for (idx = 0; idx+2 <= hexString.length; idx+=2) {
//        NSRange range = NSMakeRange(idx, 2);
//        NSString* hexStr = [hexString substringWithRange:range];
//        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
//        unsigned int intValue;
//        [scanner scanHexInt:&intValue];
//        [data appendBytes:&intValue length:1];
//    }
//    return data;
//}

#pragma mark -蓝牙配置和操作
//蓝牙网关初始化和委托方法设置
-(void)babyDelegate
{
    
    __weak typeof(self) weakSelf = self;
    [baby setBlockOnCentralManagerDidUpdateState:^(CBCentralManager *central) {
        if (central.state == CBManagerStatePoweredOn) {
            [SVProgressHUD showSuccessWithStatus:@"蓝牙打开成功，开始扫描设备"];
            [SVProgressHUD dismissWithDelay:0.9];
            [weakSelf.activityIndicatorView startAnimating];
        }else if(central.state == CBManagerStatePoweredOff){
            [SVProgressHUD showInfoWithStatus:@"请打开蓝牙以连接设备"];
            [SVProgressHUD dismissWithDelay:0.9];
        }
    }];
    
    
    [baby setBlockOnDiscoverToPeripherals:^(CBCentralManager *central, CBPeripheral *peripheral, NSDictionary *advertisementData, NSNumber *RSSI) {
//        [weakSelf.activityIndicatorView startAnimating];
        NSLog(@"搜索到了设备:%@",peripheral.name);
        [weakSelf insertTableView:peripheral advertisementData:advertisementData RSSI:RSSI];
    }];
    
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        NSLog(@"diddiscoverservices");

    }];
    
    [baby setFilterOnDiscoverPeripherals:^BOOL(NSString *peripheralName, NSDictionary *advertisementData, NSNumber *RSSI) {
        
        //最常用的场景是查找某一个前缀开头的设备
//        if ([peripheralName hasPrefix:@"Pxxxx"] ) {
//            return YES;
//        }
//        return NO;
        
        //设置查找规则是名称大于0 ， the search rule is peripheral.name length > 0
        if (peripheralName.length >0) {
            return YES;
        }
        return NO;
    }];

    
    NSDictionary *scanForPeripheralsWithOptions = @{CBCentralManagerScanOptionAllowDuplicatesKey:@YES};
    [baby setBabyOptionsWithScanForPeripheralsWithOptions:scanForPeripheralsWithOptions connectPeripheralWithOptions:nil scanForPeripheralsWithServices:nil discoverWithServices:nil discoverWithCharacteristics:nil];
}

#pragma mark -UIViewController 方法
//插入table数据
-(void)insertTableView:(CBPeripheral *)peripheral advertisementData:(NSDictionary *)advertisementData RSSI:(NSNumber *)RSSI{
    
    NSArray *peripherals = [peripheralDataArray valueForKey:@"peripheral"];
    if(![peripherals containsObject:peripheral]) {
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:peripherals.count inSection:0];
        [indexPaths addObject:indexPath];
        
        NSMutableDictionary *item = [[NSMutableDictionary alloc] init];
        [item setValue:peripheral forKey:@"peripheral"];
        [item setValue:RSSI forKey:@"RSSI"];
        [item setValue:advertisementData forKey:@"advertisementData"];
        [peripheralDataArray addObject:item];
        
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark -table委托 table delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
     return peripheralDataArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
    NSDictionary *item = [peripheralDataArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = [item objectForKey:@"peripheral"];
    NSDictionary *advertisementData = [item objectForKey:@"advertisementData"];
    NSNumber *RSSI = [item objectForKey:@"RSSI"];
    
//    NSLog(@"------%d",cell.frame.size.height);
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"cell"];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
//    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    //peripheral的显示名称,优先用kCBAdvDataLocalName的定义，若没有再使用peripheral name
    NSString *peripheralName;
    if ([advertisementData objectForKey:@"kCBAdvDataLocalName"]) {
        peripheralName = [NSString stringWithFormat:@"%@",[advertisementData objectForKey:@"kCBAdvDataLocalName"]];
    }else if(!([peripheral.name isEqualToString:@""] || peripheral.name == nil)){
        peripheralName = peripheral.name;
    }else
    {
        peripheralName = [peripheral.identifier UUIDString];
    }
    cell.textLabel.text = [NSString stringWithFormat:@"%@",peripheralName];
    //信号和服务
    cell.detailTextLabel.text = [NSString stringWithFormat:@"RSSI:%@",RSSI];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    //停止扫描
    [baby cancelScan];

    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *item = [peripheralDataArray objectAtIndex:indexPath.row];
    CBPeripheral *peripheral = [item objectForKey:@"peripheral"];
    
    HomeViewController *vc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"HomeViewController"];

    
//    if ([peripheral.name isEqualToString:@"ALX420"])
//    {
        vc.currPeripheral = peripheral;
        vc->baby = self->baby;
        [self.navigationController pushViewController:vc animated:YES];
//    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(nonnull NSIndexPath *)indexPath{
    return 60.0f;
}

- (IBAction)stopScan:(id)sender
{
    [baby cancelScan];
    [self.activityIndicatorView stopAnimating];
}

- (IBAction)startScan:(id)sender
{
    [self.activityIndicatorView startAnimating];
    baby.scanForPeripherals().begin();
}
#pragma mark - swipe

- (void)setupSwipe
{
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    [self.view addGestureRecognizer:swipe];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
}
- (void)swipeRight
{
//    [self performSegueWithIdentifier:@"SearchBLEReturnHome" sender:nil];
    [self.navigationController popViewControllerAnimated:YES];
}
@end
