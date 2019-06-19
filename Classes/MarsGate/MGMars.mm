//
//  MGMars.m
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <mars/xlog/appender.h>
#import <mars/stn/stn.h>

#import "CommandID.h"
#import "CGITask.h"
#import "NetworkEvent.h"
#import "NetworkService.h"

#import "MGMessenger.h"
#import "MGPushMessageHandler.h"

#import "MGMars.h"

@interface MGMars () {
    
    SGStarStatus _longConnectionStatus;
    SGStarStatus _connectionStatus;
}

@property (strong, nonatomic) id<SGStarDelegate> handler;
@property (strong, nonatomic) MGPushMessageHandler *pushHandler;

@end

@implementation MGMars

- (instancetype)init {
    id handler = nil;
    return [self initWithMessageHandler:handler];
}

/* designated initializer */
- (instancetype)initWithMessageHandler:(id<SGStarDelegate>)handler {
    if (self = [super init]) {
        _longConnectionStatus = SGStarStatus_Init;
        _connectionStatus = SGStarStatus_Init;
        
        self.handler = handler;
        
        MGPushMessageHandler *pmHandler;
        pmHandler = [[MGPushMessageHandler alloc] initWithHandler:handler];
        pmHandler.star = self;
        self.pushHandler = pmHandler;
    }
    return self;
}

- (SGStarStatus)status {
    switch (_longConnectionStatus) {
        case SGStarStatus_Init:
            break;
            
        case SGStarStatus_Connecting:
            return _longConnectionStatus;
            
        case SGStarStatus_Connected:
            return _longConnectionStatus;
            
        case SGStarStatus_Error:
            break;
            
        default:
            break;
    }
    return _connectionStatus;
}

- (void)onConnectionStatusChanged:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    
    int longlink_status = mars::stn::kNetworkUnkown;
    int conn_status = mars::stn::kNetworkUnkown;
    
    NSNumber *status;
    status = [info objectForKey:@"LongConnectionStatus"];
    if (status != nil) {
        longlink_status = [status intValue];
    }
    status = [info objectForKey:@"ConnectionStatus"];
    if (status != nil) {
        conn_status = [status intValue];
    }
    
    switch (longlink_status) {
        case mars::stn::kNetworkUnavailable:
        case mars::stn::kServerFailed:
        case mars::stn::kServerDown:
        case mars::stn::kGateWayFailed:
            _longConnectionStatus = SGStarStatus_Error;
            NSLog(@"Mars: long connection error");
            break;
        case mars::stn::kConnecting:
            _longConnectionStatus = SGStarStatus_Connecting;
            NSLog(@"Mars: long connection connecting");
            break;
        case mars::stn::kConnected:
            _longConnectionStatus = SGStarStatus_Connected;
            NSLog(@"Mars: long connection connected");
            break;
        case mars::stn::kNetworkUnkown:
            _longConnectionStatus = SGStarStatus_Error;
            NSLog(@"Mars: long connection unknown");
            break;
        default:
            NSLog(@"Mars: long link status changed to %d", longlink_status);
            break;
    }
    
    switch (conn_status) {
        case mars::stn::kNetworkUnavailable:
        case mars::stn::kServerFailed:
        case mars::stn::kServerDown:
        case mars::stn::kGateWayFailed:
            _connectionStatus = SGStarStatus_Error;
            NSLog(@"Mars: connection error");
            break;
        case mars::stn::kConnecting:
            _connectionStatus = SGStarStatus_Connecting;
            NSLog(@"Mars: connection connecting");
            break;
        case mars::stn::kConnected:
            _connectionStatus = SGStarStatus_Connected;
            NSLog(@"Mars: connection connected");
            break;
        case mars::stn::kNetworkUnkown:
            _connectionStatus = SGStarStatus_Error;
            NSLog(@"Mars: connection unknown");
            break;
        default:
            NSLog(@"Mars: connection status changed to %d", conn_status);
            break;
    }
    
    if ([_handler respondsToSelector:@selector(star:onConnectionStatusChanged:)]) {
        [_handler star:self onConnectionStatusChanged:self.status];
    }
}

