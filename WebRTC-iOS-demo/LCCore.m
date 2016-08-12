//
//  LCCore.m
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/11.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "LCCore.h"
#import "LC.h"

@interface LCCore ()
@property (nonatomic, strong) Wilddog *ref;
@property (nonatomic, assign) int mailId;
@end

@implementation LCCore

+ (LCCore *)sharedInstance {
    static dispatch_once_t pred = 0;
    __strong static LCCore *_sharedInstance = nil;
    dispatch_once(&pred, ^{
        _sharedInstance = [[self alloc] init];
    });
    return _sharedInstance;
}

- (void)exchange:(NSDictionary *)info {
    [self sendMsg:info toUser:_remoteUsername];
}

- (void)sendMsg:(NSDictionary *)msg toUser:(NSString *)username {
    self.ref = [[Wilddog alloc] initWithUrl:@"https://webrtc-ios-demo.wilddogio.com"];
    NSString *mailboxPath = [NSString stringWithFormat:@"room%@/%@/mailbox/mail%d", _roomId, username, _mailId++];
    NSDictionary *value = msg;
    [[_ref childByAppendingPath:mailboxPath] setValue:value];
}

@end
