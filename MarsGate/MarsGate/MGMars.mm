//
//  MGMars.m
//  MarsGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <mars/xlog/appender.h>

#import "CommandID.h"
#import "CGITask.h"
#import "NetworkEvent.h"
#import "NetworkService.h"

#import "MGMessenger.h"
#import "MGPushMessageHandler.h"

#import "MGMars.h"

@interface MGMars ()

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
        self.handler = handler;
        
        self.pushHandler = [[MGPushMessageHandler alloc] initWithHandler:handler];
    }
    return self;
}

#pragma mark - SGStar

- (nullable NSString *)IP {
    // TODO: get current connected server IP
    return @"127.0.0.1";
}

- (NSUInteger)port {
    // TODO: get current connected server port
    return 9394;
}

- (BOOL)isConnected {
    // TODO: get status of current connection
    return YES;
}

- (NSInteger)send:(const NSData *)requestData {
    return [self send:requestData handler:_handler];
}

- (NSInteger)send:(const NSData *)requestData handler:(id<SGStarDelegate>)sender {
    
    if (!sender) {
        sender = _handler;
    }
    MGMessenger *messenger = [[MGMessenger alloc] initWithData:requestData handler:sender];
    
    CGITask *task;
    task = [[CGITask alloc] initAll:ChannelType_LongConn
                           AndCmdId:kSendMsgCmdId
                          AndCGIUri:@"/sendmessage"
                            AndHost:@"dim.chat"];
    [[NetworkService sharedInstance] startTask:task ForUI:messenger];
    return 0;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    
    [NetworkService sharedInstance].delegate = [[NetworkEvent alloc] init];
    [[NetworkService sharedInstance] setCallBack];
    [[NetworkService sharedInstance] createMars];
    [[NetworkService sharedInstance] setClientVersion:200];
    [[NetworkService sharedInstance] setLongLinkAddress:@"dim.chat" port:9394];
    [[NetworkService sharedInstance] setShortLinkPort:8080];
    [[NetworkService sharedInstance] reportEvent_OnForeground:YES];
    [[NetworkService sharedInstance] makesureLongLinkConnect];
    
    [[NetworkStatus sharedInstance] Start:[NetworkService sharedInstance]];
    
    [[NetworkService sharedInstance] addPushObserver:_pushHandler withCmdId:kSendMsgCmdId];
    [[NetworkService sharedInstance] addPushObserver:_pushHandler withCmdId:kPushMessageCmdId];
    
    return YES;
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    [[NetworkService sharedInstance] reportEvent_OnForeground:NO];
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    [[NetworkService sharedInstance] reportEvent_OnForeground:YES];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    
    [[NetworkService sharedInstance] destroyMars];
    
    appender_close();
}

@end
