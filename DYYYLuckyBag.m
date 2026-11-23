//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  抢福袋实现：配置读取 + 消息判定 + 自动参与
//

#import "DYYYLuckyBag.h"
#import <UIKit/UIKit.h>
#import <objc/message.h>

NSString *const kDYYYLBEnabledKey = @"DYYYLBEnabled";
NSString *const kDYYYLBAllowDiamondKey = @"DYYYLBAllowDiamond";
NSString *const kDYYYLBMaxDiamondKey = @"DYYYLBMaxDiamond";
NSString *const kDYYYLBHostsKey = @"DYYYLBHosts";
NSString *const kDYYYLBLastResultKey = @"DYYYLBLastResult";

/// 已处理过的福袋 id，避免同一条消息重复参与
static NSMutableSet<NSString *> *DYYYLuckyBagHandledBoxIDs(void) {
    static NSMutableSet<NSString *> *set;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      set = [NSMutableSet set];
    });
    return set;
}

#pragma mark - 消息解析

/// 从消息对象里找出带 diamondCount 的福袋内容（兼容一层包装）
static id DYYYLuckyBagPayload(id message) {
    if (!message) {
        return nil;
    }
    SEL diamondSelector = NSSelectorFromString(@"diamondCount");
    if ([message respondsToSelector:diamondSelector]) {
        return message;
    }
    NSArray<NSString *> *keys = @[ @"payload", @"content", @"message", @"body", @"luckyBox", @"data", @"model" ];
    for (NSString *key in keys) {
        id value = nil;
        @try {
            value = [message valueForKey:key];
        } @catch (__unused NSException *exception) {
            continue;
        }
        if (!value || value == message) {
            continue;
        }
        if ([value respondsToSelector:diamondSelector]) {
            return value;
        }
        for (NSString *innerKey in keys) {
            id inner = nil;
            @try {
                inner = [value valueForKey:innerKey];
            } @catch (__unused NSException *exception) {
                continue;
            }
            if (inner && [inner respondsToSelector:diamondSelector]) {
                return inner;
            }
        }
    }
    return nil;
}

/// payload 上取一个字段（KVC，失败返回 nil）
static id DYYYLuckyBagValue(id payload, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        id value = nil;
        @try {
            value = [payload valueForKey:key];
        } @catch (__unused NSException *exception) {
            continue;
        }
        if (value && value != [NSNull null]) {
            return value;
        }
    }
    return nil;
}

/// 从 HTSLiveUser 这类对象里取一个可比较的 id 字符串
static NSString *DYYYLuckyBagUserToken(id user) {
    if (!user) {
        return nil;
    }
    if ([user isKindOfClass:[NSString class]]) {
        return (NSString *)user;
    }
    id value = DYYYLuckyBagValue(user, @[ @"secUid", @"sec_uid", @"userIdStr", @"idStr", @"uid", @"userId", @"id" ]);
    if ([value isKindOfClass:[NSString class]] && ((NSString *)value).length > 0) {
        return (NSString *)value;
    }
    if ([value respondsToSelector:@selector(stringValue)]) {
        NSString *text = [value stringValue];
        return text.length > 0 ? text : nil;
    }
    return nil;
}

#pragma mark -

@implementation DYYYLuckyBag

+ (BOOL)enabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDYYYLBEnabledKey];
}

+ (BOOL)allowDiamond {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDYYYLBAllowDiamondKey];
}

+ (NSInteger)maxDiamond {
    id raw = [[NSUserDefaults standardUserDefaults] objectForKey:kDYYYLBMaxDiamondKey];
    if ([raw isKindOfClass:[NSString class]]) {
        return [(NSString *)raw integerValue];
    }
    if ([raw respondsToSelector:@selector(integerValue)]) {
        return [raw integerValue];
    }
    return 0;
}

+ (NSArray<NSString *> *)hostTokens {
    id raw = [[NSUserDefaults standardUserDefaults] objectForKey:kDYYYLBHostsKey];
    if (![raw isKindOfClass:[NSArray class]]) {
        return @[];
    }
    NSMutableArray<NSString *> *tokens = [NSMutableArray array];
    for (id item in (NSArray *)raw) {
        if ([item isKindOfClass:[NSString class]] && ((NSString *)item).length > 0) {
            [tokens addObject:item];
        }
    }
    return tokens;
}

+ (void)setHostTokens:(NSArray<NSString *> *)tokens {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (tokens.count == 0) {
        [defaults removeObjectForKey:kDYYYLBHostsKey];
        return;
    }
    [defaults setObject:tokens forKey:kDYYYLBHostsKey];
}

+ (NSString *)hostsSummary {
    NSArray<NSString *> *tokens = [self hostTokens];
    if (tokens.count == 0) {
        return @"全部直播间";
    }
    return [NSString stringWithFormat:@"%lu 个主播", (unsigned long)tokens.count];
}

