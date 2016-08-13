//
//  LCCore.h
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/11.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LCCoreDelegate <NSObject>

- (void)didReceiveLocalVideoTrack:(id)track;//RTCVideoTrack *
- (void)didReceiveRemoteVideoTrack:(id)track;

@end

@interface LCCore : NSObject

@property (nonatomic, assign) BOOL isCaller;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *remoteUsername;
@property (nonatomic, copy) NSString *roomId;

@property (nonatomic, weak) id<LCCoreDelegate> delegate;

+ (LCCore *)sharedInstance;
- (void)exchange:(NSDictionary *)info;
@end
