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
@property (strong, nonatomic) RTCEAGLVideoView *localView;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (nonatomic, strong) Wilddog *ref;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, assign) int mailId;
@end

@implementation RoomViewController

- (void)dealloc {
    [_ref removeAllObservers];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.remoteView = [[RTCEAGLVideoView alloc] init];
    self.remoteView.frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    [self.view addSubview:_remoteView];
    
    self.localView = [[RTCEAGLVideoView alloc] init];
    self.localView.frame = CGRectMake(0, 60, self.view.frame.size.width * 0.3, self.view.frame.size.height * 0.3);
    [self.view addSubview:_localView];
    
    self.username = [NSString stringWithFormat:@"user%d", arc4random() % 10000];
    
    self.ref = [[Wilddog alloc] initWithUrl:@"https://webrtc-ios-demo.wilddogio.com"];
    NSString *roomPath = [NSString stringWithFormat:@"room%@", _roomId];
    NSString *roomPath_r = [NSString stringWithFormat:@"%@/r", roomPath];
    NSString *userPath = [NSString stringWithFormat:@"%@/%@", roomPath_r, _username];
    NSString *mailboxPath = [NSString stringWithFormat:@"%@/mailbox", userPath];
    
    [[_ref childByAppendingPath:userPath] setValue:@{@"state":@"join"}];
    
    LCCore *core = [LCCore sharedInstance];
    core.delegate = self;
    core.username = _username;
    core.roomId = _roomId;
    
    LCRTC *rtc = [LCRTC sharedInstance];
    [rtc createPeerConnection];
    
    __weak typeof(self) weakself = self;
    static int numOfObserve = 0;
    [[_ref childByAppendingPath:roomPath] observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
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
    
    [[_ref childByAppendingPath:roomPath_r] observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        if (![_username isEqualToString:snapshot.key]) {
            core.remoteUsername = snapshot.key;
        }
    }];
    
    [[_ref childByAppendingPath:mailboxPath] observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
        NSLog(@"%@", snapshot);
        [rtc handleExchangeInfo:snapshot.value];
        [weakself updateTextView:@{snapshot.key:snapshot.value}];
    }];
}

- (void)updateTextView:(id)value {
    _textView.text = [NSString stringWithFormat:@"%@\n\n%@", _textView.text, value];
}

# pragma mark - LCCoreDelegate
- (void)didReceiveLocalVideoTrack:(id)track {
    self.localVideoTrack = track;
    [self.localVideoTrack addRenderer:self.localView];
}

- (void)didReceiveRemoteVideoTrack:(id)track {
    self.remoteVideoTrack = track;
    [self.remoteVideoTrack addRenderer:self.remoteView];
    
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
