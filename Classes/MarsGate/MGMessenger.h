//
//  MGMessenger.h
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "StarGate.h"

#import "UINotifyDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MGMessenger : NSObject <UINotifyDelegate>

@property (weak, nonatomic) id<SGStar> star;

- (instancetype)initWithData:(const NSData *)data
                     handler:(nullable id<SGStarDelegate>)sender
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
