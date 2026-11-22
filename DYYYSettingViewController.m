//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
//  两指长按打开的自定义设置面板
//  UI 已按轻玻璃风格重构：顶栏圆形按钮 + 标题区 + 页码点 + 分段标签 + 区块卡片 + 二级详情页
//

#import "DYYYSettingViewController.h"
#import "DYYYAboutDialogView.h"
#import "DYYYConstants.h"
#import "DYYYGlassComponents.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#pragma mark - 数据模型

typedef NS_ENUM(NSInteger, DYYYSettingItemType) { DYYYSettingItemTypeSwitch, DYYYSettingItemTypeTextField, DYYYSettingItemTypePicker };

@interface DYYYSettingItem : NSObject

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSString *key;
@property(nonatomic, assign) DYYYSettingItemType type;
@property(nonatomic, copy, nullable) NSString *placeholder;

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type;
+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type placeholder:(nullable NSString *)placeholder;

@end

@implementation DYYYSettingItem

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type {
    return [self itemWithTitle:title key:key type:type placeholder:nil];
}

+ (instancetype)itemWithTitle:(NSString *)title key:(NSString *)key type:(DYYYSettingItemType)type placeholder:(nullable NSString *)placeholder {
    DYYYSettingItem *item = [[DYYYSettingItem alloc] init];
    item.title = title;
    item.key = key;
    item.type = type;
    item.placeholder = placeholder;
    return item;
}

@end

@interface DYYYSettingSection : NSObject

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSArray<DYYYSettingItem *> *items;

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<DYYYSettingItem *> *)items;

@end

@implementation DYYYSettingSection

+ (instancetype)sectionWithTitle:(NSString *)title items:(NSArray<DYYYSettingItem *> *)items {
    DYYYSettingSection *section = [[DYYYSettingSection alloc] init];
    section.title = title;
    section.items = items;
    return section;
}

@end

@interface DYYYSettingTab : NSObject

@property(nonatomic, copy) NSString *title;
@property(nonatomic, copy) NSArray<DYYYSettingSection *> *sections;

+ (instancetype)tabWithTitle:(NSString *)title sections:(NSArray<DYYYSettingSection *> *)sections;

@end

@implementation DYYYSettingTab

+ (instancetype)tabWithTitle:(NSString *)title sections:(NSArray<DYYYSettingSection *> *)sections {
    DYYYSettingTab *tab = [[DYYYSettingTab alloc] init];
    tab.title = title;
    tab.sections = sections;
    return tab;
}

@end

#pragma mark - 设置目录（数据层）

/// 集中管理面板的所有区块与二级选项，控制器只负责渲染
@interface DYYYSettingStore : NSObject

+ (void)prepareDefaultValues;
+ (NSArray<DYYYSettingTab *> *)tabs;
+ (NSArray *)optionsForKey:(NSString *)key;
+ (NSString *)displayValueForKey:(NSString *)key value:(id)value;
+ (id)defaultValueForKey:(NSString *)key;
/// 取当前值（未设置时回落到默认值）
+ (id)currentValueForKey:(NSString *)key;

@end

static NSArray<DYYYSettingTab *> *gDYYYSettingTabs = nil;

@implementation DYYYSettingStore

+ (void)prepareDefaultValues {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    // 如果快捷倍速数值未设置，设置默认值
    if (![defaults objectForKey:@"DYYYSpeedSettings"]) {
        [defaults setObject:@"1.0,1.25,1.5,2.0" forKey:@"DYYYSpeedSettings"];
    }

    // 如果按钮大小未设置，设置默认值
    if (![defaults objectForKey:@"DYYYSpeedButtonSize"]) {
        [defaults setFloat:32.0 forKey:@"DYYYSpeedButtonSize"];
    }
}

