//
//  LCRTC.h
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/11.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import <Foundation/Foundation.h>
@class RTCPeerConnectionFactory;
@class RTCPeerConnection;
@class LCRTC;

@protocol LCRTCDelegate <NSObject>

- (void)rtc:(LCRTC *)rtc didReceiveLocalVideoTrack:(id)track;//RTCVideoTrack *
- (void)rtc:(LCRTC *)rtc didReceiveRemoteVideoTrack:(id)track;

@end

@interface LCRTC : NSObject

@property (nonatomic, strong) RTCPeerConnectionFactory *peerConnectionFactory;
@property (nonatomic, strong) RTCPeerConnection *peerConnection;
@property (nonatomic, strong) NSMutableArray *queuedRemoteCandidates;
@property (nonatomic, assign) BOOL isCaller;
@property (nonatomic, copy) NSString *remoteUsername;
@property (nonatomic, weak) id<LCRTCDelegate> delegate;

//+(LCRTC *)sharedInstance;

- (void)createPeerConnection;
- (void)createOffer;
- (void)stopPeerConnection;

- (void)handleExchangeInfo:(NSDictionary *)msg;

@end
