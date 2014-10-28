//
//  ViewController.h
//  InAppPurchase_Test
//
//  Created by ohtaisao on 2014/10/28.
//  Copyright (c) 2014年 isao. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <StoreKit/StoreKit.h>

@interface ViewController : UIViewController <SKProductsRequestDelegate,SKPaymentTransactionObserver>

-(IBAction)pay_syouhiItem:(id)sender;
@end

