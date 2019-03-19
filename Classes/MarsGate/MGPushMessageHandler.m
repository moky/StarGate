//
//  MGPushMessageHandler.m
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "MGPushMessageHandler.h"

@interface MGPushMessageHandler ()

@property (strong, nonatomic) id<SGStarDelegate> handler;

@end

@implementation MGPushMessageHandler

- (instancetype)init {
    id handler = nil;
    return [self initWithHandler:handler];
}

/* designated initializer */
- (instancetype)initWithHandler:(id<SGStarDelegate>)receiver {
    if (self = [super init]) {
        _handler = receiver;
    }
    return self;
}

#pragma mark - PushNotifyDelegate

- (void)notifyPushMessage:(NSData *)pushData withCmdId:(NSInteger)cmdId {
    NSLog(@"pushData len: %lu, cmd: %ld", pushData.length, cmdId);
    // TODO: receive push message
    NSInteger res = [_handler star:_star onReceive:pushData];
    NSLog(@"process result: %ld", res);
}

@end
