# Design: 精简 B站直播客户端 (BiliLive)

**Date**: 2026-06-02
**Author**: Sisyphus (基于 xiaoyaocz/dart_simple_live)
**License**: GPL-3.0 (保留原项目许可证)

---

## 1. 目标

将 `dart_simple_live` 项目精简为 **仅含 B站直播** 的 Android 客户端：
- 删除斗鱼、虎牙、抖音全部代码
- 删除 TV 版 (`simple_live_tv_app`) 和控制台 (`simple_live_console`)
- 去除 B站账号登录、关注、数据同步等非核心功能
- 修复已知 Bug，优化代码质量
- 最终作为独立项目上传至用户 GitHub

---

## 2. 保留的功能

### 核心能力
| 功能 | 来源 | 状态 |
|------|------|------|
| 直播分类浏览 | `bilibili_site.dart` | 保留 |
| 分区直播间列表 | `bilibili_site.dart` | 保留 |
| 推荐直播间 | `bilibili_site.dart` | 保留 |
| 直播间详情（标题/封面/在线/开播状态） | `bilibili_site.dart` | 保留 |
| 多清晰度播放地址 | `bilibili_site.dart` | 保留 |
| WebSocket 弹幕 | `bilibili_danmaku.dart` | 保留 |
| 醒目留言 (Super Chat) | `bilibili_site.dart` | 保留 |
| 搜索直播间/主播 | `bilibili_site.dart` | 保留 |
| WBI 签名 | `bilibili_site.dart` | 保留 |
| Buvid 生成 | `bilibili_site.dart` | 保留 |

### App 功能
| 功能 | 说明 | 状态 |
|------|------|------|
| 首页分区浏览 | 显示 B站直播分区列表 | 保留 |
| 直播间播放 | video + danmaku overlay | 保留 |
| 搜索 | 搜索直播间和主播 | 保留 |
| 观看记录 | 本地 Hive 存储，无需登录 | 保留 |
| 弹幕设置 | 字体大小、透明度、速度等 | 保留 |
| 弹幕屏蔽 | 关键词/用户屏蔽 | 保留 |
| 外观设置 | 主题色、暗黑模式 | 保留 |
| 定时关闭 | 定时退出播放 | 保留 |
| 其他设置 | 硬件加速、播放器等 | 保留 |

---

## 3. 删除的内容

### 3.1 删除文件
```
simple_live_core/lib/src/sites/
  ├── douyin_site.dart      ← 删除
  ├── huya_site.dart         ← 删除
  ├── douyu_site.dart        ← 删除
  ├── douyin_page.dart       ← 删除
  ├── huya_cache.dart        ← 删除

simple_live_core/lib/src/danmaku/
  ├── douyin_danmaku.dart    ← 删除
  ├── huya_danmaku.dart       ← 删除
  ├── douyu_danmaku.dart      ← 删除

simple_live_tv_app/          ← 整体删除
simple_live_console/         ← 整体删除
```

### 3.2 删除 App 功能
- **B站账号登录** → `bilibili_account_service.dart`, `modules/mine/account/`
- **数据同步** → `sync_service.dart`, `signalr_service.dart`, `sync_client_request.dart`
- **抖音账号** → `douyin_account_service.dart`
- **链接解析** → `modules/mine/parse/`
- **关注功能** → `follow_service.dart`, `models/follow_user_item.dart`
- **平台选择逻辑** → `sites.dart`, 首页 tab 切换
- **Desktop 窗口管理** → `window_manager` 相关
- **多平台判断** → `Platform.isWindows/isMacOS/isLinux` 相关，只保留 Android

### 3.3 简化依赖
| 依赖 | 决策 |
|------|------|
| `window_manager` | ❌ 删除 (Android 不需要) |
| `flutter_inappwebview` | ❌ 删除 (不再需要登录) |
| `signalr` | ❌ 删除 (不再需要同步) |

---

## 4. 实现分阶段计划

### Phase 1: 清理 Core 层
1. 删除 `simple_live_core` 中非 B站站点的 site 文件
2. 删除非 B站弹幕文件
3. 更新 `simple_live_core.dart` 导出文件
4. 更新 `live_site.dart` 接口（移除不必要的抽象）
5. 运行测试确保 Core 层编译通过

### Phase 2: 清理 App 层 — UI/功能
1. 删除平台选择 tab，首页直接显示 B站分区
2. 删除账号管理相关页面 (`modules/mine/account/`)
3. 删除数据同步相关 (`SignalR`, `SyncService`)
4. 删除关注功能
5. 删除链接解析
6. 删除 TV + Console 模块
7. 删除抖音账号服务
8. 简化 `main.dart`（去掉 Desktop 窗口逻辑、多平台判读）

### Phase 3: Bug 修复 + 优化
1. 修复 Android 页面过渡动画 BUG（`main.dart` L211）
2. 简化 `app_pages.dart` 路由表
3. 精简 `sites.dart` 为单一 B站配置
4. 清理无效 import 和冗余代码
5. 验证编译通过、APK 可构建

### Phase 4: 最终确认
1. 构建 Android APK 测试
2. 更新 `README.md`，注明原作者和修改内容
3. 保持项目可直接上传至用户 GitHub

---

## 5. 架构调整

### 之前架构
```
simple_live_core (多平台) → simple_live_app (多平台切换)
                          → simple_live_tv_app
                          → simple_live_console
```

### 之后架构
```
simple_live_core (仅 B站) → simple_live_app (Android)
```

`simple_live_core` 中的抽象层（`LiveSite` 接口）根据精简后情况决定保留或内联。如果 Core 中只剩一个实现，考虑内联简化。

---

## 6. 风险评估

| 风险 | 影响 | 缓解 |
|------|------|------|
| 删除代码破坏编译链 | 高 | 每阶段结束编译验证 |
| `LiveSite` 接口耦合多个模块 | 中 | Phase 3 才决定是否内联，先最小改动 |
| Hive 数据迁移兼容 | 低 | 保留现有数据库模型，历史记录无需迁移 |
| media_kit 平台兼容 | 低 | 专注 Android，无需处理桌面差异 |

---

## 7. 成功标准

- [ ] 项目仅包含 B站直播相关代码
- [ ] 无编译错误和警告
- [ ] Android APK 可正常构建
- [ ] 以下功能可用：分类浏览、直播间播放、弹幕显示、搜索、观看记录
- [ ] 无登录/关注/同步/平台切换功能残留
- [ ] 保留 GPL-3.0 许可证和原作者署名
- [ ] README 注明修改内容和作者