+ (BOOL)hostAllowedWithUID:(NSString *)uid nickname:(NSString *)nickname {
    NSArray<NSString *> *tokens = [self hostTokens];
    if (tokens.count == 0) {
        return YES;
    }
    if (uid.length == 0 && nickname.length == 0) {
        return YES;
    }
    for (NSString *token in tokens) {
        NSString *trimmed = [token stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0) {
            continue;
        }
        if (uid.length > 0 && ([trimmed isEqualToString:uid] || [trimmed hasSuffix:[@"|" stringByAppendingString:uid]])) {
            return YES;
        }
        if (nickname.length > 0 && [trimmed hasPrefix:[nickname stringByAppendingString:@"|"]]) {
            return YES;
        }
    }
    return NO;
}

+ (NSString *)lastResult {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:kDYYYLBLastResultKey];
    return [value isKindOfClass:[NSString class]] ? (NSString *)value : @"尚无记录";
}

+ (void)setLastResult:(NSString *)result {
    [[NSUserDefaults standardUserDefaults] setObject:(result ?: @"") forKey:kDYYYLBLastResultKey];
}

#pragma mark - 核心判定

+ (void)handleLuckyBoxMessage:(id)message manager:(id)manager {
    if (![self enabled] || !manager) {
        return;
    }

    id payload = DYYYLuckyBagPayload(message);
    if (!payload) {
        return; // 不是福袋消息，直接忽略
    }

    NSInteger cost = [[DYYYLuckyBagValue(payload, @[ @"diamondCount" ]) description] integerValue];
    NSString *boxID = [DYYYLuckyBagValue(payload, @[ @"boxId" ]) description];
    id user = DYYYLuckyBagValue(payload, @[ @"user" ]);
    NSString *uid = DYYYLuckyBagUserToken(user);
    NSString *nickname = nil;
    id nickValue = DYYYLuckyBagValue(user, @[ @"nickname", @"nickName" ]);
    if ([nickValue isKindOfClass:[NSString class]]) {
        nickname = nickValue;
    }
    NSString *title = nil;
    id titleValue = DYYYLuckyBagValue(payload, @[ @"title" ]);
    if ([titleValue isKindOfClass:[NSString class]]) {
        title = titleValue;
    }

    // 同一个福袋只处理一次
    NSString *dedupeKey = boxID.length > 0 ? boxID : [NSString stringWithFormat:@"%@-%ld", uid ?: @"?", (long)cost];
    if ([DYYYLuckyBagHandledBoxIDs() containsObject:dedupeKey]) {
        return;
    }
    [DYYYLuckyBagHandledBoxIDs() addObject:dedupeKey];

    NSString *who = nickname.length > 0 ? nickname : (uid.length > 0 ? uid : @"未知主播");
    NSString *bagName = title.length > 0 ? title : @"福袋";

    if (![self hostAllowedWithUID:uid nickname:nickname]) {
        [self setLastResult:[NSString stringWithFormat:@"跳过：%@ 不在监控列表", who]];
        return;
    }

    if (cost > 0) {
        if (![self allowDiamond]) {
            [self setLastResult:[NSString stringWithFormat:@"跳过：%@ 的%@需 %ld 钻（未开启钻石参与）", who, bagName, (long)cost]];
            return;
        }
        NSInteger limit = [self maxDiamond];
        if (cost > limit) {
            [self setLastResult:[NSString stringWithFormat:@"跳过：%@ 的%@需 %ld 钻（上限 %ld）", who, bagName, (long)cost, (long)limit]];
            return;
        }
    }

    [self setLastResult:[NSString stringWithFormat:@"参与中：%@ 的%@（%ld 钻）", who, bagName, (long)cost]];

    // 消息到达时视图可能还没就绪，稍等一下再调参与入口
    __weak id weakManager = manager;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      id strongManager = weakManager;
      if (!strongManager) {
          [self setLastResult:[NSString stringWithFormat:@"失败：%@ 的%@（直播间已退出）", who, bagName]];
          return;
      }
      SEL grabSelector = NSSelectorFromString(@"openGrabLuckyBoxView");
      if (![strongManager respondsToSelector:grabSelector]) {
          [self setLastResult:@"失败：当前版本没有 openGrabLuckyBoxView"];
          return;
      }
      @try {
          ((void (*)(id, SEL))objc_msgSend)(strongManager, grabSelector);
          [self setLastResult:[NSString stringWithFormat:@"已参与：%@ 的%@（%ld 钻）", who, bagName, (long)cost]];
      } @catch (__unused NSException *exception) {
          [self setLastResult:[NSString stringWithFormat:@"失败：%@ 的%@（调用异常）", who, bagName]];
      }
    });
}

@end
