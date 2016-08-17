//
//  LCRTC.m
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/11.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "LC.h"
#import "LCRTC.h"

#define STUN_URI @"stun:stun.l.google.com:19302"

@interface LCRTC () <RTCPeerConnectionDelegate, RTCSessionDescriptionDelegate>
@property (nonatomic, strong)  NSMutableArray *iceServers;

@end

@implementation LCRTC

//+ (LCRTC *)sharedInstance {
//    static dispatch_once_t pred = 0;
//    __strong static LCRTC *_sharedrtc = nil;
//    dispatch_once(&pred, ^{
//        _sharedrtc = [[self alloc] init];
//    });
//    return _sharedrtc;
//}

/**
 * create peerConnection
 **/
- (void)createPeerConnection {
    self.queuedRemoteCandidates = [NSMutableArray array];
    [RTCPeerConnectionFactory initializeSSL];
    self.peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    RTCPair *audioPair = [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"];
    NSMutableArray *mandatoryConstraints = [NSMutableArray arrayWithObject:audioPair];
//    if (_isVideoEnabled) {
        [mandatoryConstraints addObject:[[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]];
//    }
    
    NSArray *optionalConstraints = @[[[RTCPair alloc] initWithKey:@"internalSctpDataChannels" value:@"true"],
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"false"],];
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                                                             optionalConstraints:optionalConstraints];
    self.iceServers = [NSMutableArray array];
    RTCICEServer *stunICEServer = [[RTCICEServer alloc] initWithURI:[NSURL URLWithString:STUN_URI]
                                                           username:@"username"
                                                           password:@"password"];
    [_iceServers addObject:stunICEServer];
    self.peerConnection = [_peerConnectionFactory peerConnectionWithICEServers:_iceServers
                                                                   constraints:constraints
                                                                      delegate:self];
    
    RTCMediaStream *stream = [_peerConnectionFactory mediaStreamWithLabel:@"ARDAMS"];
    
//    if (_isVideoEnabled) {
        NSString *cameraID = nil;
        for (AVCaptureDevice *device in [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
            if (device.position == AVCaptureDevicePositionFront) {
                cameraID = [device localizedName];
                break;
            }
        }
        if (cameraID) {
            RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
            RTCMediaConstraints *videoConstraints = [[RTCMediaConstraints alloc] init];
            RTCVideoSource *videoSource = [self.peerConnectionFactory videoSourceWithCapturer:capturer
                                                                                  constraints:videoConstraints];
            RTCVideoTrack *videoTrack = [self.peerConnectionFactory videoTrackWithID:@"ARDAMSv0" source:videoSource];
            if ([self.delegate respondsToSelector:@selector(rtc:didReceiveLocalVideoTrack:)]) {
                [self.delegate rtc:self didReceiveLocalVideoTrack:videoTrack];
            }
            [stream addVideoTrack:videoTrack];
        }
//    }
    
    [stream addAudioTrack:[_peerConnectionFactory audioTrackWithID:@"ARDAMSa0"]];
    [_peerConnection addStream:stream];// constraints:constraints];
}

- (void)createOffer {
    RTCPair *audioPair = [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"];
    NSMutableArray *mandatoryConstraints = [NSMutableArray arrayWithObject:audioPair];
//    if (_isVideoEnabled) {
        [mandatoryConstraints addObject:[[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]];
//    }
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints
                                                                             optionalConstraints:nil];
    [_peerConnection createOfferWithDelegate:self constraints:constraints];
}

- (void)drainRemoteCandidates {
    if (_queuedRemoteCandidates) {
        for (RTCICECandidate *candidate in _queuedRemoteCandidates) {
            [_peerConnection addICECandidate:candidate];
        }
    }
    self.queuedRemoteCandidates = nil;
}

- (void)stopPeerConnection {
    NSLog(@"--------------- stop peer connection, %d", self.peerConnection.iceConnectionState);
    if (self.peerConnection.iceConnectionState != RTCICEConnectionNew) {
        [self.peerConnection close];
    }
    self.peerConnection = nil;
    self.queuedRemoteCandidates = nil;
    [RTCPeerConnectionFactory deinitializeSSL];
}

- (void)handleExchangeInfo:(NSDictionary *)msg {
    NSString *infoType = msg[@"type"];
    if ([infoType isEqualToString:@"offer"] || [infoType isEqualToString:@"answer"]) {
        RTCSessionDescription *sdp = nil;
        sdp = [[RTCSessionDescription alloc] initWithType:msg[@"type"]
                                                      sdp:msg[@"sdp"]];
        [self.peerConnection setRemoteDescriptionWithDelegate:self sessionDescription:sdp];
    } else if ([infoType isEqualToString:@"candidate"]) {
        NSString *mid = msg[@"id"];
        NSNumber *sdpLineIndex = msg[@"label"];
        NSString *sdp = msg[@"candidate"];
        
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:mid index:sdpLineIndex.intValue sdp:sdp];
        if (_queuedRemoteCandidates) {
            [_queuedRemoteCandidates addObject:candidate];
        } else {
            [self.peerConnection addICECandidate:candidate];
        }
    }
}


#pragma mark - RTCPeerConnectionDelegate
// Triggered when there is an error.
- (void)peerConnectionOnError:(RTCPeerConnection*)peerConnection {
  
}

// Triggered when the SignalingState changed.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged {
   
}

