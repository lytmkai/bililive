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

### v2.1 (2026-06-07)

#### 🎙️ 直播间录音功能

- **音频录制**：在直播间新增"录音"按钮，可将直播音频实时录制为 M4A 文件（路径：我的 → 音频设置）
- **FFmpeg 引擎**：使用 FFmpeg 进行流拷贝录制（`-c:a copy`），零编码损耗，保留原始 AAC 音质
- **录制控制**：支持开始/停止录制，状态栏实时显示录制时长
- **防误触**：首次录音弹出确认对话框，支持"不再显示"选项
- **断线重连**：FFmpeg 内置自动重连参数（`-reconnect`），适应不稳定的直播流
- **自定义保存路径**：支持通过文件选择器自定义录音文件存储目录，并验证目录可写性
- **文件管理**：查看已录制文件列表（按修改时间倒序）、分享文件、打开存储文件夹
- **生命周期管理**：切换直播间或退出页面时自动停止录音，防止资源泄漏
- **防止休眠**：录制期间保持设备唤醒（Wakelock）

#### 📌 首页默认分区固定（Pin）

- **固定子分区到首页**：在分区选择菜单中，可为任意子分区添加图钉标记，将其固定为首页独立 Tab（位于"推荐"右侧，启动即加载）
- **一键切换**：固定的子分区作为独立 Tab 自动加载内容，底部菜单中显示图钉图标
- **取消固定**：通过底部菜单中自定义分区的关闭按钮移除固定，或设置清除
- **持久化存储**：固定的分区信息通过 JSON 序列化保存至 Hive，重启应用自动恢复
- **UI 指示**：首页标题栏当前选中固定分区时显示图钉图标

#### 🏠 首页加载优化

- **启动立即加载**：修复进入首页时推荐列表空白问题，`_initDefaultController` 在 `onInit` 中立即触发首屏数据请求
- **加载进度百分比**：刷新按钮显示当前加载进度百分比（`42%`），加载过程更透明
- **自定义 Tab 预加载**：固定的子分区参与启动预加载（`_preWarmPartitions`），错开 500ms 避免高并发

#### 🔧 其他改进

- **新增"音频设置"页面**：位于我的 → 音频设置，管理录音存储路径和录音文件
- **新增录音设计文档**：`docs/specs/2026-06-07-recording-design.md`
- **分区页布局调整**：分类详情页"加载更多"按钮上移 20px
- **新增依赖**：`ffmpeg_kit_flutter_new_https_gpl`、`file_picker`、`open_filex`、`share_plus`

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
