//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//
//  彩色评论：发布评论时自动装饰（默认关闭，由设置页开关控制）
//
//  hook 点来自 41.2.0 class-dump 实测存在：
//    AWECommentInputNetworkServiceImpl - (void)publishCommentWithModel:(id)completion:(id)
//    AWECommentInputViewController      - (void)publishCommentWithRequest:(id)inputSnapshot:(id)
//  正文位置：AWECommentInputSnapshot.text / AWECommentInputContentModel.content
//
//  用命名 group 是必要的：默认 _ungrouped 可能与其它文件生成同名符号导致链接冲突。
//

#import "AwemeHeaders.h"
#import "DYYYColoredComment.h"

%group DYYYColoredCommentGroup

%hook AWECommentInputViewController

- (void)publishCommentWithRequest:(id)request inputSnapshot:(id)snapshot {
    if ([DYYYColoredComment autoEnabled]) {
        [DYYYColoredComment decorateSnapshot:snapshot];
        [DYYYColoredComment decorateModel:request];
    }
    %orig;
}

%end

%hook AWECommentInputNetworkServiceImpl

- (void)publishCommentWithModel:(id)model completion:(id)completion {
    if (model && [DYYYColoredComment autoEnabled]) {
        [DYYYColoredComment decorateModel:model];
    }
    %orig;
}

%end

%end

%ctor {
    %init(DYYYColoredCommentGroup);
}