// Triggered when media is received on a new stream from remote peer.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
           addedStream:(RTCMediaStream*)stream {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSLog(@"peerConnection onAddStream.");
//        if (_isVideoEnabled) {
            if ([stream.audioTracks count] == 1 && [stream.videoTracks count] == 1) {
                if ([self.delegate respondsToSelector:@selector(rtc:didReceiveRemoteVideoTrack:)]) {
                    [self.delegate rtc:self didReceiveRemoteVideoTrack:stream.videoTracks[0]];
                }
            } else {
            }
//        } else {
            if ([stream.audioTracks count] == 1) {
            } else {
            }
//        }
    });
}

// Triggered when a remote peer close a stream.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
         removedStream:(RTCMediaStream*)stream {
 
}

// Triggered when renegotation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection*)peerConnection {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSLog(@"peerConnection onRenegotiationNeeded - ignoring because AppRTC has a predefined negotiation strategy");
    });
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
       gotICECandidate:(RTCICECandidate*)candidate {
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSLog(@"peerConnection onICECandidate.\n  Mid[%@] Index[%@] Sdp[%@]",
              candidate.sdpMid,
              @(candidate.sdpMLineIndex),
              candidate.sdp);
        NSDictionary* candidateInfo = @{
                                        @"type" : @"candidate",
                                        @"label" : [NSNumber numberWithInteger:candidate.sdpMLineIndex],
                                        @"id" : candidate.sdpMid,
                                        @"candidate" : candidate.sdp
                                        };
        LCCore *core = [LCCore sharedInstance];
        NSLog(@".....exchange info : %@", candidateInfo);
        [core exchange:candidateInfo toUser:_remoteUsername];
    });
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState {
   
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState {
    
}

- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel {
    
}

#pragma mark - RTCSessionDescriptionDelegate

// Match |pattern| to |string| and return the first group of the first
// match, or nil if no match was found.
+ (NSString*)firstMatch:(NSRegularExpression*)pattern
             withString:(NSString*)string {
    NSTextCheckingResult* result = [pattern firstMatchInString:string
                                                       options:0
                                                         range:NSMakeRange(0, [string length])];
    if (!result)
        return nil;
    return [string substringWithRange:[result rangeAtIndex:1]];
}

// Called when creating a session.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            NSLog(@"sessionDescription onFailure. %@", error.description);
            //            NSAssert(NO, error.description);
            return;
        }
        
        [_peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
        NSDictionary *sdpDict = @{ @"type" : sdp.type, @"sdp" : sdp.description };
        
        NSLog(@"sdpDict : %@", sdpDict);
        LCCore *core = [LCCore sharedInstance];
        [core exchange:sdpDict toUser:_remoteUsername];
    });
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            NSLog(@"sessionDescription onFailure.");
            return;
        }
        if (_isCaller) {
            // caller
            if (_peerConnection.remoteDescription) {
                [self drainRemoteCandidates];
            }
        } else {
            // callee
            if (!_peerConnection.localDescription) {
                NSArray *mandatoryConstraints = @[[[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                                  [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]];
                RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:mandatoryConstraints optionalConstraints:nil];
                [_peerConnection createAnswerWithDelegate:self constraints:constraints];
            } else {
                [self drainRemoteCandidates];
            }
        }
    });
}

#pragma mark - RTCStatsDelegate
- (void)peerConnection:(RTCPeerConnection*)peerConnection
           didGetStats:(NSArray*)stats {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString* message = [NSString stringWithFormat:@"Stats:\n %@", stats];
        NSLog(@"%@", message);
    });
}

@end
