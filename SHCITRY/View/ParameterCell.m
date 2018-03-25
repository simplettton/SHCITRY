//
//  ParameterCell.m
//  SHCITRY
//
//  Created by simplettton on 2018/1/30.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "ParameterCell.h"

@implementation ParameterCell

- (void)awakeFromNib {
    [super awakeFromNib];
        self.valueLabel.text = [NSString stringWithFormat:@"(value:%d)",(uint)self.stepper.value];

    // Initialization code
}
- (IBAction)valueChanged:(id)sender {
    self.valueLabel.text = [NSString stringWithFormat:@"(value:%d)",(uint)self.stepper.value];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
