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
- ❤️ 本地收藏/关注直播间（无需登录）
- ⏰ 定时关闭
- 🎨 外观设置
- 🏷️ 子分区浏览与收藏
- 📋 自定义收藏分区列表

## 更新日志

### v2.0 (2026-06)

#### 🎯 分区浏览全面升级

- **分区下拉菜单**：点击顶部当前分区名称弹出分区选择器，支持展开查看各父分区下的所有子分区
- **子分区详情页**：点击子分区进入独立详情页，浏览指定子分区的直播间内容
- **分区收藏**：在子分区详情页可星标收藏该分区，收藏的分区会显示在分区选择器底部的"我的收藏"区域，方便快速访问
- **自定义收藏分区**：通过分类页的"管理收藏"功能，可以浏览全部分区树并收藏常用子分区

#### ❤️ 本地关注功能恢复

- 恢复纯本地的直播间关注/收藏功能，无需登录账号
- 底部导航栏恢复"关注"标签页
- 直播间详情页恢复"关注/取消关注"按钮
- 关注列表支持筛选：全部 / 直播中 / 未开播
- 关注列表封面图片优化，减少内存占用

#### 🏷️ 直播间分区标签

- 直播间卡片新增子分区名标签（如"英雄联盟"、"虚拟主播"等），让房间内容归属一目了然

#### 🚀 性能优化

- 封面图片解码分辨率限制（cacheWidth: 400px），大幅减少内存占用
- 修复封面图片解码导致的列表滚动卡顿问题

#### 🔧 API 升级

- 新增 `getAreaRooms` API（`room/v1/area/getRoomList`），按 area_id 直接拉取子分区房间列表（无需 WBI 签名，全球可用，每页 30 间，已按分区预过滤）
- 推荐流 API 迁移至 `webMain/getMoreRecList`，替代已对海外 IP 屏蔽的 `second/getList` 和 `second/getListByArea`
- 增强的 `_matchPartition` 三层匹配策略（精确父分区名 → 模糊父分区名 → 模糊子分区名），提高首页分区过滤准确率

#### 📱 首页体验优化

- 启动时预加载热门分区的首屏数据（错开执行避免瞬间高并发）
- 首页顶部标题适配溢出门牌号省略显示
- 推荐 Tab 增加加载按钮
- 加载状态显示优化

#### 🛡️ 稳定性修复

- 修复 `loadData` 并发调用导致 `ConcurrentModificationError`
- 修复关注列表 `filterData` 并发修改异常
- 使用代次计数器（generation）防止异步竞态导致的数据错乱
- 修复 Release 签名配置在缺少 key.properties 时崩溃的问题

#### 📦 依赖与构建

- 升级 Kotlin 版本至 2.3.21 以兼容 `screen_brightness_android` 插件
- 简化测试文件
- 代码风格统一优化

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
