//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  彩色评论（emoji 装饰）实现
//
//  已知代价：装饰后文本变长，超过 maxLength 会自动放弃装饰，
//  避免评论发不出去；emoji 过多也可能被平台折叠，属于预期行为。
//

#import "DYYYColoredComment.h"
#import <objc/runtime.h>
#include <string.h>

NSString *const kDYYYColoredCommentAutoKey = @"DYYYColoredCommentAuto";
NSString *const kDYYYColoredCommentStyleKey = @"DYYYColoredCommentStyle";
NSString *const kDYYYColoredCommentLastResultKey = @"DYYYColoredCommentLastResult";

/// 抖音评论正文长度上限的保守值（实际约 100 字）
static const NSInteger kDYYYColoredCommentMaxLength = 96;

/// 防止同一个 model 被装饰两次
static char kDYYYColoredCommentDecoratedKey;

#pragma mark - 调色板

static NSArray<NSString *> *DYYYColoredCommentPalette(void) {
    static NSArray<NSString *> *palette;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      palette = @[ @"🔴", @"🟠", @"🟡", @"🟢", @"🔵", @"🟣", @"🟤" ];
    });
    return palette;
}

#pragma mark - 文本判定

/// 是否已经带装饰（避免重复叠加）
static BOOL DYYYColoredCommentHasDecoration(NSString *text) {
    for (NSString *dot in DYYYColoredCommentPalette()) {
        if ([text rangeOfString:dot].location != NSNotFound) {
            return YES;
        }
    }
    return NO;
}

/// 看起来像用户正文：有实际字符（汉字/字母/数字都算），不是 URL、不是纯符号空白。
/// 注意这里不能只认字母 —— 「111111」这种纯数字评论同样是正文。
static BOOL DYYYColoredCommentLooksLikeContent(NSString *text) {
    if (text.length < 2) {
        return NO;
    }
    if ([text hasPrefix:@"http://"] || [text hasPrefix:@"https://"]) {
        return NO;
    }
    if ([text rangeOfCharacterFromSet:[NSCharacterSet alphanumericCharacterSet]].location == NSNotFound) {
        // 纯 emoji / 纯标点的评论也允许装饰，但不能是没有长度信息的东西
        return text.length >= 2;
    }
    return YES;
}

/// 属性名像正文（优先级最高）
static BOOL DYYYColoredCommentNameIsContentLike(NSString *name) {
    NSString *lower = name.lowercaseString;
    for (NSString *keyword in @[ @"content", @"text", @"comment", @"desc", @"message" ]) {
        if ([lower containsString:keyword]) {
            return YES;
        }
    }
    return NO;
}

/// 属性名明显不是正文（ID / 昵称 / 头像 / 各类计数与时间），直接排除
static BOOL DYYYColoredCommentNameIsUnrelated(NSString *name) {
    NSString *lower = name.lowercaseString;
    for (NSString *keyword in @[ @"digg", @"like", @"share", @"count", @"time", @"date", @"status", @"reason", @"tip", @"hint",
                                 @"placeholder", @"toast", @"error", @"avatar" ]) {
        if ([lower containsString:keyword]) {
            return YES;
        }
    }
    for (NSString *suffix in @[ @"id", @"ids", @"idstr", @"url", @"uri", @"name", @"nick", @"token", @"schema", @"phone",
                                @"mobile", @"src", @"path", @"type" ]) {
        if ([lower hasSuffix:suffix]) {
            return YES;
        }
    }
    return NO;
}

#pragma mark - 反射扫描

