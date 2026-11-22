//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  轻盈玻璃风格通用 UI 组件（设置面板重构用）
//  说明：仅承载纯视图能力，不含任何业务/设置逻辑，可被任意面板复用。
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

#pragma mark - 主题配色

/// 面板统一配色与字号（浅色轻玻璃风格）
@interface DYYYPanelTheme : NSObject

+ (UIColor *)textPrimary;
+ (UIColor *)textSecondary;
+ (UIColor *)textTertiary;
/// 主色（低饱和青绿）
+ (UIColor *)accent;
/// 强调色（页码点/选中态）
+ (UIColor *)accentHighlight;
+ (UIColor *)cardFillTop;
+ (UIColor *)cardFillBottom;
+ (UIColor *)cardStroke;
+ (UIColor *)separator;

@end

#pragma mark - 玻璃卡片

/// 带高光渐变与描边的玻璃卡片，同时作为可点击控件使用
@interface DYYYGlassCardView : UIControl

/// 圆角，默认 22
@property(nonatomic, assign) CGFloat cornerRadius;
/// 是否显示 1px 玻璃描边，默认 YES
@property(nonatomic, assign) BOOL showsStroke;
/// 渐变方向的高光强度，0~1，默认 1
@property(nonatomic, assign) CGFloat highlightStrength;

@end

/// 圆形玻璃按钮（返回/关闭/关于等）
@interface DYYYCircleGlassButton : DYYYGlassCardView

- (instancetype)initWithSystemImageName:(NSString *)imageName diameter:(CGFloat)diameter;

@property(nonatomic, strong, readonly) UIImageView *iconView;

@end

/// 向右的小三角指示符（对齐设计稿的 ▶ 形态）
@interface DYYYChevronTriangleView : UIView

@property(nonatomic, strong, nullable) UIColor *fillColor;

@end

#pragma mark - 背景

/// 整屏玻璃背景（毛玻璃 + 柔光渐变 + 顶部高光）
@interface DYYYGlassBackgroundView : UIView

@end

#pragma mark - 分段标签

/// 胶囊分段标签，选中块带弹簧动画
@interface DYYYSegmentedTabs : UIView

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles;

@property(nonatomic, assign) NSInteger selectedIndex;
/// 仅用户点击时回调
@property(nonatomic, copy, nullable) void (^onChange)(NSInteger index);

@end

#pragma mark - 页码点

/// 页码指示点，当前页为描边圆环 + 实心点
@interface DYYYPageDotsView : UIView

@property(nonatomic, assign) NSInteger numberOfPages;
@property(nonatomic, assign) NSInteger currentPage;

@end

#pragma mark - 导航行

/// 主面板的区块导航行：标题 + 右侧数量 + 三角箭头
@interface DYYYSettingRowView : DYYYGlassCardView

- (instancetype)initWithTitle:(NSString *)title detail:(nullable NSString *)detail;

@property(nonatomic, strong, readonly) UILabel *titleLabel;
@property(nonatomic, strong, readonly) UILabel *detailLabel;

- (void)setDetailText:(nullable NSString *)detail;

@end

NS_ASSUME_NONNULL_END
