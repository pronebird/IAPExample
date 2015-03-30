//
//  ViewController.m
//  IAPExample
//
//  Created by pronebird on 3/11/15.
//  Copyright (c) 2015 pronebird. All rights reserved.
//

#import "ViewController.h"
#import <StoreKit/StoreKit.h>
#import "AlertControllerWithActivityIndicator.h"
#import "SKRequest+Blocks.h"

@interface ViewController () <SKProductsRequestDelegate, SKPaymentTransactionObserver>

@property NSMutableArray *restorePurchasesBlocks;
@property NSMutableDictionary *purchaseHandlersByProductIdentifier;
@property UIAlertController *alertController;

@end

@implementation ViewController

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    
    self.restorePurchasesBlocks = [NSMutableArray new];
    self.purchaseHandlersByProductIdentifier = [NSMutableDictionary new];
}

- (void)showAlertWithTitle:(NSString *)title {
    self.alertController = [AlertControllerWithActivityIndicator alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [self presentViewController:self.alertController animated:YES completion:nil];
}

- (void)hideAlert {
    [self.alertController dismissViewControllerAnimated:YES completion:nil];
    self.alertController = nil;
}

- (void)showAlertWithTitle:(NSString *)title error:(NSError *)error {
    if(self.alertController) {
        [self.alertController dismissViewControllerAnimated:YES completion:nil];
    }
    
    self.alertController = [UIAlertController alertControllerWithTitle:title message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    
    [self.alertController addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        
    }]];
    
    [self presentViewController:self.alertController animated:YES completion:nil];
}

#pragma mark - Actions

- (IBAction)buy:(id)sender {
    [self showAlertWithTitle:@"Please wait..."];

    [self buyProduct:@"500coins" completion:^(BOOL succeeded, NSError *error) {
        NSLog(@"Purchase completed. Succeeded = %d, error = %@", succeeded, error);
        
        [self hideAlert];
        
        if(!succeeded && error.code != SKErrorPaymentCancelled) {
            [self showAlertWithTitle:@"AppStore" error:error];
        }
    }];
}

- (IBAction)restore:(id)sender {
    [self showAlertWithTitle:@"Please wait..."];
    
    [self restorePurchases:^(BOOL succeeded, NSError *error) {
        NSLog(@"Restored purchases. Succeeded = %d, error = %@", succeeded, error);
        
        [self hideAlert];
        
        if(!succeeded && error) {
            [self showAlertWithTitle:@"AppStore" error:error];
        }
    }];
}

#pragma mark - IAP

- (void)addPurchaseHandler:(void(^)(BOOL succeeded, NSError *error))handler forProduct:(NSString *)identifier {
    NSMutableArray *handlers = [self.purchaseHandlersByProductIdentifier objectForKey:identifier];
    
    if(!handlers) {
        handlers = [NSMutableArray new];
        [self.purchaseHandlersByProductIdentifier setObject:handlers forKey:identifier];
    }
    
    [handlers addObject:[handler copy]];
}

- (void)callPurchaseHandlersForProduct:(NSString *)identifier succeeded:(BOOL)succeeded error:(NSError *)error {
    NSMutableArray *handlers = [self.purchaseHandlersByProductIdentifier objectForKey:identifier];
    
    if(handlers) {
        for(void(^handler)(BOOL succeeded, NSError *error) in handlers) {
            handler(succeeded, error);
        }
        
        [self.purchaseHandlersByProductIdentifier removeObjectForKey:identifier];
    }
}

- (void)addRestorePurchasesHandler:(void(^)(BOOL succeeded, NSError *error))handler {
    [self.restorePurchasesBlocks addObject:[handler copy]];
}

- (void)callRestorePurchasesHandlers:(BOOL)succeeded error:(NSError *)error {
    for(void(^handler)(BOOL succeeded, NSError *error) in self.restorePurchasesBlocks) {
        handler(succeeded, error);
    }
    
    [self.restorePurchasesBlocks removeAllObjects];
}

- (void)buyProduct:(NSString*)productIdentifier completion:(void(^)(BOOL succeeded, NSError *error))completion {
    NSSet* products = [NSSet setWithObject:productIdentifier];
    
    [self requestProductsWithIdentifiers:products completion:^(SKProductsResponse *response, NSError* error) {
        if(error) {
            NSLog(@"Failed to request products: %@", error);
            return;
        }
        
        SKProduct* product = response.products.firstObject;
        SKPayment *payment = [SKPayment paymentWithProduct:product];
        
        [self addPurchaseHandler:completion forProduct:productIdentifier];
        
        [[SKPaymentQueue defaultQueue] addPayment:payment];
    }];
}

- (void)restorePurchases:(void(^)(BOOL succeeded, NSError *error))completion {
    [self addRestorePurchasesHandler:completion];
    
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)requestProductsWithIdentifiers:(NSSet*)products completion:(void(^)(SKProductsResponse* response, NSError* error))completion {
    SKProductsRequest* request = [[SKProductsRequest alloc] initWithProductIdentifiers:products];
    request.completionBlock = completion;
    request.delegate = self;
    
    [request start];
}

#pragma mark - SKProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response {
    for(SKProduct* product in response.products) {
        NSNumberFormatter* formatter = [NSNumberFormatter new];
        formatter.numberStyle = NSNumberFormatterCurrencyStyle;
        formatter.locale = product.priceLocale;
        
        NSLog(@"product = %@", product.localizedTitle);
        NSLog(@"description = %@", product.localizedDescription);
        NSLog(@"price = %@", [formatter stringFromNumber:product.price]);
    }
    
    NSLog(@"Invalid IAPs: %@", response.invalidProductIdentifiers);
    
    if(request.completionBlock) {
        request.completionBlock(response, nil);
    }
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error {
    NSLog(@"Failed to fetch products: %@", error);
    
    if(request.completionBlock) {
        request.completionBlock(nil, error);
    }
}

#pragma mark - SKPaymentTransactionObserver

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
    for(SKPaymentTransaction *transaction in transactions) {
        switch (transaction.transactionState) {
            case SKPaymentTransactionStatePurchased:
                [self completeTransaction:transaction];
                break;
            case SKPaymentTransactionStateFailed:
                [self failedTransaction:transaction];
                break;
            case SKPaymentTransactionStateRestored:
                [self restoreTransaction:transaction];
            default:
                break;
        }
    }
}

- (void)completeTransaction:(SKPaymentTransaction *)transaction {
    NSLog(@"Complete transaction = %@", transaction.payment.productIdentifier);
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [self callPurchaseHandlersForProduct:transaction.payment.productIdentifier succeeded:YES error:nil];
}

- (void)restoreTransaction:(SKPaymentTransaction *)transaction {
    SKPayment *payment = transaction.originalTransaction ? transaction.originalTransaction.payment : transaction.payment;
    
    NSLog(@"Restore transaction = %@", payment.productIdentifier);
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}

- (void)failedTransaction:(SKPaymentTransaction *)transaction {
    if(transaction.error.code == SKErrorPaymentCancelled) {
        NSLog(@"Transaction has been cancelled.");
    }
    
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    
    [self callPurchaseHandlersForProduct:transaction.payment.productIdentifier succeeded:NO error:transaction.error];
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error {
    NSLog(@"Transactions restoration failed: %@", error);
    
    [self callRestorePurchasesHandlers:NO error:error];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue {
    NSLog(@"Transactions have been restored.");
    
    [self callRestorePurchasesHandlers:YES error:nil];
}

@end
