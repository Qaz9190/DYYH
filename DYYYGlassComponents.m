//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  轻盈玻璃风格通用 UI 组件实现
//

#import "DYYYGlassComponents.h"

#pragma mark - 主题配色

@implementation DYYYPanelTheme

+ (UIColor *)textPrimary {
    return [UIColor colorWithRed:0.07 green:0.09 blue:0.13 alpha:1.0];
}

+ (UIColor *)textSecondary {
    return [UIColor colorWithRed:0.07 green:0.09 blue:0.13 alpha:0.55];
}

+ (UIColor *)textTertiary {
    return [UIColor colorWithRed:0.07 green:0.09 blue:0.13 alpha:0.32];
}

+ (UIColor *)accent {
    return [UIColor colorWithRed:0.44 green:0.66 blue:0.65 alpha:1.0];
}

+ (UIColor *)accentHighlight {
    return [UIColor colorWithRed:0.30 green:0.79 blue:0.85 alpha:1.0];
}

+ (UIColor *)cardFillTop {
    return [UIColor colorWithWhite:1.0 alpha:0.58];
}

+ (UIColor *)cardFillBottom {
    return [UIColor colorWithWhite:1.0 alpha:0.30];
}

+ (UIColor *)cardStroke {
    return [UIColor colorWithWhite:1.0 alpha:0.62];
}

+ (UIColor *)separator {
    return [UIColor colorWithWhite:1.0 alpha:0.42];
}

@end

#pragma mark - 玻璃卡片

@interface DYYYGlassCardView ()

@property(nonatomic, strong) CAGradientLayer *highlightLayer;

- (void)setupGlass;
- (void)applyHighlightColors;

@end

@implementation DYYYGlassCardView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupGlass];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupGlass];
    }
    return self;
}

- (void)setupGlass {
    _cornerRadius = 22.0;
    _showsStroke = YES;
    _highlightStrength = 1.0;

    self.backgroundColor = [UIColor clearColor];
    self.layer.cornerRadius = _cornerRadius;
    self.layer.cornerCurve = kCACornerCurveContinuous;
    self.layer.masksToBounds = YES;
    self.layer.borderWidth = 0.8;
    self.layer.borderColor = [DYYYPanelTheme cardStroke].CGColor;

    _highlightLayer = [CAGradientLayer layer];
    _highlightLayer.startPoint = CGPointMake(0.12, 0.0);
    _highlightLayer.endPoint = CGPointMake(0.88, 1.0);
    [self.layer insertSublayer:_highlightLayer atIndex:0];

    [self applyHighlightColors];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.highlightLayer.frame = self.bounds;
    [CATransaction commit];
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _cornerRadius = cornerRadius;
    self.layer.cornerRadius = cornerRadius;
}

- (void)setShowsStroke:(BOOL)showsStroke {
    _showsStroke = showsStroke;
    self.layer.borderWidth = showsStroke ? 0.8 : 0.0;
}

- (void)setHighlightStrength:(CGFloat)highlightStrength {
    _highlightStrength = MAX(0.0, MIN(1.0, highlightStrength));
    [self applyHighlightColors];
}

- (void)applyHighlightColors {
    CGFloat strength = MAX(0.0, MIN(1.0, _highlightStrength));

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.highlightLayer.colors = @[
        (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.58 * strength].CGColor,
        (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.24 * strength].CGColor,
    ];
    self.highlightLayer.locations = @[ @0.0, @1.0 ];
    [CATransaction commit];
}

- (void)setHighlighted:(BOOL)highlighted {
    [super setHighlighted:highlighted];

    [UIView animateWithDuration:0.18
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.transform = highlighted ? CGAffineTransformMakeScale(0.975, 0.975) : CGAffineTransformIdentity;
                       self.alpha = highlighted ? 0.86 : 1.0;
                     }
                     completion:nil];
}

@end

#pragma mark - 圆形玻璃按钮

@interface DYYYCircleGlassButton ()

@property(nonatomic, strong) UIImageView *iconView;

@end

@implementation DYYYCircleGlassButton

