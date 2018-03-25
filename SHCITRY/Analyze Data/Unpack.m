//
//  Unpack.m
//  SHCITRY
//
//  Created by Binger Zeng on 2018/1/2.
//  Copyright © 2018年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "Unpack.h"
#define KPacketHeadValue 0xAA
#define KPacketBeginValue 0xFD

@implementation Unpack

+(NSData *)unpackDataWithoutCRC:(NSData *)pdata{
    Byte *dataBytes = (Byte *)[pdata bytes];
    //取出cmdid开头的数据
    UInt32 lengthOfDataWithoutHead = dataBytes[2];
    uint8_t *ls = malloc(sizeof(*ls) * lengthOfDataWithoutHead);
    UInt32 lengthOfLs = 0;
    for (UInt32 i = 3 ; i<lengthOfDataWithoutHead - 2; i++) {
        UInt8 curChar = dataBytes[i];
        ls[lengthOfLs++] = curChar;
    }
    
    NSData *dataLs = [NSData dataWithBytes:ls length:lengthOfLs];
    return dataLs;
}



+(NSData *)unpackData:(NSData *)pdata {
    Byte *byte = (Byte *)[pdata bytes];
    for (int i = 0; i< [pdata length]; i ++) {
        NSLog(@"receive--------------------------------------bytes[%d] = %x",i,byte[i]);
    }
    
    UInt32 nheadPos = 0;
    Byte *dataBytes = (Byte *)[pdata bytes];
    NSInteger lengthOfData = [pdata length];
    //寻找头部
    BOOL hasHead = NO;
    for (UInt32 i = 0; i<lengthOfData; i++)
    {
        if (dataBytes[i] == KPacketBeginValue && dataBytes[i+1] == KPacketHeadValue)
        {
            hasHead = YES;
            //获取头部索引
            nheadPos = ++i;
            break;
        }
    }
    //找不到头部，返回错误
    if (!hasHead)
    {
        NSLog(@"error:cannot find head");
        return nil;
    }
    //取出cmdid开头的数据
    UInt32 lengthOfDataWithoutHead = dataBytes[nheadPos + 1];
    uint8_t *ls = malloc(sizeof(*ls) * lengthOfDataWithoutHead);
    UInt32 lengthOfLs = 0;
    for (UInt32 i = nheadPos +2 ; i<lengthOfDataWithoutHead - 2; i++) {
        UInt8 curChar = dataBytes[i];
        ls[lengthOfLs++] = curChar;
    }
    
    NSData *dataLs = [NSData dataWithBytes:ls length:lengthOfLs];
    
    //计算验证码
    NSData *crcData = [self getCrcVerifyCode:dataLs];
//    const uint8_t *byte = (const uint8_t *)ls;
//    UInt16 crc16 = gen_checkCrc16(byte, lengthOfLs);
    
    
    //验证检验码
    NSInteger crcOffset = nheadPos + 1 + lengthOfLs;
    
    //计算好的crc NSData转成UInt16
    UInt16 crc16;
    [crcData getBytes:&crc16 length:2];
    
    //对比计算的crc和包中的crc校验码是否一样
    if(crc16 != OSReadBigInt16(dataBytes, crcOffset))
    {
//        ls = NULL;
        NSLog(@"error: pack checkcrc error");
    }
    NSData *data = [NSData dataWithBytes:ls length:lengthOfLs];
    return data;
}
//#define PLOY 0XFFFF
//uint16_t gen_checkCrc16(const uint8_t *data, uint16_t size) {
//    uint16_t crc = 0;
//    uint8_t i;
//    for (; size > 0; size--) {
//        crc = crc ^ (*data++ <<8);
//        for (i = 0; i < 8; i++) {
//            if (crc & 0X8000) {
//                crc = (crc << 1) ^ PLOY;
//            }else {
//                crc <<= 1;
//            }
//        }
//        crc &= 0XFFFF;
//    }
//    return crc;
//}
+(NSData *)getCrcVerifyCode:(NSData *)data {
    int crcWord = 0x0000ffff;
    
    Byte *dataArray = (Byte *)[data bytes];
    for(int i = 0; i < data.length; i++) {
        Byte byte = dataArray[i];
        crcWord ^= (int)byte & 0x000000ff;
        for (int j = 0; j < 8; j++) {
            if ((crcWord & 0x00000001) == 1) {
                crcWord = crcWord >> 1;
                crcWord = crcWord ^ 0x0000A001;
            }else {
                crcWord = (crcWord >> 1);
            }
        }
    }
    Byte crcH = (Byte)0xff&(crcWord>>8);
    Byte crcL = (Byte)0xff&crcWord;
    Byte arraycrcp[] = {crcH,crcL};
    NSData *datacrc = [[NSData alloc]initWithBytes:arraycrcp length:sizeof(arraycrcp)];
    return datacrc;
    
}
@end