#pragma mark - SGStar

- (BOOL)launchWithOptions:(nullable NSDictionary *)launchOptions {
    
    UInt32 clientVersion = 200;
    NSString *longLinkAddress = @"dim.chat";
    unsigned short longLinkPort = 9394;
    unsigned short shortLinkPort = 8080;
    
    NSString *address;
    NSNumber *port;
    // LongLink
    address = [launchOptions objectForKey:@"LongLinkAddress"];
    if (address) {
        longLinkAddress = address;
    }
    port = [launchOptions objectForKey:@"LongLinkPort"];
    if (port != nil) {
        longLinkPort = [port unsignedShortValue];
    }
    // ShortLink
    port = [launchOptions objectForKey:@"ShortLinkPort"];
    if (port != nil) {
        shortLinkPort = [port unsignedShortValue];
    }
    
    // OnNewDNS:
    NSDictionary *ipTable = [launchOptions objectForKey:@"NewDNS"];
    if (!ipTable) {
        ipTable = @{
                    @"dim.chat": @[
                            @"127.0.0.1",
                            ],
                    };
    }
    
    NetworkEvent *networkEvent = [[NetworkEvent alloc] init];
    for (NSString *domain in ipTable) {
        [networkEvent setIPList:[ipTable objectForKey:domain] forHost:domain];
    }
    
    [NetworkService sharedInstance].delegate = networkEvent;
    [[NetworkService sharedInstance] setCallBack];
    [[NetworkService sharedInstance] createMars];
    [[NetworkService sharedInstance] setClientVersion:clientVersion];
    [[NetworkService sharedInstance] setLongLinkAddress:longLinkAddress port:longLinkPort];
    [[NetworkService sharedInstance] setShortLinkPort:shortLinkPort];
    [[NetworkService sharedInstance] reportEvent_OnForeground:YES];
    [[NetworkService sharedInstance] makesureLongLinkConnect];
    
    [[NetworkStatus sharedInstance] Start:[NetworkService sharedInstance]];
    
    [[NetworkService sharedInstance] addPushObserver:_pushHandler withCmdId:kSendMsgCmdId];
    [[NetworkService sharedInstance] addPushObserver:_pushHandler withCmdId:kPushMessageCmdId];
    
    // listening ConnectionStatusChanged from networkEvent
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc addObserver:self
           selector:@selector(onConnectionStatusChanged:)
               name:kNotificationName_ConnectionStatusChanged
             object:networkEvent];
    
    return YES;
}

- (void)enterBackground {
    [[NetworkService sharedInstance] reportEvent_OnForeground:NO];
}

- (void)enterForeground {
    [[NetworkService sharedInstance] reportEvent_OnForeground:YES];
}

- (void)terminate {
    // remove listening ConnectionStatusChanged from networkEvent
    NetworkEvent *networkEvent = [NetworkService sharedInstance].delegate;
    NSNotificationCenter *dc = [NSNotificationCenter defaultCenter];
    [dc removeObserver:self
                  name:kNotificationName_ConnectionStatusChanged
                object:networkEvent];
    
    [[NetworkService sharedInstance] destroyMars];
    appender_close();
}

#pragma mark -

- (NSInteger)send:(NSData *)requestData {
    return [self send:requestData handler:_handler];
}

- (NSInteger)send:(NSData *)requestData handler:(nullable id<SGStarDelegate>)sender {
    
    MGMessenger *messenger = [[MGMessenger alloc] initWithData:requestData handler:sender];
    messenger.star = self;
    
    CGITask *task;
    task = [[CGITask alloc] initAll:ChannelType_LongConn
                           AndCmdId:kSendMsgCmdId
                          AndCGIUri:@"/sendmessage"
                            AndHost:@"dim.chat"];
    [[NetworkService sharedInstance] startTask:task ForUI:messenger];
    return 0;
}

@end
