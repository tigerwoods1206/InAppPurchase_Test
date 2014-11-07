//
//  DecodeReceipt.m
//  InAppPurchase_Test
//
//  Created by ohtaisao on 2014/11/07.
//  Copyright (c) 2014年 isao. All rights reserved.
//

#import "DecodeReceipt.h"
#include <openssl/x509.h>
#include <openssl/pkcs7.h>
#include <openssl/err.h>
#include "Payload.h"

@implementation DecodeReceipt

#define INAPP_ATTR_START	1700
#define INAPP_QUANTITY	1701
#define INAPP_PRODID	1702
#define INAPP_TRANSID	1703
#define INAPP_PURCHDATE	1704
#define INAPP_ORIGTRANSID	1705
#define INAPP_ORIGPURCHDATE	1706
#define INAPP_ATTR_END	1707
#define INAPP_SUBEXP_DATE 1708
#define INAPP_WEBORDER 1711
#define INAPP_CANCEL_DATE 1712

NSString *kReceiptInAppQuantity	= @"Quantity";
NSString *kReceiptInAppProductIdentifier	= @"ProductIdentifier";
NSString *kReceiptInAppTransactionIdentifier	= @"TransactionIdentifier";
NSString *kReceiptInAppPurchaseDate	= @"PurchaseDate";
NSString *kReceiptInAppOriginalTransactionIdentifier	= @"OriginalTransactionIdentifier";
NSString *kReceiptInAppOriginalPurchaseDate	= @"OriginalPurchaseDate";
NSString *kReceiptInAppSubscriptionExpirationDate = @"SubExpDate";
NSString *kReceiptInAppCancellationDate = @"CancelDate";
NSString *kReceiptInAppWebOrderLineItemID = @"WebItemId";

-(NSDictionary *)decode:(NSData*)data
{
    NSMutableDictionary *info = [NSMutableDictionary dictionary];
    
    /* ペイロードの解析で使用される変数。データ型はどちらもPayload.hで宣言されています。*/
    Payload_t *payload = NULL;
    asn_dec_rval_t rval;
    
    rval = asn_DEF_Payload.ber_decoder(NULL, &asn_DEF_Payload, (void **)&payload, (void *)[data bytes], (int)[data length], 0);
    OCTET_STRING_t *string;
    NSString *key;
    
    for (size_t i = 0; i < payload->list.count; i++) {
        ReceiptAttribute_t *entry;
        entry = payload->list.array[i];
        switch (entry->type) {
            case INAPP_ATTR_START:
                
                break;
            case INAPP_QUANTITY:
                string = &entry->value;
                NSLog(@"%s",string);
                key = kReceiptInAppQuantity;
                break;
            case INAPP_PRODID:
                string = &entry->value;
                string->buf += 2;
                string->size -= 2;
                NSLog(@"%s",string);
                key = kReceiptInAppProductIdentifier;
                break;
            case INAPP_TRANSID:
                string = &entry->value;
                string->buf += 2;
                string->size -= 2;
                NSLog(@"%s",string);
                key = kReceiptInAppTransactionIdentifier;
                break;
            case INAPP_PURCHDATE:
                string = &entry->value;
                NSLog(@"%s",string);
                key = kReceiptInAppPurchaseDate;
                break;
            case INAPP_ORIGTRANSID:
                string = &entry->value;
                string->buf += 2;
                string->size -= 2;
                NSLog(@"%s",string);
                key = kReceiptInAppOriginalTransactionIdentifier;
                break;
            case INAPP_ORIGPURCHDATE:
                string = &entry->value;
                NSLog(@"%s",string);
                key = kReceiptInAppOriginalPurchaseDate;
                break;
            case INAPP_ATTR_END:
                //string = &entry->value;
               // NSLog(@"%s",string);
                
                break;
            case INAPP_SUBEXP_DATE:
                string = &entry->value;
                NSLog(@"%s",string);
                key = kReceiptInAppSubscriptionExpirationDate;
                break;
            case INAPP_WEBORDER:
                string = &entry->value;
                NSLog(@"%s",string);
                key = kReceiptInAppWebOrderLineItemID;
                break;
            case INAPP_CANCEL_DATE:
                string = &entry->value;
                NSLog(@"%s",string);
                key = kReceiptInAppCancellationDate;
                break;
            default:
                break;
        }
        NSString *nsstring = [[NSString alloc] initWithBytes:string->buf
                                                    length:(NSUInteger)string->size
                                                  encoding:NSUTF8StringEncoding];
        
        [info setObject:nsstring forKey:key];
    }

    return info;
}

@end