/// 递归扫描对象里的字符串属性，挑出最像正文的一段
static void DYYYColoredCommentScanObject(id object, NSString *prefix, NSInteger depth, NSString **bestPath, NSString **bestText, NSInteger *bestScore) {
    if (!object || depth < 0) {
        return;
    }
    Class cls = object_getClass(object);
    // 只扫自身及最近 3 层父类，避免一路扫到 NSObject
    for (int level = 0; level < 4 && cls; level++) {
        unsigned int count = 0;
        objc_property_t *props = class_copyPropertyList(cls, &count);
        for (unsigned int i = 0; i < count; i++) {
            const char *attr = property_getAttributes(props[i]);
            if (!attr || attr[0] != 'T') {
                continue;
            }
            NSString *name = @(property_getName(props[i]));

            id value = nil;
            @try {
                value = [object valueForKey:name];
            } @catch (__unused NSException *exception) {
                continue;
            }
            if (!value) {
                continue;
            }

            NSString *path = prefix.length > 0 ? [prefix stringByAppendingFormat:@".%@", name] : name;

            if ([value isKindOfClass:[NSString class]]) {
                NSString *text = (NSString *)value;
                if (text.length < 2 || text.length > 400) {
                    continue;
                }
                if (DYYYColoredCommentNameIsUnrelated(name)) {
                    continue;
                }
                if (!DYYYColoredCommentLooksLikeContent(text)) {
                    continue;
                }
                NSInteger score = (DYYYColoredCommentNameIsContentLike(name) ? 1000 : 500) + (NSInteger)MIN(text.length, (NSUInteger)200);
                if (score > *bestScore) {
                    *bestScore = score;
                    *bestPath = path;
                    *bestText = text;
                }
            } else if (depth > 0 && value != object) {
                // 只往「内容/请求/模型」这类容器里再钻一层，避免扫遍整棵对象图
                NSString *lower = name.lowercaseString;
                if ([lower containsString:@"content"] || [lower containsString:@"text"] || [lower containsString:@"request"] ||
                    [lower containsString:@"model"] || [lower containsString:@"draft"]) {
                    DYYYColoredCommentScanObject(value, path, depth - 1, bestPath, bestText, bestScore);
                }
            }
        }
        if (props) {
            free(props);
        }
        cls = class_getSuperclass(cls);
    }
}

#pragma mark -

@implementation DYYYColoredComment

+ (NSArray<NSString *> *)styleNames {
    return @[ @"彩色圆点", @"彩色色带", @"彩色包边", @"彩色角标" ];
}

+ (NSString *)styleNameForStyle:(DYYYColoredCommentStyle)style {
    NSArray<NSString *> *names = [self styleNames];
    NSInteger index = (NSInteger)style;
    if (index < 0 || index >= (NSInteger)names.count) {
        index = 0;
    }
    return names[index];
}

+ (DYYYColoredCommentStyle)styleForName:(NSString *)name {
    if (name.length == 0) {
        return DYYYColoredCommentStyleDots;
    }
    NSInteger index = (NSInteger)[[self styleNames] indexOfObject:name];
    if (index == NSNotFound) {
        // 也接受纯数字（手写偏好或旧版本）
        index = name.integerValue;
    }
    if (index < DYYYColoredCommentStyleDots || index > DYYYColoredCommentStyleBadge) {
        index = DYYYColoredCommentStyleDots;
    }
    return (DYYYColoredCommentStyle)index;
}

+ (DYYYColoredCommentStyle)currentStyle {
    id raw = [[NSUserDefaults standardUserDefaults] objectForKey:kDYYYColoredCommentStyleKey];
    if ([raw isKindOfClass:[NSString class]]) {
        return [self styleForName:(NSString *)raw];
    }
    if ([raw respondsToSelector:@selector(integerValue)]) {
        NSInteger index = [raw integerValue];
        if (index < DYYYColoredCommentStyleDots || index > DYYYColoredCommentStyleBadge) {
            index = DYYYColoredCommentStyleDots;
        }
        return (DYYYColoredCommentStyle)index;
    }
    return DYYYColoredCommentStyleDots;
}

+ (BOOL)autoEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kDYYYColoredCommentAutoKey];
}

+ (NSInteger)maxLength {
    return kDYYYColoredCommentMaxLength;
}

+ (NSString *)lastResult {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:kDYYYColoredCommentLastResultKey];
    return [value isKindOfClass:[NSString class]] ? (NSString *)value : @"尚未记录";
}

+ (void)setLastResult:(NSString *)result {
    [[NSUserDefaults standardUserDefaults] setObject:(result ?: @"") forKey:kDYYYColoredCommentLastResultKey];
}

