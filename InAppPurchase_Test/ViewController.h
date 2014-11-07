//
//  ViewController.h
//  InAppPurchase_Test
//
//  Created by ohtaisao on 2014/10/28.
//  Copyright (c) 2014年 isao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController <SKProductsRequestDelegate,SKPaymentTransactionObserver,UIPickerViewDelegate, UIPickerViewDataSource>

-(IBAction)pay_syouhiItem:(id)sender;
-(IBAction)pay_hisyouhiItem:(id)sender;
-(IBAction)view_ReceiptDetail:(id)sender;
@end

