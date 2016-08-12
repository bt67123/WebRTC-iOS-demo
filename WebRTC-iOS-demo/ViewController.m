//
//  ViewController.m
//  WebRTC-iOS-demo
//
//  Created by lcj on 16/8/9.
//  Copyright © 2016年 lcj. All rights reserved.
//

#import "ViewController.h"
#import "RoomViewController.h"

@interface ViewController ()
@property (strong, nonatomic) IBOutlet UITextField *roomTextField;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
//    self.ref = [[Wilddog alloc] initWithUrl:@"https://webrtc-ios-demo.wilddogio.com"];
//    [[_ref childByAppendingPath:@"room2/userId2/mailbox/mailId3"] setValue:@{@"from":@"userId1", @"type":@"answer", @"value":@"answer hello world"}];
//    
//    [[_ref childByAppendingPath:@"room2/userId2/mailbox"] observeEventType:WEventTypeChildAdded withBlock:^(WDataSnapshot * _Nonnull snapshot) {
//        
//    }];
}

#pragma mark - storyboard
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([@"joinRoom" isEqualToString:segue.identifier]) {
        RoomViewController *ctrl = (RoomViewController *)segue.destinationViewController;
        ctrl.roomId = _roomTextField.text;
    }
}

- (IBAction)onJoinButtonClicked:(UIButton *)sender {
    if (_roomTextField.text.length > 0) {
        [self performSegueWithIdentifier:@"joinRoom" sender:nil];
    }
}

@end
