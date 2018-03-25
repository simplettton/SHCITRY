//
//  BackgroundViewController.m
//  SHCITRY
//
//  Created by simplettton on 2018/1/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "BackgroundViewController.h"


#define SERVICE_UUID           @"1b7e8251-2877-41c3-b46e-cf057c562023"
#define TX_CHARACTERISTIC_UUID @"5e9bf2a8-f93f-4481-a67e-3b2f4a07891a"
#define RX_CHARACTERISTIC_UUID @"8ac32d3f-5cb9-4d44-bec2-ee689169f626"
#define KScreenWidth [UIScreen mainScreen].bounds.size.width

#define CMDID_BackPACK1 0x50
#define CMDID_BACKPACK2 0X51

#define CMDID_WIND_MACHINE_SPEED 0X5a
#define CMDID_FAN 0X5e

#define CELL_KEY_TAG 1
#define CELL_VALUE_TAG 2
@interface BackgroundViewController ()<UITableViewDelegate,UITableViewDataSource>
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (strong ,nonatomic)NSArray *dataKeys;
@property (strong ,nonatomic)NSArray *controlKeys;
@property (strong ,nonatomic)NSArray *cmdids;
@property (strong ,nonatomic)NSMutableDictionary *dataDic;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeight;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;


@end

@implementation BackgroundViewController

#pragma mark - lifeCycle
- (void)viewDidLoad {
    
    [super viewDidLoad];
    [self initAll];

    self.title = @"Background";
    
    self.tableView.scrollEnabled = NO;
}

-(void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:YES];
    [self babyDelegate];
    [self askForBackPack];
    if(self.receiveCharacteristic!=nil) {

        //通知方式监听一个characteristic的值
        [baby notify:self.currPeripheral
      characteristic:self.receiveCharacteristic
               block:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
                   NSLog(@"----------------------------------------------");
                   NSData *data = self.receiveCharacteristic.value;
                   [self analyzeData:data];
               }];
    }

}
-(void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:YES];

    
}
-(void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    
    [self reloadTableView];
}

-(void)initAll {
    self.dataKeys = @[@"TO",@"TH",@"TP",@"TL",@"TN",@"TW",@"TL",@"H",@"T",@"TR1(温度)",@"TR2(湿度)",@"WL(相对水位)"];
    self.controlKeys = @[@"出水阀门",@"冲洗电磁阀",@"循环阀",@"冷水泵",@"扫风电机速度",@"紫外杀菌",@"制冷阀1",@"制冷阀2",@"风扇"];

    self.dataDic = [[NSMutableDictionary alloc]init];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self setupSwipe];
    [self babyDelegate];
    
    UIBarButtonItem *backButton = [[UIBarButtonItem alloc]init];
    backButton.title = @"Back";
    self.navigationItem.backBarButtonItem = backButton;
    
}

#pragma mark - swipe
- (void)setupSwipe {
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight)];
    [self.view addGestureRecognizer:swipe];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
}

- (void)swipeRight {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - babyDelegate

-(void)babyDelegate {
    
    [baby setBlockOnDisconnect:^(CBCentralManager *central, CBPeripheral *peripheral, NSError *error) {
        NSLog(@"设备：%@ 已断开连接",peripheral.name);
        //        [baby.centralManager connectPeripheral:peripheral options:nil];
//        weakSelf.BLEisConnected = NO;
        [SVProgressHUD showInfoWithStatus:[NSString stringWithFormat:@"设备：%@ 已断开连接",peripheral.name]];
//        [SVProgressHUD dismissWithDelay:0.9];
    }];
    
    [baby setBlockOnDiscoverServices:^(CBPeripheral *peripheral, NSError *error) {
        
    }];
    
    [baby setBlockOnReadValueForCharacteristic:^(CBPeripheral *peripheral, CBCharacteristic *characteristics, NSError *error) {
        
    }];
    
    [baby setBlockOnDidUpdateNotificationStateForCharacteristic:^(CBCharacteristic *characteristic, NSError *error)
     {
         NSLog(@"didUpdata");
         
     }];
    
}

#pragma mark - tableView Delegate
-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}
-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    if (section == 0) {
        return self.dataKeys.count;
    }else{
        return self.controlKeys.count;
    }

}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{

    if (indexPath.section == 0) {
        
        UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"cell"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        if (!cell) {
            cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"cell"];
        }
        UILabel *keyLabel = [cell viewWithTag:CELL_KEY_TAG];
        UILabel *valueLabel = [cell viewWithTag:CELL_VALUE_TAG];
        keyLabel.text = self.dataKeys[indexPath.row];
        
        //根据datakey在dataDic中取出value
        NSString *dataKey = self.dataKeys[indexPath.row];
        NSString *dataValue = self.dataDic[dataKey];
        valueLabel.text = dataValue != nil? dataValue:@"no data";
        return cell;
    }else if(indexPath.section == 1){

        if (indexPath.row == [self.controlKeys indexOfObject:@"扫风电机速度"]) {
            ParameterCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ParameterCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleDefault;
            
            if (!cell) {
                NSArray *array = [[NSBundle mainBundle]loadNibNamed:@"ParameterCell" owner:self options:nil];
                cell = (ParameterCell *)array.firstObject;
                cell.selectionStyle = UITableViewCellSelectionStyleDefault;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                
            }
            NSString *controlKey = self.controlKeys[indexPath.row];
            
            cell.keyLabel.text = controlKey;
            NSString *controlValue = self.dataDic[controlKey];
            cell.valueLabel.text = controlValue != nil? controlValue:@"(value:0)";
            
            cell.stepper.hidden = YES;
            
            return cell;
        }else if(indexPath.row == [self.controlKeys indexOfObject:@"风扇"]){
            ParameterCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ParameterCell"];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            if (!cell) {
                NSArray *array = [[NSBundle mainBundle]loadNibNamed:@"ParameterCell" owner:self options:nil];
                cell = (ParameterCell *)array.firstObject;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                
            }
            
            cell.keyLabel.text = self.controlKeys[indexPath.row];
            cell.stepper.minimumValue = 0;
            cell.stepper.maximumValue = 5;
            
            [cell.stepper addTarget:self action:@selector(stepperValueChanged:) forControlEvents:UIControlEventValueChanged];
            
            return cell;
        }else{
            ControlCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"ControlCell"];
            if (!cell) {
                NSArray *array = [[NSBundle mainBundle]loadNibNamed:@"ControlCell" owner:self options:nil];
                cell = (ControlCell *)array.firstObject;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
            }
            cell.label.text = self.controlKeys[indexPath.row];
            
            [cell.segmentedControl addTarget:self
                                      action:@selector(sendControlCommand:) forControlEvents:UIControlEventValueChanged];

            //标志cell 计算控制命令
            if (indexPath.row < 4) {
                [cell.segmentedControl setTag:indexPath.row];
            }else{
                [cell.segmentedControl setTag:indexPath.row +1];
            }

            
            return cell;
        }
