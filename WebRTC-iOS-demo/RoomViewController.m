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

@interface RoomViewController () <LCCoreDelegate>
@property (strong, nonatomic) IBOutlet UITextView *textView;

@property (strong, nonatomic) RTCEAGLVideoView *remoteView;
@property (strong, nonatomic) RTCEAGLVideoView *remoteView2;
@property (strong, nonatomic) RTCEAGLVideoView *localView;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack2;
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (nonatomic, strong) Wilddog *ref;
@property (nonatomic, strong) Wilddog *ref_roomPath;
@property (nonatomic, strong) Wilddog *ref_roomPath_r;
@property (nonatomic, strong) Wilddog *ref_mailbox;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, assign) int mailId;
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
    
    self.remoteView = [[RTCEAGLVideoView alloc] init];
    self.remoteView.frame = CGRectMake(0, 0, self.view.frame.size.width*0.5, self.view.frame.size.height*0.5);
    [self.view addSubview:_remoteView];
    
    self.remoteView2 = [[RTCEAGLVideoView alloc] init];
    self.remoteView2.frame = CGRectMake(self.view.frame.size.width*0.5, 0, self.view.frame.size.width*0.5, self.view.frame.size.height*0.5);
    [self.view addSubview:_remoteView2];
    
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
    core.delegate = self;
    core.username = _username;
    core.roomId = _roomId;
    
    LCRTC *rtc = [LCRTC sharedInstance];
    [rtc createPeerConnection];
    
    __weak typeof(self) weakself = self;
    static int numOfObserve = 0;
    [_ref_roomPath observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        for (NSString *username in [snapshot.value allKeys]) {
            if (![_username isEqualToString:username]) {
                core.remoteUsername = username;
                if (numOfObserve == 0) {
                    core.isCaller = YES;
                    [rtc createOffer];
                }
            }
        }
        numOfObserve++;
    }];
    
    [_ref_roomPath_r observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        if (![_username isEqualToString:snapshot.key]) {
            core.remoteUsername = snapshot.key;
        }
    }];
    
    [_ref_mailbox observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        NSLog(@"%@", snapshot);
        [rtc handleExchangeInfo:snapshot.value];
        [weakself updateTextView:@{snapshot.key:snapshot.value}];
    }];
}

- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
    [_ref_roomPath setValue:nil];
    [[LCRTC sharedInstance] stopPeerConnection];
}

- (void)updateTextView:(id)value {
    _textView.text = [NSString stringWithFormat:@"%@\n\n%@", _textView.text, value];
}

# pragma mark - LCCoreDelegate
- (void)didReceiveLocalVideoTrack:(id)track {
    self.localVideoTrack = track;
    [self.localVideoTrack addRenderer:self.localView];
}

- (void)didReceiveRemoteVideoTracks:(NSArray *)tracks {
    self.remoteVideoTrack = tracks[0];
    [self.remoteVideoTrack addRenderer:self.remoteView];
    if (tracks.count == 2) {
        self.remoteVideoTrack2 = tracks[1];
        [self.remoteVideoTrack2 addRenderer:self.remoteView2];
    }
    
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
