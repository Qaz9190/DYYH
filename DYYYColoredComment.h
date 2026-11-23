//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  彩色评论（emoji 装饰）
//
//  ⚠️ 前置说明
//  ------------------------------------------------------------------
//  抖音评论的正文是纯文本，协议里没有「字体颜色」字段，对方看到的颜色
//  由对方客户端的渲染规则决定（浅色模式黑字 / 深色模式白字）。
//  所以「让别人看到彩色字体」在客户端层面做不到；唯一能让对方也看到
//  彩色字符的办法，是把彩色字符写进正文 —— emoji 是唯一所有客户端都
//  会渲染成彩色的字符。本模块做的是「用彩色 emoji 装饰评论文本」。
//
//  三种用法：
//  1) 手动：DYYYColoredCommentDecorateText() 生成后复制粘贴到评论框
//  2) 自动：打开设置后，发布评论时自动装饰（默认关闭）
//  3) 预览：直接拿返回值用 UILabel 显示
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// 偏好键
extern NSString *const kDYYYColoredCommentAutoKey;       // BOOL，发布时自动装饰
extern NSString *const kDYYYColoredCommentStyleKey;      // 装饰样式（中文名或数字，两者都兼容）
extern NSString *const kDYYYColoredCommentLastResultKey; // 最近一次自动装饰的结果（调试用）

typedef NS_ENUM(NSInteger, DYYYColoredCommentStyle) {
    /// 每行前置彩色圆点，逐行换色（最自然，推荐）
    DYYYColoredCommentStyleDots = 0,
    /// 正文前铺一条彩色色带，再跟正文
    DYYYColoredCommentStyleStrip,
    /// 首尾用彩色方块包边
    DYYYColoredCommentStyleBorder,
    /// 每行末尾加彩色标记
    DYYYColoredCommentStyleBadge,
};

@interface DYYYColoredComment : NSObject

/// 样式中文名，顺序与枚举一致，可直接喂给选择器
+ (NSArray<NSString *> *)styleNames;
+ (NSString *)styleNameForStyle:(DYYYColoredCommentStyle)style;
+ (DYYYColoredCommentStyle)styleForName:(nullable NSString *)name;

/// 当前样式（未设置时返回圆点样式）
+ (DYYYColoredCommentStyle)currentStyle;
/// 当前是否开启自动装饰
+ (BOOL)autoEnabled;
/// 装饰后的正文长度上限，超过就放弃装饰，避免评论发不出去
+ (NSInteger)maxLength;

/// 最近一次自动装饰的结果，例如「AWECommentPublishModel.content：已装饰（6→12 字）」
+ (NSString *)lastResult;
+ (void)setLastResult:(nullable NSString *)result;

/// 按指定样式装饰文本；空文本、已装饰过、装饰后超长都原样返回
+ (NSString *)decorateText:(nullable NSString *)text style:(DYYYColoredCommentStyle)style;
/// 用当前样式装饰
+ (NSString *)decorateTextWithCurrentStyle:(nullable NSString *)text;

/// hook 用：反射找出 model 里的正文并就地替换（同一对象只处理一次）
+ (void)decorateModel:(nullable id)model;

/// hook 用：直接装饰输入快照的 text 字段（41.2.0 已确认 AWECommentInputSnapshot.text 存在）
+ (void)decorateSnapshot:(nullable id)snapshot;

@end

NS_ASSUME_NONNULL_END