- (instancetype)initWithSystemImageName:(NSString *)imageName diameter:(CGFloat)diameter {
    self = [super initWithFrame:CGRectMake(0, 0, diameter, diameter)];
    if (self) {
        self.cornerRadius = diameter / 2.0;

        _iconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:imageName]];
        _iconView.contentMode = UIViewContentModeScaleAspectFit;
        _iconView.tintColor = [DYYYPanelTheme textPrimary];
        _iconView.alpha = 0.72;
        _iconView.userInteractionEnabled = NO;
        _iconView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_iconView];

        CGFloat iconSide = diameter * 0.42;
        [NSLayoutConstraint activateConstraints:@[
            [_iconView.centerXAnchor constraintEqualToAnchor:self.centerXAnchor],
            [_iconView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_iconView.widthAnchor constraintEqualToConstant:iconSide],
            [_iconView.heightAnchor constraintEqualToConstant:iconSide],
        ]];
    }
    return self;
}

@end

#pragma mark - 三角指示符

@implementation DYYYChevronTriangleView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
        _fillColor = [DYYYPanelTheme textPrimary];
    }
    return self;
}

- (void)setFillColor:(UIColor *)fillColor {
    _fillColor = fillColor;
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    UIBezierPath *path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(1.5, 1.5)];
    [path addLineToPoint:CGPointMake(rect.size.width - 1.0, rect.size.height / 2.0)];
    [path addLineToPoint:CGPointMake(1.5, rect.size.height - 1.5)];
    [path closePath];

    [(self.fillColor ?: [DYYYPanelTheme textPrimary]) setFill];
    [path fill];
}

@end

#pragma mark - 玻璃背景

@interface DYYYGlassBackgroundView ()

@property(nonatomic, strong) UIVisualEffectView *blurView;
@property(nonatomic, strong) CAGradientLayer *tintLayer;

@end

@implementation DYYYGlassBackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // 底色略微抬高：面板被 present 的第一帧模糊还没采样到背景时，
        // 不至于直接透出原画面造成「闪一下」。
        self.backgroundColor = [UIColor colorWithWhite:0.97 alpha:0.14];
        self.userInteractionEnabled = NO;

        UIBlurEffect *effect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemUltraThinMaterialLight];
        _blurView = [[UIVisualEffectView alloc] initWithEffect:effect];
        _blurView.userInteractionEnabled = NO;
        // 初始就铺满 + 自动伸缩，保证 layoutSubviews 之前不是空白帧
        _blurView.frame = self.bounds;
        _blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self addSubview:_blurView];

        _tintLayer = [CAGradientLayer layer];
        _tintLayer.colors = @[
            (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.34].CGColor,
            (__bridge id)[UIColor colorWithWhite:0.98 alpha:0.14].CGColor,
            (__bridge id)[UIColor colorWithWhite:1.0 alpha:0.26].CGColor,
        ];
        _tintLayer.locations = @[ @0.0, @0.52, @1.0 ];
        _tintLayer.startPoint = CGPointMake(0.5, 0.0);
        _tintLayer.endPoint = CGPointMake(0.5, 1.0);
        _tintLayer.frame = self.bounds;
        [self.layer addSublayer:_tintLayer];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.blurView.frame = self.bounds;
    self.tintLayer.frame = self.bounds;
    [CATransaction commit];
}

@end

#pragma mark - 分段标签

@interface DYYYSegmentedTabs ()

@property(nonatomic, strong) NSArray<NSString *> *titles;
@property(nonatomic, strong) NSMutableArray<UILabel *> *labels;
@property(nonatomic, strong) UIView *trackView;
@property(nonatomic, strong) UIView *pillView;

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated;
- (void)layoutSegmentsAnimated:(BOOL)animated;
- (void)applySelectionAppearance;
- (void)handleTap:(UITapGestureRecognizer *)gesture;

@end

@implementation DYYYSegmentedTabs