+ (NSArray<DYYYSettingTab *> *)tabs {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      DYYYSettingSection *basicSection = [DYYYSettingSection sectionWithTitle:@"基本设置"
                                                                       items:@[
                                                                           [DYYYSettingItem itemWithTitle:@"视频背景颜色" key:@"DYYYVideoBGColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制"],
                                                                           [DYYYSettingItem itemWithTitle:@"启用弹幕改色" key:@"DYYYEnableDanmuColor" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"自定弹幕颜色" key:@"DYYYDanmuColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制"],
                                                                           [DYYYSettingItem itemWithTitle:@"设置默认倍速" key:@"DYYYDefaultSpeed" type:DYYYSettingItemTypePicker],
                                                                           [DYYYSettingItem itemWithTitle:@"设置长按倍速" key:@"DYYYLongPressSpeed" type:DYYYSettingItemTypePicker],
                                                                           [DYYYSettingItem itemWithTitle:@"上下控制倍速" key:@"DYYYEnableLongPressSpeedGesture" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"显示进度时长" key:@"DYYYShowScheduleDisplay" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"进度时长样式" key:@"DYYYScheduleStyle" type:DYYYSettingItemTypeTextField placeholder:@"默认"],
                                                                           [DYYYSettingItem itemWithTitle:@"进度纵轴位置" key:@"DYYYTimelineVerticalPosition" type:DYYYSettingItemTypeTextField placeholder:@"-12.5"],
                                                                           [DYYYSettingItem itemWithTitle:@"进度标签颜色" key:@"DYYYProgressLabelColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制"],
                                                                           [DYYYSettingItem itemWithTitle:@"隐藏视频进度" key:@"DYYYHideVideoProgress" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"启用自动播放" key:@"DYYYEnableAutoPlay" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"忽略投屏 VPN 检测" key:@"DYYYDisableCastVPNCheck" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"推荐过滤直播" key:@"DYYYSkipLive" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"推荐过滤热点" key:@"DYYYSkipHotSpot" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"推荐过滤低赞" key:@"DYYYFilterLowLikes" type:DYYYSettingItemTypeTextField placeholder:@"填0关闭"],
                                                                           [DYYYSettingItem itemWithTitle:@"推荐视频时限" key:@"DYYYFilterTimeLimit" type:DYYYSettingItemTypeTextField placeholder:@"填0关闭，单位为天"],
                                                                           [DYYYSettingItem itemWithTitle:@"推荐过滤HDR" key:@"DYYYFilterFeedHDR" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"启用首页净化" key:@"DYYYEnablePure" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"启用首页全屏" key:@"DYYYEnableFullScreen" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"启用屏蔽广告" key:@"DYYYNoAds" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"屏蔽检测更新" key:@"DYYYNoUpdates" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"去青少年弹窗" key:@"DYYYHideTeenMode" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"评论区毛玻璃" key:@"DYYYEnableCommentBlur" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"通知玻璃效果" key:@"DYYYEnableNotificationTransparency" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"毛玻璃透明度" key:@"DYYYCommentBlurTransparent" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
                                                                           [DYYYSettingItem itemWithTitle:@"通知圆角半径" key:@"DYYYNotificationCornerRadius" type:DYYYSettingItemTypeTextField placeholder:@"默认12"],
                                                                           [DYYYSettingItem itemWithTitle:@"时间属地显示" key:@"DYYYEnableArea" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"国外解析账号" key:@"DYYYGeonamesUsername" type:DYYYSettingItemTypeTextField placeholder:@"需填写才能解析国外"],
                                                                           [DYYYSettingItem itemWithTitle:@"时间标签颜色" key:@"DYYYLabelColor" type:DYYYSettingItemTypeTextField placeholder:@"十六进制"],
                                                                           [DYYYSettingItem itemWithTitle:@"属地随机渐变" key:@"DYYYEnableRandomGradient" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"隐藏系统顶栏" key:@"DYYYHideStatusbar" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"关注二次确认" key:@"DYYYFollowTips" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"收藏二次确认" key:@"DYYYCollectTips" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"默认直播画质" key:@"DYYYLiveQuality" type:DYYYSettingItemTypePicker],
                                                                           [DYYYSettingItem itemWithTitle:@"提高视频画质" key:@"DYYYEnableVideoHighestQuality" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"禁用直播PCDN功能" key:@"DYYYDisableLivePCDN" type:DYYYSettingItemTypeSwitch],
                                                                       ]];

      DYYYSettingSection *uiSection = [DYYYSettingSection sectionWithTitle:@"界面设置"
                                                                    items:@[
                                                                        [DYYYSettingItem itemWithTitle:@"设置顶栏透明" key:@"DYYYTopBarTransparent" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
                                                                        [DYYYSettingItem itemWithTitle:@"设置全局透明" key:@"DYYYGlobalTransparency" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
                                                                        [DYYYSettingItem itemWithTitle:@"首页头像透明" key:@"DYYYAvatarViewTransparency" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
                                                                        [DYYYSettingItem itemWithTitle:@"右侧栏缩放度" key:@"DYYYElementScale" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"昵称文案缩放" key:@"DYYYNicknameScale" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"昵称下移距离" key:@"DYYYNicknameVerticalOffset" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"文案下移距离" key:@"DYYYDescriptionVerticalOffset" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"属地上移距离" key:@"DYYYIPLabelVerticalOffset" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"修改底栏高度" key:@"DYYYTabBarHeight" type:DYYYSettingItemTypeTextField placeholder:@"默认为空"],
                                                                        [DYYYSettingItem itemWithTitle:@"设置首页标题" key:@"DYYYIndexTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"设置朋友标题" key:@"DYYYFriendsTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"设置消息标题" key:@"DYYYMsgTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                        [DYYYSettingItem itemWithTitle:@"设置我的标题" key:@"DYYYSelfTitle" type:DYYYSettingItemTypeTextField placeholder:@"不填默认"],
                                                                    ]];

      DYYYSettingSection *hideSection = [DYYYSettingSection sectionWithTitle:@"隐藏设置"
                                                                      items:@[
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏全屏观看" key:@"DYYYHideEntry" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏商城" key:@"DYYYHideShopButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏双列箭头" key:@"DYYYHideDoubleColumnEntry" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏消息" key:@"DYYYHideMessageButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏朋友" key:@"DYYYHideFriendsButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏我的" key:@"DYYYHideMyButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏加号" key:@"DYYYHidePlusButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏热榜" key:@"DYYYHideHotSearch" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏评论" key:@"DYYYHideComment" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏红点" key:@"DYYYHideBottomDot" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底栏背景" key:@"DYYYHideBottomBg" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"精简平板底栏" key:@"DYYYHidePadTabBarElements" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏常用小程序" key:@"DYYYHideSidebarRecentApps" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏常访问的人" key:@"DYYYHideSidebarRecentUsers" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏侧栏红点" key:@"DYYYHideSidebarDot" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏发作品框" key:@"DYYYHidePostView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏头像加号" key:@"DYYYHideLOTAnimationView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"移除头像加号" key:@"DYYYHideFollowPromptView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏点赞数值" key:@"DYYYHideLikeLabel" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏评论数值" key:@"DYYYHideCommentLabel" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏收藏数值" key:@"DYYYHideCollectLabel" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏分享数值" key:@"DYYYHideShareLabel" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏点赞按钮" key:@"DYYYHideLikeButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏评论按钮" key:@"DYYYHideCommentButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏收藏按钮" key:@"DYYYHideCollectButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏头像按钮" key:@"DYYYHideAvatarButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏音乐按钮" key:@"DYYYHideMusicButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏分享按钮" key:@"DYYYHideShareButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏视频定位" key:@"DYYYHideLocation" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏右上搜索" key:@"DYYYHideDiscover" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏相关搜索" key:@"DYYYHideInteractionSearch" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏弹出热搜" key:@"DYYYHideSearchBubble" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏搜索同款" key:@"DYYYHideSearchSame" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏长框搜索" key:@"DYYYHideSearchEntrance" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏进入直播" key:@"DYYYHideEnterLive" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏评论视图" key:@"DYYYHideCommentViews" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏通知提示" key:@"DYYYHidePushBanner" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏消息顶栏红包" key:@"DYYYHideMessageTabRedPacket" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏头像列表" key:@"DYYYHideAvatarList" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏头像气泡" key:@"DYYYHideAvatarBubble" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏左侧边栏" key:@"DYYYHideLeftSideBar" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏吃喝玩乐" key:@"DYYYHideNearbyCapsuleView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏弹幕按钮" key:@"DYYYHideDanmuButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏取消静音" key:@"DYYYHideCancelMute" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏去汽水听" key:@"DYYYHideQuqishuiting" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏共创头像" key:@"DYYYHideGongChuang" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏热点提示" key:@"DYYYHideHotspot" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏推荐提示" key:@"DYYYHideRecommendTips" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏分享提示" key:@"DYYYHideShareContentView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏作者声明" key:@"DYYYHideAntiAddictedNotice" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底部相关" key:@"DYYYHideBottomRelated" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏视频锚点" key:@"DYYYHideFeedAnchorContainer" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏挑战贴纸" key:@"DYYYHideChallengeStickers" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏图文标签" key:@"DYYYHideEditTags" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏校园提示" key:@"DYYYHideTemplateTags" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏作者店铺" key:@"DYYYHideHisShop" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏顶栏横线" key:@"DYYYHideTopBarLine" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏视频合集" key:@"DYYYHideTemplateVideo" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏短剧合集" key:@"DYYYHideTemplatePlaylet" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏动图标签" key:@"DYYYHideLiveGIF" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏笔记标签" key:@"DYYYHideItemTag" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏底部话题" key:@"DYYYHideTemplateGroup" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏相机定位" key:@"DYYYHideCameraLocation" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏视频滑条" key:@"DYYYHideStoryProgressSlide" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏图片滑条" key:@"DYYYHideDotsIndicator" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏分享私信" key:@"DYYYHidePrivateMessages" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏昵称右侧" key:@"DYYYHideRightLabel" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏群聊商店" key:@"DYYYHideGroupShop" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏直播胶囊" key:@"DYYYHideLiveCapsuleView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏关注顶端" key:@"DYYYHideLiveView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏关注直播" key:@"DYYYHideConcernCapsuleView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏同城顶端" key:@"DYYYHideMenuView" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏群直播中" key:@"DYYYHideGroupLiveIndicator" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏聊天底栏" key:@"DYYYHideGroupInputActionBar" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏添加朋友" key:@"DYYYHideButton" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏日常按钮" key:@"DYYYHideFamiliar" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏直播广场" key:@"DYYYHideLivePlayground" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏礼物展馆" key:@"DYYYHideGiftPavilion" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏顶栏红点" key:@"DYYYHideTopBarBadge" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏退出清屏" key:@"DYYYHideLiveRoomClear" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏投屏按钮" key:@"DYYYHideLiveRoomMirroring" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏直播发现" key:@"DYYYHideLiveDiscovery" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏直播点歌" key:@"DYYYHideKTVSongIndicator" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏流量提醒" key:@"DYYYHideCellularAlert" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏红包悬浮" key:@"DYYYHidePendantGroup" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏章节进度" key:@"DYYYHideChapterProgress" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏键盘AI" key:@"DYYYHideKeyboardAI" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏上次看到" key:@"DYYYHidePopover" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏展开渐变" key:@"DYYYHideGradient" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏关闭按钮" key:@"DYYYHideLiveRoomClose" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏横屏按钮" key:@"DYYYHideLiveRoomFullscreen" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏返回按钮" key:@"DYYYHideBack" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏商品信息" key:@"DYYYHideLiveGoodsMsg" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏点赞动画" key:@"DYYYHideLiveLikeAnimation" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏输入扫码" key:@"DYYYHideScancode" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏私信回复" key:@"DYYYHideReply" type:DYYYSettingItemTypeSwitch],
                                                                          [DYYYSettingItem itemWithTitle:@"隐藏暂停相关" key:@"DYYYHidePauseVideoRelatedWord" type:DYYYSettingItemTypeSwitch],
                                                                      ]];

      DYYYSettingSection *removeSection = [DYYYSettingSection sectionWithTitle:@"顶栏移除"
                                                                        items:@[
                                                                            [DYYYSettingItem itemWithTitle:@"移除推荐" key:@"DYYYHideHotContainer" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除关注" key:@"DYYYHideFollow" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除精选" key:@"DYYYHideMediumVideo" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除商城" key:@"DYYYHideMall" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除朋友" key:@"DYYYHideFriend" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除同城" key:@"DYYYHideNearby" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除团购" key:@"DYYYHideGroupon" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除直播" key:@"DYYYHideTabLive" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除热点" key:@"DYYYHidePadHot" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除经验" key:@"DYYYHideHangout" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除短剧" key:@"DYYYHidePlaylet" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除看剧" key:@"DYYYHideCinema" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除少儿" key:@"DYYYHideKidsV2" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除游戏" key:@"DYYYHideGame" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"移除长视频" key:@"DYYYHideMediumVideo" type:DYYYSettingItemTypeSwitch],
                                                                        ]];

      DYYYSettingSection *panelHideSection = [DYYYSettingSection sectionWithTitle:@"隐藏面板"
                                                                           items:@[
                                                                               [DYYYSettingItem itemWithTitle:@"精简长按面板" key:@"DYYYSimplifyLongPressPanel" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏面板项目" key:@"DYYYHidePanelItems" type:DYYYSettingItemTypeTextField placeholder:@"逗号分隔按钮名"],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论分享" key:@"DYYYHideCommentShareToFriends" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论复制" key:@"DYYYHideCommentLongPressCopy" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论保存" key:@"DYYYHideCommentLongPressSaveImage" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论举报" key:@"DYYYHideCommentLongPressReport" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论搜索" key:@"DYYYHideCommentLongPressSearch" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论转发日常" key:@"DYYYHideCommentLongPressDaily" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论视频回复" key:@"DYYYHideCommentLongPressVideoReply" type:DYYYSettingItemTypeSwitch],
                                                                               [DYYYSettingItem itemWithTitle:@"隐藏评论识别图片" key:@"DYYYHideCommentLongPressPictureSearch" type:DYYYSettingItemTypeSwitch],
                                                                           ]];

      DYYYSettingSection *panelSection = [DYYYSettingSection sectionWithTitle:@"面板设置"
                                                                       items:@[
                                                                           [DYYYSettingItem itemWithTitle:@"启用新版长按面板" key:@"DYYYEnableModernPanel" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板玻璃效果" key:@"DYYYLongPressPanelBlur" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板深色模式" key:@"DYYYLongPressPanelDark" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"保存面板玻璃效果" key:@"DYYYEnableSheetBlur" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"面板毛玻璃透明度" key:@"DYYYSheetBlurTransparent" type:DYYYSettingItemTypeTextField placeholder:@"0-1小数"],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板保存视频" key:@"DYYYLongPressSaveVideo" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板保存封面" key:@"DYYYLongPressSaveCover" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板保存音频" key:@"DYYYLongPressSaveAudio" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板保存图片" key:@"DYYYLongPressSaveCurrentImage" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按保存所有图片" key:@"DYYYLongPressSaveAllImages" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板生成视频" key:@"DYYYLongPressCreateVideo" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板复制文案" key:@"DYYYLongPressCopyText" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板复制链接" key:@"DYYYLongPressCopyLink" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板接口解析" key:@"DYYYLongPressApiDownload" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板定时关闭" key:@"DYYYLongPressTimerClose" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板过滤文案" key:@"DYYYLongPressFilterTitle" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按面板过滤作者" key:@"DYYYLongPressFilterUser" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板保存视频" key:@"DYYYDoubleTapDownload" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板保存音频" key:@"DYYYDoubleTapDownloadAudio" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板接口解析" key:@"DYYYDoubleInterfaceDownload" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板制作视频" key:@"DYYYDoubleCreateVideo" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板复制文案" key:@"DYYYDoubleTapCopyDesc" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板打开评论" key:@"DYYYDoubleTapComment" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板点赞视频" key:@"DYYYDoubleTapLike" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板分享视频" key:@"DYYYDoubleTapshowSharePanel" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"双击面板长按面板" key:@"DYYYDoubleTapshowDislikeOnVideo" type:DYYYSettingItemTypeSwitch],
                                                                       ]];

      DYYYSettingSection *funcSection = [DYYYSettingSection sectionWithTitle:@"功能设置"
                                                                       items:@[
                                                                           [DYYYSettingItem itemWithTitle:@"启用双击打开评论" key:@"DYYYEnableDoubleOpenComment" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"启用双击打开菜单" key:@"DYYYEnableDoubleTapMenu" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"启用自动勾选原图" key:@"DYYYAutoSelectOriginalPhoto" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"资料默认进入作品" key:@"DYYYDefaultEnterWorks" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"禁用自动进入直播" key:@"DYYYDisableAutoEnterLive" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"左侧边栏快捷入口" key:@"DYYYEntrance" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"接口解析保存媒体" key:@"DYYYInterfaceDownload" type:DYYYSettingItemTypeTextField placeholder:@"不填关闭"],
                                                                           [DYYYSettingItem itemWithTitle:@"接口显示清晰选项" key:@"DYYYShowAllVideoQuality" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"移除评论实况水印" key:@"DYYYCommentLivePhotoNotWaterMark" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"移除评论图片水印" key:@"DYYYCommentNotWaterMark" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"禁用点击首页刷新" key:@"DYYYDisableHomeRefresh" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"禁用双击视频点赞" key:@"DYYYDisableDoubleTapLike" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"启用保存他人头像" key:@"DYYYEnableSaveAvatar" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"保存评论区表情包" key:@"DYYYForceDownloadEmotion" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"保存预览页表情包" key:@"DYYYForceDownloadPreviewEmotion" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"保存聊天页表情包" key:@"DYYYForceDownloadIMEmotion" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按评论复制评论" key:@"DYYYCommentCopyText" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按简介复制简介" key:@"DYYYBioCopyText" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"长按文案复制文案" key:@"DYYYLongPressCopyTextEnabled" type:DYYYSettingItemTypeSwitch],
                                                                           [DYYYSettingItem itemWithTitle:@"下载完成震动反馈" key:@"DYYYHapticFeedbackEnabled" type:DYYYSettingItemTypeSwitch],
                                                                       ]];

      DYYYSettingSection *floatSection = [DYYYSettingSection sectionWithTitle:@"悬浮按钮"
                                                                        items:@[
                                                                            [DYYYSettingItem itemWithTitle:@"启用快捷倍速按钮" key:@"DYYYEnableFloatSpeedButton" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"快捷倍速数值设置" key:@"DYYYSpeedSettings" type:DYYYSettingItemTypeTextField placeholder:@"逗号分隔"],
                                                                            [DYYYSettingItem itemWithTitle:@"自动恢复默认倍速" key:@"DYYYAutoRestoreSpeed" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"倍速按钮显示后缀" key:@"DYYYSpeedButtonShowX" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"快捷倍速按钮大小" key:@"DYYYSpeedButtonSize" type:DYYYSettingItemTypeTextField placeholder:@"默认32"],
                                                                            [DYYYSettingItem itemWithTitle:@"启用一键清屏按钮" key:@"DYYYEnableFloatClearButton" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"快捷清屏按钮大小" key:@"DYYYEnableFloatClearButtonSize" type:DYYYSettingItemTypeTextField placeholder:@"默认40"],
                                                                            [DYYYSettingItem itemWithTitle:@"清屏隐藏弹幕" key:@"DYYYHideDanmaku" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"清屏移除时间进度" key:@"DYYYRemoveTimeProgress" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"清屏隐藏时间进度" key:@"DYYYHideTimeProgress" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"清屏隐藏滑条" key:@"DYYYHideSlider" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"清屏隐藏底栏" key:@"DYYYHideTabBar" type:DYYYSettingItemTypeSwitch],
                                                                            [DYYYSettingItem itemWithTitle:@"清屏隐藏倍速" key:@"DYYYHideSpeed" type:DYYYSettingItemTypeSwitch],
                                                                        ]];

      gDYYYSettingTabs = @[
          [DYYYSettingTab tabWithTitle:@"抖音优化" sections:@[ basicSection, uiSection, hideSection, removeSection ]],
          [DYYYSettingTab tabWithTitle:@"扩展功能" sections:@[ panelHideSection, panelSection, funcSection, floatSection ]],
      ];
    });

    return gDYYYSettingTabs;
}

+ (NSArray *)optionsForKey:(NSString *)key {
    if ([key isEqualToString:@"DYYYDefaultSpeed"] || [key isEqualToString:@"DYYYLongPressSpeed"]) {
        // 倍速选项
        return @[ @0.75, @1.0, @1.25, @1.5, @2.0, @2.5, @3.0 ];
    } else if ([key isEqualToString:@"DYYYLiveQuality"]) {
        // 直播清晰度选项
        return @[ @"蓝光帧彩", @"蓝光", @"超清", @"高清", @"标清", @"自动" ];
    }
    return @[];
}

+ (NSString *)displayValueForKey:(NSString *)key value:(id)value {
    if ([key isEqualToString:@"DYYYDefaultSpeed"] || [key isEqualToString:@"DYYYLongPressSpeed"]) {
        // 倍速显示格式
        return [NSString stringWithFormat:@"%.2f", [value floatValue]];
    } else if ([key isEqualToString:@"DYYYLiveQuality"]) {
        // 直播清晰度直接显示
        return value ? [NSString stringWithFormat:@"%@", value] : @"自动";
    }
    return value ? [NSString stringWithFormat:@"%@", value] : @"";
}

+ (id)defaultValueForKey:(NSString *)key {
    if ([key isEqualToString:@"DYYYDefaultSpeed"] || [key isEqualToString:@"DYYYLongPressSpeed"]) {
        return @1.0;
    } else if ([key isEqualToString:@"DYYYLiveQuality"]) {
        return @"自动";
    }
    return nil;
}

+ (id)currentValueForKey:(NSString *)key {
    id value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (!value) {
        value = [self defaultValueForKey:key];
    }
    return value;
}

@end

#pragma mark - 二级详情页单元格

typedef NS_ENUM(NSInteger, DYYYSettingCellPosition) {
    DYYYSettingCellPositionSingle,
    DYYYSettingCellPositionTop,
    DYYYSettingCellPositionMiddle,
    DYYYSettingCellPositionBottom
};

@interface DYYYSettingOptionCell : UITableViewCell

@property(nonatomic, copy, nullable) void (^onSwitchChanged)(BOOL isOn);
@property(nonatomic, copy, nullable) void (^onTextChanged)(NSString *text);
@property(nonatomic, copy, nullable) void (^onTextBeginEditing)(void);

- (void)configureWithItem:(DYYYSettingItem *)item position:(DYYYSettingCellPosition)position;

@end

@interface DYYYSettingOptionCell ()

@property(nonatomic, strong) DYYYGlassCardView *cardView;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UIView *separatorView;
@property(nonatomic, strong) UISwitch *switchView;
@property(nonatomic, strong) UITextField *textField;
@property(nonatomic, strong) UILabel *valueLabel;
@property(nonatomic, strong) DYYYChevronTriangleView *valueChevron;
@property(nonatomic, strong) NSLayoutConstraint *titleToSwitchConstraint;
@property(nonatomic, strong) NSLayoutConstraint *titleToFieldConstraint;
@property(nonatomic, strong) NSLayoutConstraint *titleToValueConstraint;
@property(nonatomic, copy, nullable) NSString *currentKey;

@end

@implementation DYYYSettingOptionCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        self.backgroundColor = [UIColor clearColor];
        self.contentView.backgroundColor = [UIColor clearColor];
        self.selectionStyle = UITableViewCellSelectionStyleNone;

        _cardView = [[DYYYGlassCardView alloc] initWithFrame:CGRectZero];
        _cardView.userInteractionEnabled = NO;
        _cardView.highlightStrength = 0.85;
        _cardView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_cardView];

        _titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _titleLabel.font = [UIFont systemFontOfSize:15.5 weight:UIFontWeightMedium];
        _titleLabel.textColor = [DYYYPanelTheme textPrimary];
        _titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_titleLabel];

        _separatorView = [[UIView alloc] initWithFrame:CGRectZero];
        _separatorView.backgroundColor = [DYYYPanelTheme separator];
        _separatorView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.contentView addSubview:_separatorView];

        _switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
        _switchView.onTintColor = [DYYYPanelTheme accent];
        _switchView.translatesAutoresizingMaskIntoConstraints = NO;
        _switchView.hidden = YES;
        [_switchView addTarget:self action:@selector(switchValueChanged:) forControlEvents:UIControlEventValueChanged];
        [self.contentView addSubview:_switchView];

        _textField = [[UITextField alloc] initWithFrame:CGRectZero];
        _textField.borderStyle = UITextBorderStyleNone;
        _textField.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.58];
        _textField.layer.cornerRadius = 10.0;
        _textField.layer.cornerCurve = kCACornerCurveContinuous;
        _textField.layer.borderWidth = 0.8;
        _textField.layer.borderColor = [UIColor colorWithWhite:1.0 alpha:0.72].CGColor;
        _textField.font = [UIFont systemFontOfSize:14.0 weight:UIFontWeightMedium];
        _textField.textColor = [DYYYPanelTheme textPrimary];
        _textField.tintColor = [DYYYPanelTheme accent];
        _textField.textAlignment = NSTextAlignmentRight;
        _textField.returnKeyType = UIReturnKeyDone;
        _textField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 32)];
        _textField.leftViewMode = UITextFieldViewModeAlways;
        _textField.rightView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 10, 32)];
        _textField.rightViewMode = UITextFieldViewModeAlways;
        _textField.translatesAutoresizingMaskIntoConstraints = NO;
        _textField.hidden = YES;
        [_textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
        [_textField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingDidEnd];
        [_textField addTarget:self action:@selector(textFieldBeganEditing:) forControlEvents:UIControlEventEditingDidBegin];
        [self.contentView addSubview:_textField];

        _valueLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _valueLabel.font = [UIFont systemFontOfSize:15.0 weight:UIFontWeightMedium];
        _valueLabel.textColor = [DYYYPanelTheme textSecondary];
        _valueLabel.textAlignment = NSTextAlignmentRight;
        _valueLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _valueLabel.hidden = YES;
        [self.contentView addSubview:_valueLabel];

        _valueChevron = [[DYYYChevronTriangleView alloc] initWithFrame:CGRectZero];
        _valueChevron.fillColor = [DYYYPanelTheme textPrimary];
        _valueChevron.alpha = 0.35;
        _valueChevron.translatesAutoresizingMaskIntoConstraints = NO;
        _valueChevron.hidden = YES;
        [self.contentView addSubview:_valueChevron];

        [NSLayoutConstraint activateConstraints:@[
            [_cardView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor],
            [_cardView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_cardView.topAnchor constraintEqualToAnchor:self.contentView.topAnchor],
            [_cardView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],

            [_titleLabel.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
            [_titleLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

            [_switchView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-16.0],
            [_switchView.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

            [_textField.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-14.0],
            [_textField.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_textField.widthAnchor constraintEqualToConstant:138.0],
            [_textField.heightAnchor constraintEqualToConstant:32.0],

            [_valueChevron.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor constant:-18.0],
            [_valueChevron.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],
            [_valueChevron.widthAnchor constraintEqualToConstant:7.0],
            [_valueChevron.heightAnchor constraintEqualToConstant:12.0],

            [_valueLabel.trailingAnchor constraintEqualToAnchor:_valueChevron.leadingAnchor constant:-8.0],
            [_valueLabel.centerYAnchor constraintEqualToAnchor:self.contentView.centerYAnchor],

            [_separatorView.leadingAnchor constraintEqualToAnchor:self.contentView.leadingAnchor constant:18.0],
            [_separatorView.trailingAnchor constraintEqualToAnchor:self.contentView.trailingAnchor],
            [_separatorView.bottomAnchor constraintEqualToAnchor:self.contentView.bottomAnchor],
            [_separatorView.heightAnchor constraintEqualToConstant:0.5],
        ]];

        [_titleLabel setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];

        // 不同控件类型的标题右侧约束，按需启用，避免隐藏控件挤压标题
        _titleToSwitchConstraint = [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_switchView.leadingAnchor constant:-10.0];
        _titleToFieldConstraint = [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_textField.leadingAnchor constant:-10.0];
        _titleToValueConstraint = [_titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:_valueLabel.leadingAnchor constant:-10.0];
    }
    return self;
}

- (void)prepareForReuse {
    [super prepareForReuse];
    self.onSwitchChanged = nil;
    self.onTextChanged = nil;
    self.onTextBeginEditing = nil;
    [self.textField resignFirstResponder];
    self.textField.text = nil;
}

- (void)configureWithItem:(DYYYSettingItem *)item position:(DYYYSettingCellPosition)position {
    self.currentKey = item.key;
    self.titleLabel.text = item.title;

    CGFloat radius = 18.0;
    self.cardView.cornerRadius = radius;
    switch (position) {
        case DYYYSettingCellPositionSingle:
            self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner | kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            break;
        case DYYYSettingCellPositionTop:
            self.cardView.layer.maskedCorners = kCALayerMinXMinYCorner | kCALayerMaxXMinYCorner;
            break;
        case DYYYSettingCellPositionBottom:
            self.cardView.layer.maskedCorners = kCALayerMinXMaxYCorner | kCALayerMaxXMaxYCorner;
            break;
        default:
            self.cardView.layer.maskedCorners = 0;
            break;
    }

    self.separatorView.hidden = (position == DYYYSettingCellPositionBottom || position == DYYYSettingCellPositionSingle);

    self.switchView.hidden = YES;
    self.textField.hidden = YES;
    self.valueLabel.hidden = YES;
    self.valueChevron.hidden = YES;

    [NSLayoutConstraint deactivateConstraints:@[ self.titleToSwitchConstraint, self.titleToFieldConstraint, self.titleToValueConstraint ]];

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];

    if (item.type == DYYYSettingItemTypeSwitch) {
        self.switchView.hidden = NO;
        self.titleToSwitchConstraint.active = YES;
        [self.switchView setOn:[defaults boolForKey:item.key] animated:NO];
    } else if (item.type == DYYYSettingItemTypeTextField) {
        self.textField.hidden = NO;
        self.titleToFieldConstraint.active = YES;
        self.textField.text = [defaults objectForKey:item.key];
        NSString *placeholder = item.placeholder ?: @"";
        self.textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
                                                                               attributes:@{
                                                                                   NSForegroundColorAttributeName : [DYYYPanelTheme textTertiary],
                                                                                   NSFontAttributeName : [UIFont systemFontOfSize:14.0 weight:UIFontWeightRegular],
                                                                               }];
    } else if (item.type == DYYYSettingItemTypePicker) {
        self.valueLabel.hidden = NO;
        self.valueChevron.hidden = NO;
        self.titleToValueConstraint.active = YES;
        id currentValue = [DYYYSettingStore currentValueForKey:item.key];
        self.valueLabel.text = [DYYYSettingStore displayValueForKey:item.key value:currentValue];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated {
    [super setHighlighted:highlighted animated:animated];

    [UIView animateWithDuration:0.16
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.cardView.alpha = highlighted ? 0.72 : 1.0;
                     }
                     completion:nil];
}

- (void)switchValueChanged:(UISwitch *)sender {
    if (self.onSwitchChanged) {
        self.onSwitchChanged(sender.isOn);
    }
}

- (void)textFieldBeganEditing:(UITextField *)textField {
    if (self.onTextBeginEditing) {
        self.onTextBeginEditing();
    }
}

- (void)textFieldChanged:(UITextField *)textField {
    if (self.onTextChanged) {
        self.onTextChanged(textField.text ?: @"");
    }
}

@end

#pragma mark - 二级详情页

@interface DYYYSettingDetailViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

- (instancetype)initWithSectionTitle:(NSString *)title items:(NSArray<DYYYSettingItem *> *)items;

/// 点击返回按钮时回调（由父面板负责移除本页）
@property(nonatomic, copy, nullable) void (^onClose)(void);

@property(nonatomic, copy) NSString *sectionTitle;
@property(nonatomic, copy) NSArray<DYYYSettingItem *> *items;
@property(nonatomic, strong) DYYYGlassBackgroundView *backgroundView;
@property(nonatomic, strong) UIView *headerBar;
@property(nonatomic, strong) DYYYCircleGlassButton *backButton;
@property(nonatomic, strong) UILabel *headerTitleLabel;
@property(nonatomic, strong) UILabel *headerSubtitleLabel;
@property(nonatomic, strong) UITableView *tableView;
@property(nonatomic, strong, nullable) NSIndexPath *activeIndexPath;

- (void)keyboardWillChangeFrame:(NSNotification *)notification;

@end

@implementation DYYYSettingDetailViewController

- (instancetype)initWithSectionTitle:(NSString *)title items:(NSArray<DYYYSettingItem *> *)items {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        _sectionTitle = [title copy];
        _items = [items copy];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    self.view.backgroundColor = [UIColor clearColor];

    self.backgroundView = [[DYYYGlassBackgroundView alloc] initWithFrame:CGRectZero];
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundView];

    self.headerBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.headerBar.backgroundColor = [UIColor clearColor];
    self.headerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerBar];

    self.backButton = [[DYYYCircleGlassButton alloc] initWithSystemImageName:@"chevron.left" diameter:40.0];
    self.backButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.backButton addTarget:self action:@selector(backTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.backButton];

    self.headerTitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.headerTitleLabel.text = self.sectionTitle;
    self.headerTitleLabel.font = [UIFont systemFontOfSize:19.0 weight:UIFontWeightSemibold];
    self.headerTitleLabel.textColor = [DYYYPanelTheme textPrimary];
    self.headerTitleLabel.textAlignment = NSTextAlignmentCenter;
    self.headerTitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerBar addSubview:self.headerTitleLabel];

    self.headerSubtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.headerSubtitleLabel.text = [NSString stringWithFormat:@"%lu 项设置", (unsigned long)self.items.count];
    self.headerSubtitleLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightMedium];
    self.headerSubtitleLabel.textColor = [DYYYPanelTheme textTertiary];
    self.headerSubtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.headerSubtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.headerBar addSubview:self.headerSubtitleLabel];

    self.tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.showsVerticalScrollIndicator = YES;
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    self.tableView.rowHeight = 58.0;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    self.tableView.contentInset = UIEdgeInsetsMake(10, 0, 48, 0);
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.tableView];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backgroundView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.headerBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerBar.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:6.0],
        [self.headerBar.heightAnchor constraintEqualToConstant:58.0],

        [self.backButton.leadingAnchor constraintEqualToAnchor:self.headerBar.leadingAnchor constant:16.0],
        [self.backButton.centerYAnchor constraintEqualToAnchor:self.headerBar.centerYAnchor],
        [self.backButton.widthAnchor constraintEqualToConstant:40.0],
        [self.backButton.heightAnchor constraintEqualToConstant:40.0],

        [self.headerTitleLabel.centerXAnchor constraintEqualToAnchor:self.headerBar.centerXAnchor],
        [self.headerTitleLabel.centerYAnchor constraintEqualToAnchor:self.headerBar.centerYAnchor constant:-7.0],

        [self.headerSubtitleLabel.centerXAnchor constraintEqualToAnchor:self.headerBar.centerXAnchor],
        [self.headerSubtitleLabel.topAnchor constraintEqualToAnchor:self.headerTitleLabel.bottomAnchor constant:2.0],

        [self.tableView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor constant:16.0],
        [self.tableView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor constant:-16.0],
        [self.tableView.topAnchor constraintEqualToAnchor:self.headerBar.bottomAnchor],
        [self.tableView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillChangeFrame:) name:UIKeyboardWillChangeFrameNotification object:nil];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - 键盘

