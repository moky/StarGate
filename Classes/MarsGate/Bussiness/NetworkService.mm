// Tencent is pleased to support the open source community by making Mars available.
// Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.

// Licensed under the MIT License (the "License"); you may not use this file except in 
// compliance with the License. You may obtain a copy of the License at
// http://opensource.org/licenses/MIT

// Unless required by applicable law or agreed to in writing, software distributed under the License is
// distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions and
// limitations under the License.

//
//  NetworkService.mm
//  iOSDemo
//
//  Created by caoshaokun on 16/11/23.
//  Copyright © 2016年 caoshaokun. All rights reserved.
//

#include "NetworkService.h"

#import <SystemConfiguration/SCNetworkReachability.h>

#import "NetworkDelegate.h"
#import "CGITask.h"

#import "app_callback.h"
#import "stn_callback.h"

#import <mars/app/app_logic.h>
#import <mars/baseevent/base_logic.h>
#import <mars/xlog/xlogger.h>
#import <mars/xlog/xloggerbase.h>
#import <mars/xlog/appender.h>

#import "stnproto_logic.h"

using namespace mars::stn;

@interface NetworkService ()

@end

@implementation NetworkService

+ (NetworkService*)sharedInstance {
    static NetworkService *_sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _sharedInstance = [[self alloc] init];
    });
    
    return _sharedInstance;
}

- (void)dealloc {
    NSLog(@"Dealloc");
}

- (void)setCallBack {
    mars::stn::SetCallback(mars::stn::StnCallBack::Instance());
    mars::app::SetCallback(mars::app::AppCallBack::Instance());
}

- (void) createMars {
    mars::baseevent::OnCreate();
}

- (void)setClientVersion:(UInt32)clientVersion {
    mars::stn::SetClientVersion(clientVersion);
}

- (void)setShortLinkDebugIP:(NSString *)IP port:(const unsigned short)port {
    std::string ipAddress([IP UTF8String]);
    mars::stn::SetShortlinkSvrAddr(port, ipAddress);
}

- (void)setShortLinkPort:(const unsigned short)port {
    mars::stn::SetShortlinkSvrAddr(port, "");
}

- (void)setLongLinkAddress:(NSString *)string port:(const unsigned short)port debugIP:(NSString *)IP {
    std::string ipAddress([string UTF8String]);
    std::string debugIP([IP UTF8String]);
    std::vector<uint16_t> ports;
    ports.push_back(port);
    mars::stn::SetLonglinkSvrAddr(ipAddress,ports,debugIP);
}

- (void)setLongLinkAddress:(NSString *)string port:(const unsigned short)port {
    std::string ipAddress([string UTF8String]);
    std::vector<uint16_t> ports;
    ports.push_back(port);
    mars::stn::SetLonglinkSvrAddr(ipAddress, ports, "");
}

- (void)makesureLongLinkConnect {
    mars::stn::MakesureLonglinkConnected();
}

- (void)destroyMars {
    mars::baseevent::OnDestroy();
}

- (void)addPushObserver:(id<PushNotifyDelegate>)observer withCmdId:(NSInteger)cmdId {
    [_delegate addPushObserver:observer withCmdId:cmdId];
}

- (int)startTask:(CGITask *)task ForUI:(id<UINotifyDelegate>)delegateUI {
    Task ctask = Task();
    ctask.cmdid = task.cmdid;
    ctask.channel_select = task.channel_select;
    ctask.cgi = std::string(task.cgi.UTF8String);
    ctask.shortlink_host_list.push_back(std::string(task.host.UTF8String));
    ctask.user_context = (__bridge void*)task;
    
    NSString *taskIdKey = [NSString stringWithFormat:@"%d", ctask.taskid];
    [_delegate addObserver:delegateUI forKey:taskIdKey];
    [_delegate addCGITasks:task forKey:taskIdKey];
    
    mars::stn::StartTask(ctask);
    
    return ctask.taskid;
}

- (void)stopTask:(NSInteger)taskID {
    mars::stn::StopTask((uint32_t)taskID);
}



// event reporting
- (void)reportEvent_OnForeground:(BOOL)isForeground {
    mars::baseevent::OnForeground(isForeground);
}

- (void)reportEvent_OnNetworkChange {
    mars::baseevent::OnNetworkChange();
}

// callbacks
- (BOOL)isAuthed {
    return [_delegate isAuthed];
}

- (NSArray *)OnNewDns:(NSString *)address {
    return [_delegate OnNewDns:address];
}

- (void)OnPushWithCmd:(NSInteger)cid data:(NSData *)data {
    return [_delegate OnPushWithCmd:cid data:data];
}

- (NSData*)Request2BufferWithTaskID:(uint32_t)tid userContext:(const void *)context {
    CGITask *task = (__bridge CGITask *)context;
    return [_delegate Request2BufferWithTaskID:tid task:task];
}

- (NSInteger)Buffer2ResponseWithTaskID:(uint32_t)tid ResponseData:(NSData *)data userContext:(const void *)context {
    CGITask *task = (__bridge CGITask *)context;
    return [_delegate Buffer2ResponseWithTaskID:tid responseData:data task:task];
}

- (NSInteger)OnTaskEndWithTaskID:(uint32_t)tid userContext:(const void *)context errType:(uint32_t)errtype errCode:(uint32_t)errcode; {
    CGITask *task = (__bridge CGITask *)context;
    return [_delegate OnTaskEndWithTaskID:tid task:task errType:errtype errCode:errcode];
}

- (void)OnConnectionStatusChange:(int32_t)status longConnStatus:(int32_t)longConnStatus {
    [_delegate OnConnectionStatusChange:status longConnStatus:longConnStatus];
}

#pragma mark NetworkStatusDelegate
-(void) ReachabilityChange:(UInt32)uiFlags {
    
    if ((uiFlags & kSCNetworkReachabilityFlagsConnectionRequired) == 0) {
        mars::baseevent::OnNetworkChange();
    }
    
}

@end

