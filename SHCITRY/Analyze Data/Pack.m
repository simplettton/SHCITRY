//
//  Pack.m
//  SHCITRY
//
//  Created by Binger Zeng on 2017/12/26.
//  Copyright © 2017年 Shenzhen Lifotronic Technology Co.,Ltd. All rights reserved.
//

#import "Pack.h"
static const UInt8 KPacketHeadValue = 0xAA;
static const UInt8 KPacketBeginValue = 0xFD;
@implementation Pack
+ (NSData *)packetWithCmdid:(Byte)cmdid dataEnabled:(BOOL)dataEnabled data:(NSString *)dataString
{
    NSData *pdata = [self convertHexStrToData:dataString];
    
    UInt8 lengthOfData = [pdata length];
    
    UInt8 length = 1+2;
    if (dataEnabled) {  length += (Byte)lengthOfData;   }
    uint8_t *tmpData = malloc(sizeof(*tmpData)*100);
    
    //crc16检验 长度字节到包头字节
    tmpData[0] = length;
    NSLog(@"length = %d",tmpData[0]);
    tmpData[1] = cmdid;
    Byte *data = (Byte *)[pdata bytes];
    if (dataEnabled)
    {
        if (dataString) {
            for (int i = 0; i<lengthOfData; i++)
            {
                tmpData[2+i] = data[i];
                //            NSLog(@"data [%d] = %x",i,data[i]);
            }
        }
    }
    
    NSData *datatmp = [NSData dataWithBytes:tmpData length:lengthOfData +2];
    
    //计算crc校验码
    NSData *crcData = [self getCrcVerifyCode:datatmp];
    
//    const uint8_t *byte = (const uint8_t *)tmpData;
//    UInt16 crc16 = gen_crc16(byte, lengthOfData+2);
//    //大端模式
//    tmpData[lengthOfData+2] = (Byte)((crc16 >> 8) & 0xFF);
//    tmpData[lengthOfData+3] = (Byte)(crc16 & 0xFF);
    
    //取出crc校验码的高位和低位
    Byte *crcBytes = (Byte *)[crcData bytes];
    tmpData[lengthOfData+2] = crcBytes[0];
    tmpData[lengthOfData+3] = crcBytes[1];
    
//    NSLog(@"crc[0] = %x",tmpData[lengthOfData + 2]);
//    NSLog(@"crc [1] = %x",tmpData[lengthOfData + 3]);

    uint8_t *ls = malloc(sizeof(*ls)*100);
    ls[0] = KPacketBeginValue;
    ls[1] = KPacketHeadValue;
    UInt32 lengthOfLs = 2;
    for (int i = 0; i<(lengthOfData+4); i++)
    {
        ls[lengthOfLs] = tmpData[i];
        lengthOfLs++;
    }
    NSData * packData = [NSData dataWithBytes:ls length:lengthOfLs];
    
//    Byte arrayhead [] = {KPacketBeginValue,KPacketHeadValue};
//    NSData *headData = [[NSData alloc]initWithBytes:arrayhead length:sizeof(arrayhead)];
    Byte *byte = (Byte *)[packData bytes];
    for (int i = 0; i< [packData length]; i ++) {
        NSLog(@"send--------------------------------------bytes[%d] = %x",i,byte[i]);
    }
    
    return packData;
}
//#define PLOY 0XFFFF
//uint16_t gen_crc16(const uint8_t *data, uint16_t size) {
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
//    NSLog(@"crc = %hx",crc);
//    return crc;
//
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

//大端模式
+ (NSData *) convertHexStrToData:(NSString *)hexString {
    NSMutableData* data = [NSMutableData data];
    int idx;
    for (idx = 0; idx+2 <= hexString.length; idx+=2) {
        NSRange range = NSMakeRange(idx, 2);
        NSString* hexStr = [hexString substringWithRange:range];
        NSScanner* scanner = [NSScanner scannerWithString:hexStr];
        unsigned int intValue;
        [scanner scanHexInt:&intValue];
        [data appendBytes:&intValue length:1];
    }
    return data;
}


@end