- (void)keyboardWillChangeFrame:(NSNotification *)notification {
    NSDictionary *userInfo = notification.userInfo;
    NSTimeInterval duration = [userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect endFrame = [userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    CGRect localFrame = [self.view convertRect:endFrame fromView:nil];
    CGFloat overlap = MAX(0.0, CGRectGetMaxY(self.view.bounds) - CGRectGetMinY(localFrame));

    UIEdgeInsets inset = UIEdgeInsetsMake(10, 0, 48.0 + overlap, 0);
    [UIView animateWithDuration:duration
                          delay:0
                        options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                     animations:^{
                       self.tableView.contentInset = inset;
                       self.tableView.scrollIndicatorInsets = inset;
                     }
                     completion:nil];

    if (overlap > 0 && self.activeIndexPath) {
        [self.tableView scrollToRowAtIndexPath:self.activeIndexPath atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDarkContent;
}

#pragma mark - 交互

- (void)backTapped {
    if (self.onClose) {
        self.onClose();
    }
}

- (void)showOptionsForItem:(DYYYSettingItem *)item indexPath:(NSIndexPath *)indexPath {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"选择%@", item.title]
                                                                   message:nil
                                                            preferredStyle:UIAlertControllerStyleActionSheet];

    NSArray *options = [DYYYSettingStore optionsForKey:item.key];
    for (id option in options) {
        NSString *title = [DYYYSettingStore displayValueForKey:item.key value:option];
        UIAlertAction *action = [UIAlertAction actionWithTitle:title
                                                        style:UIAlertActionStyleDefault
                                                      handler:^(UIAlertAction *_Nonnull action) {
                                                        [[NSUserDefaults standardUserDefaults] setObject:option forKey:item.key];
                                                        [self.tableView reloadRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationFade];
                                                      }];
        [alert addAction:action];
    }

    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];

    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UITableViewCell *selectedCell = [self.tableView cellForRowAtIndexPath:indexPath];
        alert.popoverPresentationController.sourceView = selectedCell;
        alert.popoverPresentationController.sourceRect = selectedCell.bounds;
    }

    [self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *const reuseIdentifier = @"DYYYSettingOptionCell";
    DYYYSettingOptionCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier];
    if (!cell) {
        cell = [[DYYYSettingOptionCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:reuseIdentifier];
    }

    DYYYSettingItem *item = self.items[indexPath.row];
    DYYYSettingCellPosition position = DYYYSettingCellPositionMiddle;
    if (self.items.count == 1) {
        position = DYYYSettingCellPositionSingle;
    } else if (indexPath.row == 0) {
        position = DYYYSettingCellPositionTop;
    } else if (indexPath.row == (NSInteger)self.items.count - 1) {
        position = DYYYSettingCellPositionBottom;
    }

    [cell configureWithItem:item position:position];

    cell.onSwitchChanged = ^(BOOL isOn) {
      [[NSUserDefaults standardUserDefaults] setBool:isOn forKey:item.key];
    };
    cell.onTextChanged = ^(NSString *text) {
      [[NSUserDefaults standardUserDefaults] setObject:text forKey:item.key];
    };
    __weak typeof(self) weakSelf = self;
    cell.onTextBeginEditing = ^{
      weakSelf.activeIndexPath = indexPath;
    };

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    DYYYSettingItem *item = self.items[indexPath.row];
    if (item.type == DYYYSettingItemTypePicker) {
        [self showOptionsForItem:item indexPath:indexPath];
    }
}

@end

#pragma mark - 主面板

@interface DYYYSettingViewController ()

@property(nonatomic, strong) DYYYGlassBackgroundView *backgroundView;
@property(nonatomic, strong) UIView *headerBar;
@property(nonatomic, strong) DYYYCircleGlassButton *closeButton;
@property(nonatomic, strong) DYYYCircleGlassButton *aboutButton;
@property(nonatomic, strong) UIScrollView *scrollView;
@property(nonatomic, strong) UIStackView *contentStack;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *subtitleLabel;
@property(nonatomic, strong) DYYYPageDotsView *pageDots;
@property(nonatomic, strong) DYYYSegmentedTabs *tabBar;
@property(nonatomic, strong) UIStackView *rowStack;
@property(nonatomic, strong) UILabel *footerLabel;
@property(nonatomic, copy) NSArray<DYYYSettingTab *> *tabs;
@property(nonatomic, assign) NSInteger currentTabIndex;
@property(nonatomic, assign) BOOL isAgreementShown;

- (void)setupBackground;
- (void)setupHeaderBar;
- (void)setupScrollContent;
- (void)applyTab:(NSInteger)index animated:(BOOL)animated;
- (void)rebuildRowsAnimated:(BOOL)animated;
- (void)presentDetailViewController:(DYYYSettingDetailViewController *)detail;
- (void)dismissDetailViewController:(DYYYSettingDetailViewController *)detail;
- (void)closeTapped;
- (void)aboutTapped;
- (void)checkFirstLaunch;
- (void)showAgreementAlert;

@end

@implementation DYYYSettingViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // 面板统一采用浅色轻玻璃外观，避免抖音深色背景导致对比度混乱
    self.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
    self.view.backgroundColor = [UIColor clearColor];

    self.isAgreementShown = NO;
    self.currentTabIndex = 0;

    [DYYYSettingStore prepareDefaultValues];
    self.tabs = [DYYYSettingStore tabs];

    [self setupBackground];
    [self setupHeaderBar];
    [self setupScrollContent];
    [self applyTab:0 animated:NO];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // 注意：这里不要再做整屏淡入。面板弹出动画结束时内容已经可见，
    // 若此时把 alpha 打到 0 再淡入，会出现「内容闪一下」的观感。
    if (!self.isAgreementShown) {
        [self checkFirstLaunch];
        self.isAgreementShown = YES;
    }
}

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleDarkContent;
}

