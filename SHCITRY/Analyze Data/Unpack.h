//
//  Unpack.h
//  SHCITRY
//
//  Created by Binger Zeng on 2018/1/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Unpack : NSObject
+(NSData *)unpackData:(NSData *)pdata;
+(NSData *)unpackDataWithoutCRC:(NSData *)pdata;
@end
