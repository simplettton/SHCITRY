//
//  FilterElementImageView.m
//  SHCITRY
//
//  Created by Binger Zeng on 2018/1/18.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "FilterElementImageView.h"

@implementation FilterElementImageView

-(void)changeColor {
    self.highlighted = !self.highlighted;
}

-(void)deallocTimer {
    [self.changeColorTimer invalidate];
    self.changeColorTimer = nil;
}

@end
