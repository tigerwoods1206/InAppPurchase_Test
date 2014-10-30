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
-(BOOL)checkAll;
-(BOOL)checkPosition;
-(BOOL)checkSignature;
-(BOOL)checkBundleID;
-(BOOL)checkBundleVersion;
-(BOOL)checkGUID;

@end