#pragma mark - 布局搭建

- (void)setupBackground {
    self.backgroundView = [[DYYYGlassBackgroundView alloc] initWithFrame:CGRectZero];
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.backgroundView];

    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.backgroundView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
    ]];
}

- (void)setupHeaderBar {
    self.headerBar = [[UIView alloc] initWithFrame:CGRectZero];
    self.headerBar.backgroundColor = [UIColor clearColor];
    self.headerBar.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.headerBar];

    self.closeButton = [[DYYYCircleGlassButton alloc] initWithSystemImageName:@"xmark" diameter:42.0];
    self.closeButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.closeButton.accessibilityLabel = @"关闭";
    [self.closeButton addTarget:self action:@selector(closeTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.closeButton];

    self.aboutButton = [[DYYYCircleGlassButton alloc] initWithSystemImageName:@"info" diameter:42.0];
    self.aboutButton.translatesAutoresizingMaskIntoConstraints = NO;
    self.aboutButton.accessibilityLabel = @"关于";
    [self.aboutButton addTarget:self action:@selector(aboutTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.headerBar addSubview:self.aboutButton];

    UILayoutGuide *safeArea = self.view.safeAreaLayoutGuide;
    [NSLayoutConstraint activateConstraints:@[
        [self.headerBar.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.headerBar.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.headerBar.topAnchor constraintEqualToAnchor:safeArea.topAnchor constant:4.0],
        [self.headerBar.heightAnchor constraintEqualToConstant:48.0],

        [self.closeButton.leadingAnchor constraintEqualToAnchor:self.headerBar.leadingAnchor constant:16.0],
        [self.closeButton.centerYAnchor constraintEqualToAnchor:self.headerBar.centerYAnchor],
        [self.closeButton.widthAnchor constraintEqualToConstant:42.0],
        [self.closeButton.heightAnchor constraintEqualToConstant:42.0],

        [self.aboutButton.trailingAnchor constraintEqualToAnchor:self.headerBar.trailingAnchor constant:-16.0],
        [self.aboutButton.centerYAnchor constraintEqualToAnchor:self.headerBar.centerYAnchor],
        [self.aboutButton.widthAnchor constraintEqualToConstant:42.0],
        [self.aboutButton.heightAnchor constraintEqualToConstant:42.0],
    ]];
}

- (void)setupScrollContent {
    self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.alwaysBounceVertical = YES;
    self.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.scrollView];

    self.contentStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.contentStack.axis = UILayoutConstraintAxisVertical;
    self.contentStack.alignment = UIStackViewAlignmentFill;
    self.contentStack.spacing = 16.0;
    self.contentStack.layoutMarginsRelativeArrangement = YES;
    self.contentStack.layoutMargins = UIEdgeInsetsMake(6, 16, 44, 16);
    self.contentStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.scrollView addSubview:self.contentStack];

    // 标题区（替代设计稿中的资料卡，头像部分不做实现）
    UIView *titleContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.titleLabel.text = DYYY_SETTINGS_NAME;
    self.titleLabel.font = [UIFont systemFontOfSize:31.0 weight:UIFontWeightBold];
    self.titleLabel.textColor = [DYYYPanelTheme textPrimary];
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleContainer addSubview:self.titleLabel];

    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.subtitleLabel.text = [NSString stringWithFormat:@"抖音界面调整 · 版本 %@", DYYY_VERSION];
    self.subtitleLabel.font = [UIFont systemFontOfSize:13.0 weight:UIFontWeightMedium];
    self.subtitleLabel.textColor = [DYYYPanelTheme textSecondary];
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [titleContainer addSubview:self.subtitleLabel];

    [NSLayoutConstraint activateConstraints:@[
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:titleContainer.leadingAnchor constant:4.0],
        [self.titleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:titleContainer.trailingAnchor constant:-4.0],
        [self.titleLabel.topAnchor constraintEqualToAnchor:titleContainer.topAnchor],
        [self.titleLabel.bottomAnchor constraintEqualToAnchor:self.subtitleLabel.topAnchor constant:-4.0],

        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.titleLabel.leadingAnchor],
        [self.subtitleLabel.trailingAnchor constraintLessThanOrEqualToAnchor:titleContainer.trailingAnchor constant:-4.0],
        [self.subtitleLabel.bottomAnchor constraintEqualToAnchor:titleContainer.bottomAnchor],
    ]];

    // 页码点
    UIView *dotsContainer = [[UIView alloc] initWithFrame:CGRectZero];
    self.pageDots = [[DYYYPageDotsView alloc] initWithFrame:CGRectZero];
    self.pageDots.numberOfPages = (NSInteger)self.tabs.count;
    self.pageDots.translatesAutoresizingMaskIntoConstraints = NO;
    [dotsContainer addSubview:self.pageDots];
    [NSLayoutConstraint activateConstraints:@[
        [dotsContainer.heightAnchor constraintEqualToConstant:16.0],
        [self.pageDots.centerXAnchor constraintEqualToAnchor:dotsContainer.centerXAnchor],
        [self.pageDots.centerYAnchor constraintEqualToAnchor:dotsContainer.centerYAnchor],
        [self.pageDots.heightAnchor constraintEqualToConstant:16.0],
        [self.pageDots.widthAnchor constraintEqualToConstant:MAX((CGFloat)self.tabs.count, 1.0) * 20.0],
    ]];

    // 分段标签
    NSMutableArray<NSString *> *tabTitles = [NSMutableArray array];
    for (DYYYSettingTab *tab in self.tabs) {
        [tabTitles addObject:tab.title];
    }
    self.tabBar = [[DYYYSegmentedTabs alloc] initWithTitles:tabTitles];
    self.tabBar.translatesAutoresizingMaskIntoConstraints = NO;
    __weak typeof(self) weakSelf = self;
    self.tabBar.onChange = ^(NSInteger index) {
      [weakSelf applyTab:index animated:YES];
    };
    [self.tabBar.heightAnchor constraintEqualToConstant:48.0].active = YES;

    // 区块卡片行
    self.rowStack = [[UIStackView alloc] initWithFrame:CGRectZero];
    self.rowStack.axis = UILayoutConstraintAxisVertical;
    self.rowStack.alignment = UIStackViewAlignmentFill;
    self.rowStack.spacing = 14.0;

    // 底部信息
    self.footerLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.footerLabel.text = [NSString stringWithFormat:@"Developer By @huamidev\nVersion: %@ (%@)", DYYY_VERSION, @"260104"];
    self.footerLabel.textAlignment = NSTextAlignmentCenter;
    self.footerLabel.numberOfLines = 2;
    self.footerLabel.font = [UIFont systemFontOfSize:11.5 weight:UIFontWeightRegular];
    self.footerLabel.textColor = [DYYYPanelTheme textTertiary];

    [self.contentStack addArrangedSubview:titleContainer];
    [self.contentStack addArrangedSubview:dotsContainer];
    [self.contentStack addArrangedSubview:self.tabBar];
    [self.contentStack addArrangedSubview:self.rowStack];
    [self.contentStack addArrangedSubview:self.footerLabel];

    [self.contentStack setCustomSpacing:18.0 afterView:titleContainer];
    [self.contentStack setCustomSpacing:20.0 afterView:dotsContainer];
    [self.contentStack setCustomSpacing:18.0 afterView:self.tabBar];
    [self.contentStack setCustomSpacing:26.0 afterView:self.rowStack];

    [NSLayoutConstraint activateConstraints:@[
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [self.scrollView.topAnchor constraintEqualToAnchor:self.headerBar.bottomAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],

        [self.contentStack.leadingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.leadingAnchor],
        [self.contentStack.trailingAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.trailingAnchor],
        [self.contentStack.topAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.topAnchor],
        [self.contentStack.bottomAnchor constraintEqualToAnchor:self.scrollView.contentLayoutGuide.bottomAnchor],
        [self.contentStack.widthAnchor constraintEqualToAnchor:self.scrollView.frameLayoutGuide.widthAnchor],
    ]];
}

