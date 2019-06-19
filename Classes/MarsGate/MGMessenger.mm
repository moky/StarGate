//
//  MGMessenger.m
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <mars/stn/stn.h>

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
- (instancetype)initWithData:(NSData *)data
                     handler:(nullable id<SGStarDelegate>)sender {
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
    return (int)[_handler star:_star onReceive:responseData]; // -1 on error
}

- (int)onTaskEnd:(uint32_t)tid errType:(uint32_t)errtype errCode:(uint32_t)errcode {
    NSLog(@"task end: %d, error type: %d, code: %d", tid, errtype, errcode);
    NSError *error;
    if (errtype == mars::stn::kEctOK) {
        // success
        error = nil;
    } else {
        // failed
        NSErrorDomain domain = NSNetServicesErrorDomain;
        NSMutableDictionary<NSErrorUserInfoKey, id> *info = nil;
        
        switch (errtype) {
            case mars::stn::kEctFalse:
                domain = NSOSStatusErrorDomain;
                break;
                
            case mars::stn::kEctDial:
                domain = NSOSStatusErrorDomain;
                break;
                
            case mars::stn::kEctDns:
                domain = NSURLErrorDomain;
                break;
                
            case mars::stn::kEctSocket:
                domain = NSStreamSOCKSErrorDomain;
                break;
                
            case mars::stn::kEctHttp:
                domain = NSURLErrorDomain;
                break;
                
            case mars::stn::kEctNetMsgXP:
                domain = NSItemProviderErrorDomain;
                break;
                
            case mars::stn::kEctEnDecode:
                domain = NSPOSIXErrorDomain;
                break;
                
            case mars::stn::kEctServer:
                domain = NSNetServicesErrorDomain;
                break;
                
            case mars::stn::kEctLocal:
                domain = NSCocoaErrorDomain;
                break;
                
            case mars::stn::kEctCanceld:
                domain = NSOSStatusErrorDomain;
                break;
                
            default:
                //NSMachErrorDomain
                //NSStreamSocketSSLErrorDomain
                //NSXMLParserErrorDomain
                break;
        }
        error = [[NSError alloc] initWithDomain:domain code:errcode userInfo:info];
    }
    
    if ([_handler respondsToSelector:@selector(star:onFinishSend:withError:)]) {
        [_handler star:_star onFinishSend:_data withError:error];
    }
    return 0;
}

@end
