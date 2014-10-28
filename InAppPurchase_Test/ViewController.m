//
//  ViewController.m
//  InAppPurchase_Test
//
//  Created by ohtaisao on 2014/10/28.
//  Copyright (c) 2014年 isao. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark --
#pragma mark action
-(IBAction)pay_syouhiItem:(id)sender
{
    if ([self checkInAppPurchase]) {
        [self startInAppPurchase];
    }
    
}


- (BOOL)checkInAppPurchase
{
    if (![SKPaymentQueue canMakePayments]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
                                                        message:@"アプリ内課金が制限されています。"
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:@"OK", nil];
        [alert show];
        return NO;
    }
    return YES;
}

- (void)startInAppPurchase
{
    // com.companyname.application.productidは、「1-1. iTunes ConnectでManage In-App Purchasesの追加」で作成したProduct IDを設定します。
    NSSet *set = [NSSet setWithObjects:@"com.isao.inapppurchasetest.payment_item1 ", nil];
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:set];
    productsRequest.delegate = self;
    [productsRequest start];
}

#pragma mark SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    // 無効なアイテムがないかチェック
    if (response == nil) {
        NSLog(@"Product Response is nil");
        return;
    }
    
    // 確認できなかったidentifierをログに記録
    for (NSString *identifier in response.invalidProductIdentifiers) {
        NSLog(@"invalid product identifier: %@", identifier);
    }
       
    if ([response.invalidProductIdentifiers count] > 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"エラー"
                                                        message:@"アイテムIDが不正です。"
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil, nil];
        [alert show];
        return;
    }
    
     
    // 購入処理開始(「iTunes Storeにサインイン」ポップアップが表示)
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    for (SKProduct *product in response.products) {
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }
}

// トランザクション処理
#pragma mark SKPaymentTransactionObserver
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions
{
    for (SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchasing:
                NSLog(@"購入処理中");
                // TODO: インジケータなど回して頑張ってる感を出す。
                break;
            case SKPaymentTransactionStatePurchased:
                NSLog(@"購入成功");
                // TODO: アイテム購入した処理（アップグレード版の機能制限解除処理等）
                // TODO: 購入の持続的な記録
                [queue finishTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                NSLog(@"購入失敗: %@, %@", transaction.transactionIdentifier, transaction.error);
                // TODO: 失敗のアラート表示等
                break;
            case SKPaymentTransactionStateRestored:
                // リストア処理
                NSLog(@"以前に購入した機能を復元");
                [queue finishTransaction:transaction];
                // TODO: アイテム購入した処理（アップグレード版の機能制限解除処理等）
                break;
            default:
                [queue finishTransaction:transaction];
                break;
        }
    }
}

// リストア処理結果
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    NSLog(@"リストア失敗:%@", error);
    // TODO: 失敗のアラート表示等
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    NSLog(@"全てのリストア完了");
    // TODO: 完了のアラート表示等
}

//購入終了処理
#pragma mark SKPaymentQueue
- (void)paymentQueue:(SKPaymentQueue *)queue removedTransactions:(NSArray *)transactions
{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}

@end
