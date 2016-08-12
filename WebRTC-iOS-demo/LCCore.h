//
//  LCCore.h
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/11.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCCore : NSObject

@property (nonatomic, assign) BOOL isCaller;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *remoteUsername;
@property (nonatomic, copy) NSString *roomId;

+ (LCCore *)sharedInstance;
- (void)exchange:(NSDictionary *)info;
@end
