//
//  MGMars.h
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "StarGate.h"

NS_ASSUME_NONNULL_BEGIN

@interface MGMars : NSObject <SGStar>

- (instancetype)initWithMessageHandler:(id<SGStarDelegate>)handler
NS_DESIGNATED_INITIALIZER;

@end

NS_ASSUME_NONNULL_END
