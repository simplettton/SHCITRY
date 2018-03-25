//
//  ControlCell.m
//  SHCITRY
//
//  Created by simplettton on 2018/1/30.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "ControlCell.h"

@implementation ControlCell

- (void)awakeFromNib {
    [super awakeFromNib];
    self.segmentedControl.selectedSegmentIndex = 1;
    [self configureColor];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}
- (IBAction)controlValueChanged:(UISegmentedControl *)sender {
    [self configureColor];

}
-(void)configureColor {
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0:
            self.label.textColor = [UIColor colorWithRed:68.0/255.0 green:161./255.0 blue:233.0/255.0 alpha:1];
//            self.segmentedControl.tintColor = [UIColor colorWithRed:68.0/255.0 green:161./255.0 blue:233.0/255.0 alpha:1];
            break;
        case 1:
            self.label.textColor = [UIColor blackColor];
//            self.segmentedControl.tintColor = [UIColor blackColor];
        default:
            break;
    }
}

@end