#pragma mark - 内容刷新

- (void)applyTab:(NSInteger)index animated:(BOOL)animated {
    if (index < 0 || index >= (NSInteger)self.tabs.count) {
        return;
    }

    self.currentTabIndex = index;
    self.pageDots.currentPage = index;
    [self rebuildRowsAnimated:animated];
}

- (void)rebuildRowsAnimated:(BOOL)animated {
    for (UIView *view in self.rowStack.arrangedSubviews) {
        [self.rowStack removeArrangedSubview:view];
        [view removeFromSuperview];
    }

    DYYYSettingTab *tab = self.tabs[self.currentTabIndex];
    NSInteger index = 0;
    for (DYYYSettingSection *section in tab.sections) {
        DYYYSettingRowView *row = [[DYYYSettingRowView alloc] initWithTitle:section.title detail:[NSString stringWithFormat:@"%lu 项", (unsigned long)section.items.count]];
        row.tag = index;
        [row addTarget:self action:@selector(sectionRowTapped:) forControlEvents:UIControlEventTouchUpInside];
        [row.heightAnchor constraintEqualToConstant:70.0].active = YES;
        [self.rowStack addArrangedSubview:row];

        if (animated) {
            row.alpha = 0.0;
            row.transform = CGAffineTransformMakeTranslation(0, 18);
            [UIView animateWithDuration:0.45
                                  delay:0.04 * index
                 usingSpringWithDamping:0.88
                  initialSpringVelocity:0.4
                                options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                             animations:^{
                               row.alpha = 1.0;
                               row.transform = CGAffineTransformIdentity;
                             }
                             completion:nil];
        }
        index++;
    }

    [self.view layoutIfNeeded];
}

