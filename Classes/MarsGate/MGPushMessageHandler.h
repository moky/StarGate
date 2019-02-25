//
//  MGPushMessageHandler.h
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "StarGate.h"

#import "PushNotifyDelegate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MGPushMessageHandler : NSObject <PushNotifyDelegate>

@property (weak, nonatomic) id<SGStar> star;

- (instancetype)initWithHandler:(id<SGStarDelegate>)receiver
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
