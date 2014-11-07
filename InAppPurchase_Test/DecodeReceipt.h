//
//  DecodeReceipt.h
//  InAppPurchase_Test
//
//  Created by ohtaisao on 2014/11/07.
//  Copyright (c) 2014年 isao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DecodeReceipt : NSObject
-(NSDictionary *)decode:(NSData*)data;
@end