#pragma mark - 交互

- (void)sectionRowTapped:(DYYYSettingRowView *)row {
    NSArray<DYYYSettingSection *> *sections = self.tabs[self.currentTabIndex].sections;
    if (row.tag < 0 || row.tag >= (NSInteger)sections.count) {
        return;
    }

    DYYYSettingSection *section = sections[row.tag];

    UIImpactFeedbackGenerator *feedback = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
    [feedback impactOccurred];

    DYYYSettingDetailViewController *detail = [[DYYYSettingDetailViewController alloc] initWithSectionTitle:section.title items:section.items];
    [self presentDetailViewController:detail];
}

/// 二级页以子控制器方式滑入，保留面板的玻璃背景（不使用导航栏，避免背景失焦）
- (void)presentDetailViewController:(DYYYSettingDetailViewController *)detail {
    __weak typeof(self) weakSelf = self;
    __weak DYYYSettingDetailViewController *weakDetail = detail;
    detail.onClose = ^{
      DYYYSettingDetailViewController *strongDetail = weakDetail;
      if (strongDetail) {
          [weakSelf dismissDetailViewController:strongDetail];
      }
    };

    [self addChildViewController:detail];
    detail.view.frame = self.view.bounds;
    detail.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    detail.view.alpha = 0.0;
    detail.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(self.view.bounds) * 0.35, 0);
    [self.view addSubview:detail.view];
    [detail didMoveToParentViewController:self];

    [UIView animateWithDuration:0.38
                          delay:0
         usingSpringWithDamping:0.92
          initialSpringVelocity:0.35
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                       detail.view.alpha = 1.0;
                       detail.view.transform = CGAffineTransformIdentity;
                     }
                     completion:nil];
}