+ (NSString *)decorateText:(NSString *)text style:(DYYYColoredCommentStyle)style {
    if (![text isKindOfClass:[NSString class]]) {
        return @"";
    }
    if (text.length == 0) {
        return text;
    }
    if (DYYYColoredCommentHasDecoration(text)) {
        return text;
    }

    NSArray<NSString *> *palette = DYYYColoredCommentPalette();
    NSArray<NSString *> *lines = [text componentsSeparatedByString:@"\n"];
    NSMutableArray<NSString *> *result = [NSMutableArray arrayWithCapacity:lines.count + 1];

    switch (style) {
        case DYYYColoredCommentStyleDots: {
            NSUInteger index = 0;
            for (NSString *line in lines) {
                if (line.length == 0) {
                    [result addObject:@""];
                    continue;
                }
                [result addObject:[NSString stringWithFormat:@"%@ %@", palette[index++ % palette.count], line]];
            }
            break;
        }

        case DYYYColoredCommentStyleBadge: {
            NSUInteger index = 0;
            for (NSString *line in lines) {
                if (line.length == 0) {
                    [result addObject:@""];
                    continue;
                }
                [result addObject:[NSString stringWithFormat:@"%@ %@", line, palette[index++ % palette.count]]];
            }
            break;
        }

        case DYYYColoredCommentStyleStrip: {
            NSMutableString *strip = [NSMutableString string];
            NSUInteger wanted = MIN(palette.count, MAX((NSUInteger)3, (NSUInteger)text.length / 4));
            for (NSUInteger i = 0; i < MIN(wanted, palette.count); i++) {
                [strip appendString:palette[i]];
            }
            [result addObject:strip];
            [result addObjectsFromArray:lines];
            break;
        }

        case DYYYColoredCommentStyleBorder: {
            if (lines.count == 0) {
                return text;
            }
            NSMutableArray<NSString *> *tmp = [lines mutableCopy];
            if ([tmp.firstObject length] > 0) {
                tmp[0] = [NSString stringWithFormat:@"%@ %@", palette[0], tmp.firstObject];
            }
            if (tmp.count > 0 && [tmp.lastObject length] > 0) {
                NSUInteger last = tmp.count - 1;
                tmp[last] = [NSString stringWithFormat:@"%@ %@", tmp[last], palette[1 % palette.count]];
            }
            result = tmp;
            break;
        }
    }

    NSString *composed = [result componentsJoinedByString:@"\n"];

    // 超长兜底：宁可不装饰，也不能让评论发不出去
    if ((NSInteger)composed.length > kDYYYColoredCommentMaxLength) {
        return text;
    }
    return composed;
}

+ (NSString *)decorateTextWithCurrentStyle:(NSString *)text {
    return [self decorateText:text style:[self currentStyle]];
}

#pragma mark - 自动装饰（反射找正文）

+ (void)decorateSnapshot:(id)snapshot {
    if (!snapshot) {
        return;
    }
    NSString *text = nil;
    @try {
        text = [snapshot valueForKey:@"text"];
    } @catch (__unused NSException *exception) {
        text = nil;
    }
    if (![text isKindOfClass:[NSString class]] || text.length == 0) {
        // 拿不到 text 就走反射兜底
        [self decorateModel:snapshot];
        return;
    }

    NSString *decorated = [self decorateText:text style:[self currentStyle]];
    if (decorated.length == text.length) {
        [self setLastResult:@"输入快照：未变化（可能已装饰或超长）"];
        return;
    }
    NSUInteger originalLength = text.length;
    @try {
        [snapshot setValue:decorated forKey:@"text"];
        [self setLastResult:[NSString stringWithFormat:@"输入快照 text：已装饰（%lu→%lu 字）", (unsigned long)originalLength,
                                                       (unsigned long)decorated.length]];
    } @catch (__unused NSException *exception) {
        [self setLastResult:@"输入快照 text：写入失败"];
    }
}

+ (void)decorateModel:(id)model {
    if (!model) {
        return;
    }
    if (objc_getAssociatedObject(model, &kDYYYColoredCommentDecoratedKey)) {
        return;
    }

    NSString *bestPath = nil;
    NSString *bestText = nil;
    NSInteger bestScore = -1;
    DYYYColoredCommentScanObject(model, @"", 1, &bestPath, &bestText, &bestScore);

    NSString *className = NSStringFromClass(object_getClass(model)) ?: @"?";
    if (bestPath.length == 0 || bestText.length == 0) {
        [self setLastResult:[NSString stringWithFormat:@"%@：没找到正文", className]];
        return;
    }

    NSString *decorated = [self decorateText:bestText style:[self currentStyle]];
    if (decorated.length == bestText.length) {
        [self setLastResult:[NSString stringWithFormat:@"%@.%@：未变化（可能已装饰或超长）", className, bestPath]];
        return;
    }

    NSUInteger originalLength = bestText.length;
    BOOL succeeded = NO;
    // 可变字符串就原地改，省得依赖 KVC 写回
    if ([bestText isKindOfClass:[NSMutableString class]]) {
        [(NSMutableString *)bestText setString:decorated];
        succeeded = YES;
    } else {
        @try {
            [model setValue:decorated forKeyPath:bestPath];
            succeeded = YES;
        } @catch (__unused NSException *exception) {
            succeeded = NO;
        }
    }

    // 写成功才打标记，失败时留机会给下一个 hook 点重试
    if (succeeded) {
        objc_setAssociatedObject(model, &kDYYYColoredCommentDecoratedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    [self setLastResult:[NSString stringWithFormat:@"%@.%@：%@（%lu→%lu 字）", className, bestPath, succeeded ? @"已装饰" : @"写入失败",
                                                   (unsigned long)originalLength, (unsigned long)decorated.length]];
}

@end
