//
//  SKRequest+Blocks.h
//  IAPExample
//
//  Created by pronebird on 3/30/15.
//  Copyright (c) 2015 pronebird. All rights reserved.
//

#import <StoreKit/StoreKit.h>

@interface SKRequest (Blocks)

@property (nonatomic, copy) void(^completionBlock)(SKProductsResponse* response, NSError* error);

@end
