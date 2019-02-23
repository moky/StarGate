//
//  StarGate.h
//  StarGate
//
//  Created by Albert Moky on 2019/2/21.
//  Copyright © 2019 DIM Group. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SGStarDelegate <NSObject>

/**
 
 @return 0 on success, -1 on error
 */
- (NSInteger)onReceive:(const NSData *)responseData;

@end

@protocol SGStar <NSObject>

@property (readonly, nonatomic, nullable) NSString *IP; // server IP
@property (readonly, nonatomic) NSUInteger port;        // server port
@property (readonly, nonatomic, getter=isConnected) BOOL connected;

- (BOOL)launchWithOptions:(nullable NSDictionary *)launchOptions;
- (void)terminate;

- (void)enterBackground;
- (void)enterForeground;

/**
 
 @return 0 on success, -1 on error
 */
- (NSInteger)send:(const NSData *)requestData;
- (NSInteger)send:(const NSData *)requestData handler:(id<SGStarDelegate>)sender;

@end

NS_ASSUME_NONNULL_END
