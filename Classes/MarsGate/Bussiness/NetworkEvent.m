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
//  NetworkEvent.m
//  iOSDemo
//
//  Created by caoshaokun on 16/11/24.
//  Copyright © 2016年 caoshaokun. All rights reserved.
//

#import "NetworkEvent.h"

#import "CGITask.h"
#import "LogUtil.h"

@interface NetworkEvent ()

@property (strong, nonatomic) NSMutableDictionary *ipTable;

@end

@implementation NetworkEvent

- (void)addPushObserver:(id<PushNotifyDelegate>)observer withCmdId:(NSInteger)cmdId {
    LOG_INFO(kNetwork, @"add pushObserver for cmdId:%ld", (long)cmdId);
    [pushrecvers setObject:observer forKey:[NSString stringWithFormat:@"%ld", (long)cmdId]];
}

- (void)addObserver:(id<UINotifyDelegate>)observer forKey:(NSString *)key {
    [controllers setObject:observer forKey:key];
}

- (void)addCGITasks:(CGITask*)cgiTask forKey:(NSString *)key {
    [tasks setObject:cgiTask forKey:key];
}

- (id)init {
    
    if(self = [super init]) {
        tasks = [[NSMutableDictionary alloc] init];
        controllers = [[NSMutableDictionary alloc] init];
        pushrecvers = [[NSMutableDictionary alloc] init];
        
        _ipTable = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (void)setIPList:(NSArray *)list forHost:(NSString *)domain {
    if (list.count > 0) {
        [_ipTable setObject:[list mutableCopy] forKey:domain];
    } else {
        [_ipTable removeObjectForKey:domain];
    }
}

- (void)addIPAddress:(NSString *)IP forHost:(NSString *)domain {
    NSMutableArray *list = [_ipTable objectForKey:domain];
    if (list) {
        if ([list containsObject:IP]) {
            NSLog(@"already contains this IP: %@", IP);
        } else {
            [list addObject:IP];
        }
    } else {
        list = [[NSMutableArray alloc] initWithObjects:IP, nil];
        [_ipTable setObject:list forKey:domain];
    }
}

#pragma mark - NetworkDelegate

- (BOOL)isAuthed {
    
    return true;
}

- (NSArray *)OnNewDns:(NSString *)address {
    return [_ipTable objectForKey:address];
}

- (void)OnPushWithCmd:(NSInteger)cid data:(NSData *)data {
    id<PushNotifyDelegate> pushObserver = [pushrecvers objectForKey:[NSString stringWithFormat:@"%ld", cid]];
    if (pushObserver != nil) {
        [pushObserver notifyPushMessage:data withCmdId:cid];
    }
}

- (NSData*)Request2BufferWithTaskID:(uint32_t)tid task:(CGITask *)task {
    NSData* data = NULL;
    
    NSString *taskIdKey = [NSString stringWithFormat:@"%d", tid];
    
    id<UINotifyDelegate> uiObserver = [controllers objectForKey:taskIdKey];
    if (uiObserver != nil) {
        data = [uiObserver requestSendData];
    }
    
    return data;
}

- (NSInteger)Buffer2ResponseWithTaskID:(uint32_t)tid responseData:(NSData *)data task:(CGITask *)task {
    int returnType = 0;
    
    NSString *taskIdKey = [NSString stringWithFormat:@"%d", tid];
    
    id<UINotifyDelegate> uiObserver = [controllers objectForKey:taskIdKey];
    if (uiObserver != nil) {
        returnType = [uiObserver onPostDecode:data];
    }
    else {
        returnType = -1;
    }
    
    return returnType;
}

- (NSInteger)OnTaskEndWithTaskID:(uint32_t)tid task:(CGITask *)task errType:(uint32_t)errtype errCode:(uint32_t)errcode {
    
    NSString *taskIdKey = [NSString stringWithFormat:@"%d", tid];
    
    [tasks removeObjectForKey:taskIdKey];
    id<UINotifyDelegate> uiObserver = [controllers objectForKey:taskIdKey];
    [uiObserver onTaskEnd:tid errType:errtype errCode:errcode];
    
    [controllers removeObjectForKey:taskIdKey];
    
    return 0;
}

- (void)OnConnectionStatusChange:(int32_t)status longConnStatus:(int32_t)longConnStatus {
    NSLog(@"OnConnectionStatusChange: %d, %d", status, longConnStatus);
}


@end
