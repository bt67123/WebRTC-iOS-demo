//
//  RoomViewController.m
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/10.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "LC.h"
#import "RoomViewController.h"
#import <Wilddog/Wilddog.h>

@interface RoomViewController () <LCRTCDelegate>
@property (strong, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) RTCEAGLVideoView *localView;
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (nonatomic, strong) Wilddog *ref;
@property (nonatomic, strong) Wilddog *ref_roomPath;
@property (nonatomic, strong) Wilddog *ref_roomPath_r;
@property (nonatomic, strong) Wilddog *ref_mailbox;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, assign) int mailId;
@property (nonatomic, strong) NSMutableDictionary *rtcDic;
@property (nonatomic, strong) NSMutableDictionary *remoteViewDic;
@property (nonatomic, strong) NSMutableDictionary *remoteVideoTrackDic;

@property (nonatomic, assign) NSInteger initNum;
@property (nonatomic, assign) NSInteger numOfObserve;
@end

@implementation RoomViewController

- (void)dealloc {

    [_ref removeAllObservers];
    [_ref_roomPath removeAllObservers];
    [_ref_roomPath_r removeAllObservers];
    [_ref_mailbox removeAllObservers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.rtcDic = [NSMutableDictionary dictionary];
    self.remoteViewDic = [NSMutableDictionary dictionary];
    self.remoteVideoTrackDic = [NSMutableDictionary dictionary];
    
    self.localView = [[RTCEAGLVideoView alloc] init];
    self.localView.frame = CGRectMake(0, 60, self.view.frame.size.width * 0.3, self.view.frame.size.height * 0.3);
    [self.view addSubview:_localView];
    
    self.username = [NSString stringWithFormat:@"user%d", arc4random() % 10000];
    
    self.ref = [[Wilddog alloc] initWithUrl:@"https://webrtc-ios-demo.wilddogio.com"];
    NSString *roomPath = [NSString stringWithFormat:@"room%@", _roomId];
    NSString *roomPath_r = [NSString stringWithFormat:@"%@/r", roomPath];
    NSString *userPath = [NSString stringWithFormat:@"%@/%@", roomPath_r, _username];
    NSString *mailboxPath = [NSString stringWithFormat:@"%@/mailbox", userPath];
    
    self.ref_roomPath = [_ref childByAppendingPath:roomPath];
    self.ref_roomPath_r = [_ref childByAppendingPath:roomPath_r];
    self.ref_mailbox = [_ref childByAppendingPath:mailboxPath];
    
    [[_ref childByAppendingPath:userPath] setValue:@{@"state":@"join"}];
    
    LCCore *core = [LCCore sharedInstance];
    core.username = _username;
    core.roomId = _roomId;
    
    __weak typeof(self) weakself = self;
    _initNum = -1;
    [_ref_roomPath observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        if (weakself.initNum == -1) {
            weakself.initNum = [[snapshot.value allKeys] count];
        }
        for (NSString *remoteUsername in [snapshot.value allKeys]) {
            if (![weakself.username isEqualToString:remoteUsername]) {
                
                if (![weakself.rtcDic.allKeys containsObject:remoteUsername]) {
                    [weakself createRemoteViewWithUsername:remoteUsername];
                    
                    LCRTC *rtc = [[LCRTC alloc] init];
                    rtc.delegate = weakself;
                    [weakself.rtcDic setObject:rtc forKey:remoteUsername];
                    [rtc createPeerConnection];
                    rtc.remoteUsername = remoteUsername;
                
                }
                if (weakself.numOfObserve < weakself.initNum) {
                    LCRTC *rtc = [weakself.rtcDic objectForKey:remoteUsername];
                    rtc.isCaller = YES;
                    [rtc createOffer];
                    weakself.numOfObserve++;
                }
            }
        }
    }];

    [_ref_roomPath_r observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        NSLog(@"roompath-r ------ %@", snapshot);
        NSString *remoteUsername = snapshot.key;
        if (![weakself.username isEqualToString:remoteUsername]) {
            
            if (![weakself.rtcDic.allKeys containsObject:remoteUsername]) {
                [weakself createRemoteViewWithUsername:snapshot.key];
                
                LCRTC *rtc = [[LCRTC alloc] init];
                rtc.delegate = weakself;
                [weakself.rtcDic setObject:rtc forKey:snapshot.key];
                [rtc createPeerConnection];
                rtc.remoteUsername = snapshot.key;
            }
        }
    }];
    
    [_ref_mailbox observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        NSLog(@"mailbox ------ %@", snapshot);
        if ([snapshot.value isKindOfClass:[NSDictionary class]]) {
            LCRTC *rtc = [weakself.rtcDic objectForKey:[snapshot.value objectForKey:@"from"]];
            if (rtc) {
                [rtc handleExchangeInfo:snapshot.value];
                [weakself updateTextView:@{snapshot.key:snapshot.value}];
            }
        }
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_ref_roomPath setValue:nil];
    [self disconnect];
}

- (void)disconnect {
    __weak typeof(self) weakself = self;
    [self.remoteVideoTrackDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        RTCVideoTrack *track = obj;
        RTCEAGLVideoView *remoteView = [weakself.remoteViewDic objectForKey:key];
        [track removeRenderer:remoteView];
        [remoteView renderFrame:nil];
    }];
    
    [_localVideoTrack removeRenderer:_localView];
    _localVideoTrack = nil;
    [_localView renderFrame:nil];
    
    [self.remoteVideoTrackDic removeAllObjects];
    [self.remoteViewDic removeAllObjects];
    
    [_rtcDic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        LCRTC *rtc = obj;
        [rtc stopPeerConnection];
    }];
}

- (void)createRemoteViewWithUsername:(NSString *)username {
    RTCEAGLVideoView *remoteView = [[RTCEAGLVideoView alloc] init];
    remoteView.frame = CGRectMake(self.view.frame.size.width*(_remoteViewDic.count%2*0.5),
                                       self.view.frame.size.height*(_remoteViewDic.count/2),
                                       self.view.frame.size.width*0.5, self.view.frame.size.height*0.5);
    [_remoteViewDic setObject:remoteView forKey:username];
    [self.view addSubview:remoteView];
    
    [self.view bringSubviewToFront:_localView];
}

- (void)updateTextView:(id)value {
    _textView.text = [NSString stringWithFormat:@"%@\n\n%@", _textView.text, value];
}

# pragma mark - LCCoreDelegate
- (void)rtc:(LCRTC *)rtc didReceiveLocalVideoTrack:(id)track {
    
    self.localVideoTrack = track;
    [self.localVideoTrack addRenderer:self.localView];
}

- (void)rtc:(LCRTC *)rtc didReceiveRemoteVideoTrack:(id)track {
    [self.remoteVideoTrackDic setObject:track forKey:rtc.remoteUsername];
    [[_remoteVideoTrackDic objectForKey:rtc.remoteUsername] addRenderer:[_remoteViewDic objectForKey:rtc.remoteUsername]];
    
    static BOOL hasSetVoice = NO;
    if (!hasSetVoice) {
        AVAudioSession *audioSession = [AVAudioSession sharedInstance];
        AVAudioSessionCategoryOptions option = AVAudioSessionCategoryOptionDefaultToSpeaker;
        [audioSession setCategory:AVAudioSessionCategoryPlayAndRecord
                      withOptions:option
                            error:nil];
        
        hasSetVoice = YES;
    }
}

@end
