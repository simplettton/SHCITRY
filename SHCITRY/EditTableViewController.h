//
//  EditTableViewController.h
//  
//
//  Created by simplettton on 2018/1/31.
//

#import <UIKit/UIKit.h>
#import "Pack.h"
#import <CoreBluetooth/CoreBluetooth.h>
#import "BabyBluetooth.h"

@interface EditTableViewController : UITableViewController
@property (nonatomic,copy)void(^returnBlock)(NSString *);
@property (nonatomic,strong)NSString *controlValue;
@property (nonatomic,strong)CBCharacteristic *sendCharacteristic;
@end