//        keyLabel.text = self.controlKeys[indexPath.row];
    }
    return nil;
    
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 50;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    if (section == 0) {
        return [NSString stringWithFormat:@"datas(number:%lu)",(unsigned long)self.dataKeys.count];
    }else {
        return [NSString stringWithFormat:@"control(number:%lu)",(unsigned long)self.controlKeys.count];
    }

}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
//    ParameterCell *cell = (ParameterCell *)[tableView cellForRowAtIndexPath:indexPath];
//    NSString *controlKey  = cell.keyLabel.text;
    
    
    if (indexPath.section == 1) {
        if (indexPath.row == [self.controlKeys indexOfObject:@"扫风电机速度"]){
           [self performSegueWithIdentifier:@"ShowEditViewController" sender:nil];
        }
    }
}

-(void)reloadTableView {
    [self.tableView reloadData];
    self.tableViewHeight.constant = 1180.0f
    ;
}
#pragma mark - receiveData

-(void)analyzeData :(NSData *)receivedData {
    NSData *data = [Unpack unpackData:receivedData];
    Byte *bytes = (Byte *)[data bytes];
    Byte cmdid = bytes[0];
    
    if ( CMDID_BackPACK1 == cmdid) {
        Byte intergerPart;
        Byte fractionalPart;
        
        //前七个
        for (int i = 1; (i + 2) <([data length]-1); i = i + 2) {
            intergerPart = bytes[i];
            fractionalPart = bytes[i+1];
            NSString *dataKey = self.dataKeys[(i-1)/2];
            if (dataKey != nil) {
                self.dataDic[dataKey] = [NSString stringWithFormat:@"%d.%d",intergerPart,fractionalPart];
            }
        }
    }
    
    if (CMDID_BACKPACK2 == cmdid) {
        Byte intergerPart;
        Byte fractionalPart;
        //剩下五个
        for (int i = 1; (i + 2) <([data length]-1); i = i + 2) {
            intergerPart = bytes[i];
            fractionalPart = bytes[i+1];
            
            NSString *dataKey = self.dataKeys[(i-1)/2 + 7];
            if (dataKey != nil) {
                self.dataDic[dataKey] = [NSString stringWithFormat:@"%d.%d",intergerPart,fractionalPart];
            }
        }
        
    }
    [self reloadTableView];
}

#pragma mark - writeData

-(void)writeValueWithCmdid:(Byte)cmdid data:(NSString *)data{
    if (self.currPeripheral) {
        if (self.sendCharacteristic) {
            
            [self.currPeripheral writeValue:[Pack packetWithCmdid:cmdid
                                                      dataEnabled:YES
                                                             data:data]
                          forCharacteristic:self.sendCharacteristic
                                       type:CBCharacteristicWriteWithResponse];
        }
    }
}

#pragma mark -APPComand
-(void)askForBackPack {
    
    [self writeValueWithCmdid:CMDID_BackPACK1 data:nil];
    [self writeValueWithCmdid:CMDID_BACKPACK2 data:nil];
}

-(void)stepperValueChanged:(id)sender{
    UIStepper *stepper = (UIStepper *)sender;
    NSString *data = [NSString stringWithFormat:@"0%d",(int)stepper.value];
    [self writeValueWithCmdid:CMDID_FAN data:data];
    
}
-(void)sendControlCommand:(id)sender{
    UISegmentedControl* segmentedControl = (UISegmentedControl*)sender;
    Byte cmdid = segmentedControl.tag + 0x55;
    switch (segmentedControl.selectedSegmentIndex) {
        case 0:
            [self writeValueWithCmdid:cmdid data:@"01"];
            break;
        case 1:
            [self writeValueWithCmdid:cmdid data:@"00"];
            break;
            
        default:
            break;
    }
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender{
    if ([segue.identifier isEqualToString:@"ShowEditViewController"]) {
        EditTableViewController *vc = segue.destinationViewController;
        if ([sender isKindOfClass:[NSString class]]) {
            vc.controlValue = self.dataDic[@"扫风电机速度"];
            vc.sendCharacteristic = self.sendCharacteristic;
            vc.returnBlock = ^(NSString *setValue){
                NSIndexPath *indexPath = [NSIndexPath indexPathForRow:4 inSection:1];
                ParameterCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
                if (cell != nil) {
                    cell.valueLabel.text = [NSString stringWithFormat:@"value:%@",setValue];
                }
            };
        }
    }
}

@end
