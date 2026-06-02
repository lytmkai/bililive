> ### ⚠ 本项目不提供Release安装包，请自行编译后运行测试。

<p align="center">
    <img width="128" src="/assets/logo.png" alt="BiliLive logo">
</p>
<h2 align="center">BiliLive</h2>

<p align="center">
简简单单看B站直播
</p>

## 关于本项目

BiliLive 是基于 [Simple Live](https://github.com/xiaoyaocz/dart_simple_live) 精简优化而来，专注于观看哔哩哔哩直播。

**原项目**: [xiaoyaocz/dart_simple_live](https://github.com/xiaoyaocz/dart_simple_live) (GPL-3.0)
**本仓库**: [BoooSAMA/dart_simple_live_bilibili](https://github.com/BoooSAMA/dart_simple_live_bilibili)

### 与原项目的主要区别

- 仅保留哔哩哔哩直播功能
- 移除了虎牙、斗鱼、抖音等直播平台支持
- 移除了账号登录、关注、数据同步等非核心功能
- 简化了代码结构和依赖
- 专注于 Android 平台

## 支持平台

- [x] Android

## 功能

- 📺 哔哩哔哩直播分区浏览和推荐
- 🔍 搜索直播间和主播
- 💬 弹幕显示（含关键词屏蔽）
- 🎬 多清晰度播放
- 📝 本地观看记录
- ⏰ 定时关闭
- 🎨 外观设置

## 项目结构

- `simple_live_core` 项目核心库（仅保留B站相关）
- `simple_live_app` Flutter APP客户端

## 环境

Flutter: `3.38`

## 参考及引用

原项目 [Simple Live](https://github.com/xiaoyaocz/dart_simple_live) 参考的资料：

[AllLive](https://github.com/xiaoyaocz/AllLive)

[wbt5/real-url](https://github.com/wbt5/real-url)

[lovelyyoshino/Bilibili-Live-API](https://github.com/lovelyyoshino/Bilibili-Live-API/blob/master/API.WebSocket.md)

[IsoaSFlus/danmaku](https://github.com/IsoaSFlus/danmaku)

## 许可证

GPL-3.0 (与原项目保持一致)

## 声明

本项目的所有功能都是基于互联网上公开的资料开发，无任何破解、逆向工程等行为。

本项目仅用于学习交流编程技术，严禁将本项目用于商业目的。如有任何商业行为，均与本项目无关。

如果本项目存在侵犯您的合法权益的情况，请及时与开发者联系，开发者将会及时删除有关内容。
