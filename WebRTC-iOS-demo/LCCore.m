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

- (void)exchange:(NSDictionary *)info toUser:(NSString *)username {
    [self sendMsg:info toUser:username];
}

- (void)sendMsg:(NSDictionary *)msg toUser:(NSString *)username {
    self.ref = [[Wilddog alloc] initWithUrl:@"https://webrtc-ios-demo.wilddogio.com"];
    NSString *mailboxPath = [NSString stringWithFormat:@"room%@/r/%@/mailbox/mail%d", _roomId, username, _mailId++];
    NSMutableDictionary *value = [NSMutableDictionary dictionaryWithDictionary:msg];
    [value setObject:self.username forKey:@"from"];
    [[_ref childByAppendingPath:mailboxPath] setValue:value];
}

@end
