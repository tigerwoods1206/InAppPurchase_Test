//
//  CheckReceipt.h
//  InAppPurchase_Test
//
//  Created by ohtaisao on 2014/10/29.
//  Copyright (c) 2014年 isao. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM (NSUInteger, ReceiptCheckStage) {
    kNone,
    kPositionTrue,
    kSignatureAppleTrue,
    kBundleIDTrue,
    kBundleVersionTrue,
    kGUIDHashTrue
};

@interface CheckReceipt : NSObject
{
    
}

@property(readonly,retain) NSArray *receiptDetail;

-(BOOL)checkAll;

@end
