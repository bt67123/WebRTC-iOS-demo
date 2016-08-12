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

@interface LCRTC : NSObject

@property (nonatomic, strong) RTCPeerConnectionFactory *peerConnectionFactory;
@property (nonatomic, strong) RTCPeerConnection *peerConnection;
@property (nonatomic, strong) NSMutableArray *queuedRemoteCandidates;

+(LCRTC *)sharedInstance;

- (void)createPeerConnection;
- (void)createOffer;
- (void)stopPeerConnection;

- (void)handleExchangeInfo:(NSDictionary *)msg;

@end