- (instancetype)initWithTitles:(NSArray<NSString *> *)titles {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _titles = [titles copy];
        _selectedIndex = 0;
        _labels = [NSMutableArray array];

        _trackView = [[UIView alloc] initWithFrame:CGRectZero];
        _trackView.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.24];
        _trackView.layer.cornerRadius = 14.0;
        _trackView.layer.cornerCurve = kCACornerCurveContinuous;
        _trackView.layer.borderWidth = 0.8;
        _trackView.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.45].CGColor;
        _trackView.userInteractionEnabled = NO;
        [self addSubview:_trackView];

        _pillView = [[UIView alloc] initWithFrame:CGRectZero];
        _pillView.backgroundColor = [DYYYPanelTheme accent];
        _pillView.layer.cornerRadius = 11.0;
        _pillView.layer.cornerCurve = kCACornerCurveContinuous;
        _pillView.userInteractionEnabled = NO;
        [_trackView addSubview:_pillView];

        for (NSString *title in _titles) {
            UILabel *label = [[UILabel alloc] initWithFrame:CGRectZero];
            label.text = title;
            label.font = [UIFont systemFontOfSize:15.5 weight:UIFontWeightSemibold];
            label.textAlignment = NSTextAlignmentCenter;
            label.textColor = [DYYYPanelTheme textSecondary];
            label.userInteractionEnabled = NO;
            [_trackView addSubview:label];
            [_labels addObject:label];
        }

        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
        [self addGestureRecognizer:tap];

        self.accessibilityTraits = UIAccessibilityTraitAdjustable;

        [self applySelectionAppearance];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];

    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    self.trackView.frame = self.bounds;
    [CATransaction commit];

    [self layoutSegmentsAnimated:NO];
}

- (void)layoutSegmentsAnimated:(BOOL)animated {
    NSInteger count = (NSInteger)self.labels.count;
    if (count == 0 || self.trackView.bounds.size.width <= 0) {
        return;
    }

    CGFloat segmentWidth = self.trackView.bounds.size.width / count;
    CGFloat height = self.trackView.bounds.size.height;

    for (NSInteger index = 0; index < count; index++) {
        UILabel *label = self.labels[index];
        label.frame = CGRectMake(segmentWidth * index, 0, segmentWidth, height);
    }

    CGRect pillFrame = CGRectMake(segmentWidth * self.selectedIndex + 3.0, 3.0, segmentWidth - 6.0, height - 6.0);
    if (animated) {
        [UIView animateWithDuration:0.32
                              delay:0
             usingSpringWithDamping:0.86
              initialSpringVelocity:0.5
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:^{
                           self.pillView.frame = pillFrame;
                         }
                         completion:nil];
    } else {
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.pillView.frame = pillFrame;
        [CATransaction commit];
    }
}

- (void)applySelectionAppearance {
    for (NSInteger index = 0; index < (NSInteger)self.labels.count; index++) {
        UILabel *label = self.labels[index];
        BOOL selected = (index == self.selectedIndex);
        label.textColor = selected ? [UIColor colorWithWhite:1.0 alpha:0.97] : [DYYYPanelTheme textSecondary];
        label.font = [UIFont systemFontOfSize:15.5 weight:selected ? UIFontWeightSemibold : UIFontWeightMedium];
    }
}

- (void)setSelectedIndex:(NSInteger)selectedIndex {
    [self setSelectedIndex:selectedIndex animated:NO];
}

- (void)setSelectedIndex:(NSInteger)selectedIndex animated:(BOOL)animated {
    if (self.labels.count == 0) {
        return;
    }
    _selectedIndex = MAX(0, MIN((NSInteger)self.labels.count - 1, selectedIndex));

    [UIView transitionWithView:self
                      duration:animated ? 0.18 : 0.0
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionAllowUserInteraction
                    animations:^{
                      [self applySelectionAppearance];
                    }
                    completion:nil];

    [self layoutSegmentsAnimated:animated];
}

- (void)handleTap:(UITapGestureRecognizer *)gesture {
    NSInteger count = (NSInteger)self.labels.count;
    if (count == 0) {
        return;
    }

    CGPoint point = [gesture locationInView:self];
    CGFloat segmentWidth = MAX(self.bounds.size.width / count, 1.0);
    NSInteger index = (NSInteger)floor(point.x / segmentWidth);
    index = MAX(0, MIN(count - 1, index));

    if (index == self.selectedIndex) {
        return;
    }

    [self setSelectedIndex:index animated:YES];
    if (self.onChange) {
        self.onChange(index);
    }
}

@end

#pragma mark - 页码点

@implementation DYYYPageDotsView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.userInteractionEnabled = NO;
        self.contentMode = UIViewContentModeRedraw;
        _numberOfPages = 1;
        _currentPage = 0;
    }
    return self;
}

