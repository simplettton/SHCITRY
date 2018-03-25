//
//  Pack.h
//  SHCITRY
//
//  Created by Binger Zeng on 2017/12/26.
//  Copyright © 2017年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Pack : NSObject
+(NSData *)packetWithCmdid:(Byte)cmdid dataEnabled:(BOOL)dataEnabled data:(NSString *)dataString;
@end
