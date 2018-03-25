//
//  EditTableViewController.m
//  
//
//  Created by simplettton on 2018/1/31.
//

#import "EditTableViewController.h"

@interface EditTableViewController ()<UITextFieldDelegate>{
    BabyBluetooth *baby;
}
@property (weak, nonatomic) IBOutlet UITextField *contentTextFiled;
@property (strong ,nonatomic)CBPeripheral *peripheral;

@end

@implementation EditTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initAll];
    self.title = @"扫风电机速度";
    
}

-(void)initAll{
    
    baby = [BabyBluetooth shareBabyBluetooth];
    self.peripheral = [[baby findConnectedPeripherals]firstObject];
    
    self.tableView.tableFooterView = [[UIView alloc]init];
    //tableview group样式 section之间的高度调整
    self.tableView.sectionHeaderHeight  = 0;
    self.tableView.sectionFooterHeight = 20;
    self.tableView.contentInset = UIEdgeInsetsMake(20 - 35, 0, 0, 0);
    

    UIBarButtonItem *setButton = [[UIBarButtonItem alloc]initWithTitle:@"设置" style:UIBarButtonItemStylePlain target:self action:@selector(writeValue:)];
    self.navigationItem.rightBarButtonItem = setButton;
    
}
- (IBAction)writeValue:(id)sender {
    if (self.sendCharacteristic) {
        [self.peripheral writeValue:[Pack packetWithCmdid:0x5a
                                              dataEnabled:YES
                                                     data:[self byteToHex:[self.contentTextFiled.text integerValue]]]
                  forCharacteristic:self.sendCharacteristic
                               type:CBCharacteristicWriteWithResponse];
    }

    [self.navigationController popViewControllerAnimated:YES];
    
    

}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}
-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

//单字节十进制数转十六进制字字符串

-(NSString *)byteToHex:(Byte)value{
    NSString *hexStr = @"";
    NSString *newHexStr = [NSString stringWithFormat:@"%x",value&0xFF];
    if([newHexStr length]==1)
        hexStr = [NSString stringWithFormat:@"0%@",newHexStr];
    else
        hexStr = newHexStr;
    return newHexStr;
}
@end