- (void)setNumberOfPages:(NSInteger)numberOfPages {
    _numberOfPages = MAX(0, numberOfPages);
    [self invalidateIntrinsicContentSize];
    [self setNeedsDisplay];
}

- (void)setCurrentPage:(NSInteger)currentPage {
    if (_currentPage == currentPage) {
        return;
    }
    _currentPage = currentPage;
    [UIView transitionWithView:self
                      duration:0.2
                       options:UIViewAnimationOptionTransitionCrossDissolve
                    animations:^{
                      [self setNeedsDisplay];
                    }
                    completion:nil];
}

- (CGSize)intrinsicContentSize {
    return CGSizeMake(MAX(self.numberOfPages, 1) * 20.0, 16.0);
}

- (void)drawRect:(CGRect)rect {
    if (self.numberOfPages <= 0) {
        return;
    }

    CGFloat itemWidth = 20.0;
    CGFloat totalWidth = self.numberOfPages * itemWidth;
    CGFloat startX = (rect.size.width - totalWidth) / 2.0;
    CGFloat centerY = rect.size.height / 2.0;

    for (NSInteger index = 0; index < self.numberOfPages; index++) {
        CGPoint center = CGPointMake(startX + itemWidth * index + itemWidth / 2.0, centerY);

        if (index == self.currentPage) {
            UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:center radius:5.2 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
            ring.lineWidth = 1.6;
            [[DYYYPanelTheme accentHighlight] setStroke];
            [ring stroke];

            UIBezierPath *dot = [UIBezierPath bezierPathWithArcCenter:center radius:2.0 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
            [[DYYYPanelTheme accentHighlight] setFill];
            [dot fill];
        } else {
            UIBezierPath *dot = [UIBezierPath bezierPathWithArcCenter:center radius:2.6 startAngle:0 endAngle:M_PI * 2 clockwise:YES];
            [[UIColor colorWithWhite:0.1 alpha:0.16] setFill];
            [dot fill];
        }
    }
}

@end

#pragma mark - 导航行

@interface DYYYSettingRowView ()

@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *detailLabel;
@property(nonatomic, strong) DYYYChevronTriangleView *chevronView;

@end

@implementation DYYYSettingRowView

- (instancetype)initWithTitle:(NSString *)title detail:(NSString *)detail {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        self.cornerRadius = 22.0;

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.text = title;
        _titleLabel.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightSemibold];
        _titleLabel.textColor = [DYYYPanelTheme textPrimary];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _titleLabel.userInteractionEnabled = NO;
        [self addSubview:_titleLabel];

        _chevronView = [[DYYYChevronTriangleView alloc] initWithFrame:CGRectZero];
        _chevronView.fillColor = [DYYYPanelTheme textPrimary];
        _chevronView.alpha = 0.45;
        _chevronView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:_chevronView];

        _detailLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _detailLabel.text = detail;
        _detailLabel.font = [UIFont systemFontOfSize:12.5 weight:UIFontWeightMedium];
        _detailLabel.textColor = [DYYYPanelTheme textTertiary];
        _detailLabel.textAlignment = NSTextAlignmentRight;
        _detailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _detailLabel.userInteractionEnabled = NO;
        [self addSubview:_detailLabel];

        [NSLayoutConstraint activateConstraints:@[
            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.leadingAnchor constant:22.0],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],

            [_chevronView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor constant:-22.0],
            [_chevronView.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_chevronView.widthAnchor constraintEqualToConstant:7.0],
            [_chevronView.heightAnchor constraintEqualToConstant:12.0],

            [_detailLabel.trailingAnchor constraintEqualToAnchor:_chevronView.leadingAnchor constant:-10.0],
            [_detailLabel.centerYAnchor constraintEqualToAnchor:self.centerYAnchor],
            [_detailLabel.leadingAnchor constraintGreaterThanOrEqualToAnchor:_titleLabel.trailingAnchor constant:8.0],
        ]];

        self.isAccessibilityElement = YES;
        self.accessibilityLabel = title;
        self.accessibilityTraits = UIAccessibilityTraitButton;
    }
    return self;
}

- (void)setDetailText:(NSString *)detail {
    self.detailLabel.text = detail;
}

@end
