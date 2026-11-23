//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  抢福袋 hook：挂在直播 LuckyBox 服务管理器的消息入口上
//
//  41.2.0 class-dump 依据：
//    IESLiveLuckyBoxServiceManager 实现 HTSLiveMessageSubscriber，
//    其 - (void)messageReceived:(id) 就是福袋消息到达点；
//    参与入口是同对象的 - (void)openGrabLuckyBoxView。
//

#import "DYYYLuckyBag.h"

%group DYYYLuckyBagGroup

%hook IESLiveLuckyBoxServiceManager

- (void)messageReceived:(id)message {
    %orig;
    // 判定与参与逻辑在 DYYYLuckyBag 内部，这里只做转发
    [DYYYLuckyBag handleLuckyBoxMessage:message manager:self];
}

%end

%end

%ctor {
    %init(DYYYLuckyBagGroup);
}