- (void)dismissDetailViewController:(DYYYSettingDetailViewController *)detail {
    [detail willMoveToParentViewController:nil];

    [UIView animateWithDuration:0.26
                          delay:0
                        options:UIViewAnimationOptionAllowUserInteraction | UIViewAnimationOptionBeginFromCurrentState
                     animations:^{
                       detail.view.alpha = 0.0;
                       detail.view.transform = CGAffineTransformMakeTranslation(CGRectGetWidth(self.view.bounds) * 0.28, 0);
                     }
                     completion:^(BOOL finished) {
                       [detail.view removeFromSuperview];
                       [detail removeFromParentViewController];
                     }];
}

- (void)closeTapped {
    [self.view endEditing:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)aboutTapped {
    NSString *message = [NSString stringWithFormat:@"当前版本：%@\n\n两指长按屏幕即可打开本面板\n本插件为开源项目，仅供学习交流使用\n\nDeveloper: @huamidev\nGitHub: huami1314/DYYY", DYYY_VERSION];
    DYYYAboutDialogView *dialog = [[DYYYAboutDialogView alloc] initWithTitle:DYYY_SETTINGS_NAME message:message];
    [dialog show];
}

#pragma mark - First Launch Agreement

- (void)checkFirstLaunch {
    BOOL hasAgreed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYUserAgreementAccepted"];

    if (!hasAgreed) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self showAgreementAlert];
        });
    }
}

