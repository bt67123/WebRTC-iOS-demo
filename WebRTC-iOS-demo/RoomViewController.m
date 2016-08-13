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
@property (strong, nonatomic) IBOutlet RTCEAGLVideoView *remoteView;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;
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
    
    self.username = [NSString stringWithFormat:@"user%d", arc4random() % 10000];
    
    self.ref = [[Wilddog alloc] initWithUrl:@"https://webrtc-ios-demo.wilddogio.com"];
    NSString *roomPath = [NSString stringWithFormat:@"room%@", _roomId];
    NSString *userPath = [NSString stringWithFormat:@"room%@/%@", _roomId, _username];
    NSString *mailboxPath = [NSString stringWithFormat:@"room%@/%@/mailbox", _roomId, _username];
    
    [[_ref childByAppendingPath:userPath] setValue:@{@"state":@"join"}];
    
    LCCore *core = [LCCore sharedInstance];
    core.delegate = self;
    core.username = _username;
    core.roomId = _roomId;
    
    LCRTC *rtc = [LCRTC sharedInstance];
    [rtc createPeerConnection];
    
    __weak typeof(self) weakself = self;
    static int numOfObserve = 0;
    [_ref observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
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
    
    [[_ref childByAppendingPath:roomPath] observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
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

//- (void)sayHi:(NSString *)username {
//    NSString *mailboxPath = [NSString stringWithFormat:@"room%@/%@/mailbox", _roomId, username];
//    NSDictionary *value = @{[NSString stringWithFormat:@"mail%d", _mailId++]:@{@"from":_username, @"type":@"offer", @"value":@"hi"}};
//    [[_ref childByAppendingPath:mailboxPath] setValue:value];
//    [self updateTextView:value];
//}

- (void)updateTextView:(id)value {
    _textView.text = [NSString stringWithFormat:@"%@\n\n%@", _textView.text, value];
}

# pragma mark - LCCoreDelegate
- (void)didReceiveLocalVideoTrack:(id)track {
    
}

- (void)didReceiveRemoteVideoTrack:(id)track {
//    self.remoteVideoTrack = track;
//    [self.remoteVideoTrack addRenderer:_remoteVideoTrack];
}

@end
