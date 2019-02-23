//
//  MGMessenger.m
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import "MGMessenger.h"

@interface MGMessenger ()

@property (strong, nonatomic) NSData *data;
@property (strong, nonatomic) id<SGStarDelegate> handler;

@end

@implementation MGMessenger

- (instancetype)init {
    NSData *data = nil;
    id handler = nil;
    return [self initWithData:data handler:handler];
}

/* designated initializer */
- (instancetype)initWithData:(const NSData *)data
                     handler:(id<SGStarDelegate>)sender {
    if (self = [super init]) {
        _data = [data copy];
        _handler = sender;
    }
    return self;
}

#pragma mark - UINotifyDelegate

- (NSData*)requestSendData {
    return _data;
}

- (int)onPostDecode:(NSData*)responseData {
    return (int)[_handler onReceive:responseData]; // -1 on error
}

- (int)onTaskEnd:(uint32_t)tid errType:(uint32_t)errtype errCode:(uint32_t)errcode {
    NSLog(@"task end: %d, error type: %d, code: %d", tid, errtype, errcode);
    // TODO:
    
    return 0;
}

@end
