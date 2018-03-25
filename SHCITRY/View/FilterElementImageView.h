//
//  FilterElementImageView.h
//  SHCITRY
//
//  Created by Binger Zeng on 2018/1/18.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FilterElementImageView : UIImageView
@property (nonatomic,strong)NSTimer *changeColorTimer;
-(void)changeColor;
-(void)deallocTimer;
@end
