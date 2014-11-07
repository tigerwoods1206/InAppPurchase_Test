//
//  CheckReceipt.m
//  InAppPurchase_Test
//
//  Created by ohtaisao on 2014/10/29.
//  Copyright (c) 2014年 isao. All rights reserved.
//

#import "CheckReceipt.h"
#include <openssl/x509.h>
#include <openssl/pkcs7.h>
#include <openssl/err.h>
#include "Payload.h"
#import "DecodeReceipt.h"


@interface CheckReceipt () {
    ReceiptCheckStage curentStage;
    NSURL  *receiptURL;
    NSData *receiptBinary;
    PKCS7  *p7;
    NSMutableArray *receiptarr;
    
    //data for check receipt
    OCTET_STRING_t *bundle_id;
    OCTET_STRING_t *bundle_version;
    OCTET_STRING_t *opaque;
    OCTET_STRING_t *hash;
    
}

@end

@implementation CheckReceipt

-(id)init {
    self = [super init];
    if (self) {
        curentStage = kNone;
        receiptBinary = nil;
        receiptarr = [NSMutableArray array];
    }
    
    return self;
}

-(BOOL)checkAll {
    ERR_load_PKCS7_strings();
    ERR_load_X509_strings();
    OpenSSL_add_all_digests(); // PKCS7_verify 関数の動作に必須です。
    
    BOOL stage = [self checkPosition]; //レシートの存在チェックをします。
    stage = [self checkSignature]; //アップルルート証明書を使った署名の確認
    stage = [self checkBundleID]; //レシートのBundleIDとInfo.plistのBundleIDの一致確認
    stage = [self checkBundleVersion]; //レシートとInfo.plistのBundleVesionの一致確認
    stage = [self checkGUID]; //レシートとデバイスのGUIDの一致確認
    return stage; //全部のチェックを通ればOK
}


-(BOOL)checkPosition {
    receiptURL = [[NSBundle mainBundle] appStoreReceiptURL];
    if (receiptURL==nil) {
        return NO;
    }
    //
    curentStage   = kPositionTrue;
    return YES;
}

-(BOOL)checkSignature {
    if (curentStage!=kPositionTrue) {
        return NO;
    }
    if (receiptURL==nil) {
        return NO;
    }
    
    /* PKCS #7コンテナ(レシート)と確認の出力*/
    BIO *b_p7;
    /* 生データとしてのAppleのルート証明書と、そのOpenSSLによる表現*/
    BIO *b_x509;
    X509 *Apple;

    /* 信頼チェーン検証用のルート証明書*/
    X509_STORE *store = X509_STORE_new();
    
    /* ...BIO_new_mem_buf()を使用して両方のBIO変数のバッファとサイズを初期化... */
    receiptBinary = [NSData dataWithContentsOfURL:receiptURL];
    b_p7   = BIO_new_mem_buf((void *)[receiptBinary bytes], (int)[receiptBinary length]);
    
      /* ...Appleルート証明書をb_X509へロード... */
    NSData * rootCertData = appleRootCert();
    b_x509 = BIO_new_mem_buf((void *)[rootCertData bytes], (int)[rootCertData length]);
    
    /* レシートファイルのコンテンツをキャプチャし、p7変数にPKCS #7コンテナを代入*/
    p7 = d2i_PKCS7_bio(b_p7, NULL);
    
  
    int verifyReturnValue = 0;
   // const u_int8_t *data = (const u_int8_t *)rootCertData.bytes;
    if (store) {
      
        /* Appleルート証明書の値でb_x509を入力BIOとして初期化してX509データ構造体へロード。次にApple
         ルート証明書をこの構造体に追加*/
        Apple = d2i_X509_bio(b_x509, NULL);
        if (Apple) {
            /* 署名の確認時に抽出したレシートのペイロードを保持するためにb_outを出力BIOとして初期化*/
            BIO *payload = BIO_new(BIO_s_mem());
            X509_STORE_add_cert(store, Apple);
            if (payload) {
                /* 署名の確認。確認が正しければ、payloadにはPKCS #7のペイロードが格納され、rcは1になります。*/
                verifyReturnValue = PKCS7_verify(p7,NULL,store,NULL,payload,0);
                BIO_free(payload);
            }
            X509_free(Apple);
        }
    }
    
    if (verifyReturnValue!=1) {
        PKCS7_free(p7);
        return NO;
    }
    
    curentStage = kSignatureAppleTrue;
    
    return YES;
}

