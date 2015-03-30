//
//  SKRequest+Blocks.m
//  IAPExample
//
//  Created by pronebird on 3/30/15.
//  Copyright (c) 2015 pronebird. All rights reserved.
//

#import "SKRequest+Blocks.h"
#import <objc/runtime.h>

static const void* kSKRequstCompletionBlockKey = &kSKRequstCompletionBlockKey;

@implementation SKRequest (Blocks)

- (void)setCompletionBlock:(void (^)(SKProductsResponse* product, NSError* error))completionBlock {
    objc_setAssociatedObject(self, kSKRequstCompletionBlockKey, completionBlock, OBJC_ASSOCIATION_COPY);
}

- (void (^)(SKProductsResponse* product, NSError* error))completionBlock {
    return objc_getAssociatedObject(self, kSKRequstCompletionBlockKey);
}

@end