- (void)showAgreementAlert {
    UIAlertController *alertController =
        [UIAlertController alertControllerWithTitle:@"用户协议"
                                            message:@"本插件为开源项目\n仅供学习交流用途\n如有侵权请联系, GitHub 仓库：huami1314/DYYY\n请遵守当地法律法规, "
                                                    @"逆向工程仅为学习目的\n盗用源码进行商业用途/发布但未标记开源项目必究\n详情请参阅项目内 MIT 许可证\n\n请输入\"我已阅读并同意继续使用\"以继续使用"
                                     preferredStyle:UIAlertControllerStyleAlert];

    [alertController addTextFieldWithConfigurationHandler:^(UITextField *_Nonnull textField) {
      textField.clearButtonMode = UITextFieldViewModeWhileEditing;
    }];

    UIAlertAction *confirmAction = [UIAlertAction actionWithTitle:@"确认"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction *_Nonnull action) {
                                                            UITextField *textField = alertController.textFields.firstObject;
                                                            NSString *inputText = textField.text;

                                                            if ([inputText isEqualToString:@"我已阅读并同意继续使用"]) {
                                                                [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"DYYYUserAgreementAccepted"];
                                                            } else {
                                                                UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:@"输入错误"
                                                                                                                                    message:@"请正确输入"
                                                                                                                             preferredStyle:UIAlertControllerStyleAlert];

                                                                UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"确定"
                                                                                                                   style:UIAlertActionStyleDefault
                                                                                                                 handler:^(UIAlertAction *_Nonnull action) {
                                                                                                                   [self showAgreementAlert];
                                                                                                                 }];

                                                                [errorAlert addAction:okAction];
                                                                [self presentViewController:errorAlert animated:YES completion:nil];
                                                            }
                                                          }];

    UIAlertAction *exitAction = [UIAlertAction actionWithTitle:@"退出"
                                                         style:UIAlertActionStyleDestructive
                                                       handler:^(UIAlertAction *_Nonnull action) {
                                                         exit(0);
                                                       }];

    [alertController addAction:confirmAction];
    [alertController addAction:exitAction];

    [self presentViewController:alertController animated:YES completion:nil];
}

@end
