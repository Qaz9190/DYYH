//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  抢福袋（直播 LuckyBox）
//
//  41.2.0 class-dump 依据：
//    HTSLiveLuckyBoxMessage.diamondCount   需要多少钻
//    HTSLiveLuckyBoxMessage.boxId / boxType / boxStatus / user
//    IESLiveLuckyBoxServiceManager - (void)messageReceived:(id)  ← 消息入口，self 即 manager
//    IESLiveLuckyBoxServiceManager - (void)openGrabLuckyBoxView  ← 参与入口
//
//  本版范围：当前所在直播间里，福袋一出现就按配置自动参与；
//  中奖后的收货地址自动填写已砍掉（后续再议）。
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

extern NSString *const kDYYYLBEnabledKey;      // BOOL  启用自动抢福袋
extern NSString *const kDYYYLBAllowDiamondKey; // BOOL  允许参与需要钻的福袋
extern NSString *const kDYYYLBMaxDiamondKey;   // 字符串，钻石上限
extern NSString *const kDYYYLBHostsKey;        // NSArray<NSString *>，每项「昵称|uid」或「uid」
extern NSString *const kDYYYLBLastResultKey;   // 最近一次记录

@interface DYYYLuckyBag : NSObject

+ (BOOL)enabled;
+ (BOOL)allowDiamond;
+ (NSInteger)maxDiamond;

/// 监控主播列表（空 = 所有直播间都抢）
+ (NSArray<NSString *> *)hostTokens;
+ (void)setHostTokens:(NSArray<NSString *> *)tokens;
/// 「全部直播间」或「3 个主播」
+ (NSString *)hostsSummary;
/// 主播是否在白名单内（列表为空视为允许）
+ (BOOL)hostAllowedWithUID:(nullable NSString *)uid nickname:(nullable NSString *)nickname;

+ (NSString *)lastResult;
+ (void)setLastResult:(nullable NSString *)result;

/// hook 入口：福袋消息到达时调用，manager 为 IESLiveLuckyBoxServiceManager 实例
+ (void)handleLuckyBoxMessage:(nullable id)message manager:(nullable id)manager;

@end

NS_ASSUME_NONNULL_END
