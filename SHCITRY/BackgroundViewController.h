//
//  BackgroundViewController.h
//  SHCITRY
//
//  Created by simplettton on 2018/1/28.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import <SVProgressHUD.h>
#import "BabyBluetooth.h"
#import "EditTableViewController.h"
#import "ControlCell.h"
#import "ParameterCell.h"
#import "Pack.h"
#import "Unpack.h"


@interface BackgroundViewController : UIViewController{
    @public
    BabyBluetooth *baby;
}
@property(strong,nonatomic)CBPeripheral *currPeripheral;
@property (nonatomic,strong)CBCharacteristic *sendCharacteristic;
@property (nonatomic,strong)CBCharacteristic *receiveCharacteristic;
@end
