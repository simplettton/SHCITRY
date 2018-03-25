//
//  HomeViewController.h
//  SHCITRY
//
//  Created by Macmini on 2017/12/25.
//  Copyright © 2017年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"

@interface HomeViewController : UIViewController{
    @public
    BabyBluetooth *baby;
}
@property(strong,nonatomic)CBPeripheral *currPeripheral;
@end
