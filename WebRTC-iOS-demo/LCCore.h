//
//  LCCore.h
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/11.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LCCore : NSObject


@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *roomId;



+ (LCCore *)sharedInstance;
- (void)exchange:(NSDictionary *)info toUser:(NSString *)username;
@end