-(BOOL)checkBundleID {
    /* レシート属性を保存する変数*/
    bundle_id = NULL;
    bundle_version = NULL;
    opaque = NULL;
    hash = NULL;
    
    Payload_t *payload = [self payload];
    if (payload==nil) {
        return NO;
    }
    
    /* GUIDのハッシュ値の計算に必要な値を保存しながらレシート属性ごとに繰り返す*/
    NSString *appId = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleIdentifier"];
    
    
    for (size_t i = 0; i < payload->list.count; i++) {
        ReceiptAttribute_t *entry;
        entry = payload->list.array[i];
        switch (entry->type) {
            case 2:
                bundle_id = &entry->value;
                break;
            case 3:
                bundle_version = &entry->value;
                break;
            case 4:
                opaque = &entry->value;
                break;
            case 5:
                hash = &entry->value;
                break;
            case 17:
            {
                OCTET_STRING_t *string = &entry->value;
                NSLog(@"%ld",entry->type);
                NSData *data = [NSData dataWithBytes:string->buf length:(NSUInteger)string->size];
                DecodeReceipt *dec = [[DecodeReceipt alloc] init];
                [receiptarr addObject:[dec decode:data]];
                break;
            }
            case 19:
                NSLog(@"%ld",entry->type);
            case 21:
                NSLog(@"%ld",entry->type);
                break;
        }
    }
    
    _receiptDetail = receiptarr;
    
    NSString *receiptBundleIdString = [[NSString alloc] initWithBytes:bundle_id->buf +2
                                                               length:bundle_id->size -2
                                                             encoding:NSUTF8StringEncoding];
    //参照リンク先
    //http://www.cocoabuilder.com/archive/cocoa/300980-octet-string-nsstring.html
    
    if ([receiptBundleIdString isEqualToString:appId]) {
        NSLog(@"同じ文字列です");
        curentStage = kBundleIDTrue;
        return YES;
    } else {
        NSLog(@"異なる文字列です");
        return NO;
    }
    
   
}

-(BOOL)checkBundleVersion {
    if (curentStage != kBundleIDTrue) {
        return NO;
    }
    
    if (bundle_version==NULL) {
        return NO;
    }
    
    NSString *appVer = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
    NSString *receiptBundleVString = [[NSString alloc] initWithBytes:bundle_version->buf +2
                                                               length:bundle_version->size -2
                                                              encoding:NSUTF8StringEncoding];
    
    if ([appVer compare:receiptBundleVString]==NSOrderedSame) {
        NSLog(@"同じ文字列です appVer = %@  recipeVer = %@",appVer, receiptBundleVString );
        curentStage = kBundleVersionTrue;
        return YES;
    } else {
        NSLog(@"異なる文字列です appVer = %@  recipeVer = %@",appVer, receiptBundleVString );
        return NO;
    }
}

-(BOOL)checkGUID {
    if (curentStage != kBundleVersionTrue) {
        return NO;
    }
    
    if (opaque==NULL || bundle_id==NULL) {
        return NO;
    }
    
    /* deviceのGUIDからハッシュ値を計算します。 */
    UInt8 guid[16];
    size_t guid_sz;
    
    UIDevice *dev = [UIDevice currentDevice];
    NSUUID *vendorUUID = [dev identifierForVendor];
    
    [vendorUUID getUUIDBytes:guid];
    guid_sz = sizeof(guid);
    
    /* OpenSSL用にEVPコンテキストを宣言して初期化*/
    EVP_MD_CTX evp_ctx;
    EVP_MD_CTX_init(&evp_ctx);
    
    /* ハッシュ値の計算結果用のバッファ*/
    UInt8 digest[20];
    /* SHA-1ダイジェストを計算するためのEVPコンテキストを設定*/
    EVP_DigestInit_ex(&evp_ctx, EVP_sha1(), NULL);
    /* ハッシュ値を計算する各部分を連結。この順序で連結する必要があります。*/
    EVP_DigestUpdate(&evp_ctx, guid, guid_sz);
    EVP_DigestUpdate(&evp_ctx, opaque->buf, opaque->size);
    EVP_DigestUpdate(&evp_ctx, bundle_id->buf, bundle_id->size);
    /* ハッシュ値を計算して、結果をダイジェスト変数に保存 */
    EVP_DigestFinal_ex(&evp_ctx, digest, NULL);
    
    NSData *receipe_hash = [[NSData alloc] initWithBytes:hash->buf
                                                  length:hash->size];
    
    NSData *calc_uuid_hash = [[NSData alloc] initWithBytes:digest
                                                  length:20];
    
    if ( [receipe_hash isEqualToData:calc_uuid_hash] ) {
        curentStage = kGUIDHashTrue;
        return YES;
    }
    else {
        return NO;
    }
    
}



#pragma mark --
#pragma mark private method
-(Payload_t *)payload {
    if (curentStage != kSignatureAppleTrue) {
        return NULL;
    }
    
    if (!receiptBinary) {
        return NULL;
    }
    
    if (!p7) {
        return NULL;
    }
    
    /* レシートのペイロードとそのサイズ*/
    void *pld = NULL;
    size_t pld_sz;
    
    ASN1_OCTET_STRING *octets = p7->d.sign->contents->d.data;
    pld = octets->data;
    pld_sz = octets->length;
    
    /* ペイロードの解析で使用される変数。データ型はどちらもPayload.hで宣言されています。*/
    Payload_t *payload = NULL;
    asn_dec_rval_t rval;
    
    rval = asn_DEF_Payload.ber_decoder(NULL, &asn_DEF_Payload, (void **)&payload, pld, pld_sz, 0);
    
    return payload;
}

NSData *appleRootCert(void) {
    // Obtain the Apple Inc. root certificate from http://www.apple.com/certificateauthority/
    // Download the Apple Inc. Root Certificate ( http://www.apple.com/appleca/AppleIncRootCertificate.cer )
    // Add the receipt to your app's resource bundle.
    NSData *cert = [NSData dataWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"AppleIncRootCertificate" withExtension:@"cer"]];
    return cert;
}


@end
