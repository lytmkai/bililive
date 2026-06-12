# Design: 关注数据一键导出/导入

**Date**: 2026-06-12
**Project**: BiliLive
**License**: GPL-3.0

---

## 1. 目标

为关注页（收藏页）增加一键导出/导入功能，解决卸载重装后关注列表丢失的问题，同时支持分享给他人。

### 核心需求

- **导出**：将全部关注用户、标签分组、置顶信息导出为一个 JSON 文件
- **导入**：从 JSON 文件恢复关注列表，自动去重，保留标签和置顶关系
- **可分享**：导出的文件可以通过系统分享功能发送给他人
- **入口直观**：在关注页可直达，无需多层导航

### 非需求

- 不涉及网络同步/云备份
- 不修改现有关注页 UI 布局
- 不涉及账号登录

---

## 2. 数据格式

### JSON Schema

```json
{
  "type": "bililive_follow",
  "version": 1,
  "exportTime": "2026-06-12T10:00:00.000",
  "follows": [
    {
      "id": "bilibili_12345",
      "roomId": "12345",
      "siteId": "bilibili",
      "userName": "主播名",
      "face": "https://i0.hdslb.com/bfs/face/xxx.jpg",
      "addTime": "2026-06-12T10:00:00.000",
      "tag": "全部"
    }
  ],
  "tags": [
    {
      "id": "uuid-string",
      "tag": "好朋友",
      "userId": ["bilibili_12345"]
    }
  ],
  "pinnedIds": ["bilibili_12345"]
}
```

**字段说明**：

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `type` | string | 是 | 固定值 `"bililive_follow"`，用于导入时校验 |
| `version` | int | 是 | 格式版本号，当前为 1 |
| `exportTime` | string | 是 | ISO 8601 导出时间 |
| `follows` | array | 是 | 关注用户列表，每个元素与 `FollowUser.toJson()` 一致 |
| `tags` | array | 否 | 标签列表，每个元素与 `FollowUserTag.toJson()` 一致 |
| `pinnedIds` | array | 否 | 置顶直播间 ID 列表 |

---

## 3. 入口位置

在关注页（`FollowUserPage`）AppBar 右侧添加一个 `PopupMenuButton` 菜单按钮（三点图标 `Icons.more_vert`），包含两个选项：

1. **导出关注数据**（icon: `Icons.upload_file`）
2. **导入关注数据**（icon: `Icons.download_file`）

**选择理由**：
- 用户卸载重装后第一件事就是打开关注页，入口在最需要的位置
- 不干扰现有的刷新按钮（左侧）和筛选按钮（页面内）
- 菜单形式不占用 AppBar 空间，干净整洁

---

## 4. 导出流程

```
用户点击"导出关注数据"
    ↓
收集数据：
  ├─ DBService.instance.followBox.values  → follows[]
  ├─ DBService.instance.tagBox.values     → tags[]
  └─ AppSettingsController.instance.pinnedFollowIds → pinnedIds[]
    ↓
组装为 JSON（utf8 编码）
    ↓
调用 FilePicker.platform.saveFile()
  ├─ allowedExtensions: ['json']
  ├─ fileName: "bililive_follow_{日期}.json"
  └─ bytes: Uint8List (Android/iOS 直接写入)
    ↓
桌面平台补充写入 File(path)
    ↓
SmartDialog.showToast("导出成功")
```

### 异常处理

| 场景 | 处理方式 |
|------|----------|
| 关注列表为空 | Toast 提示"暂无关注数据可导出" |
| 用户取消保存 | 静默退出，不提示 |
| 文件写入失败 | Toast 显示错误详情 |
| `utf8` 编码异常 | catch 后 Toast 提示 |

---

## 5. 导入流程

```
用户点击"导入关注数据"
    ↓
调用 FilePicker.platform.pickFiles()
  ├─ allowedExtensions: ['json']
  └─ type: FileType.custom
    ↓
读取文件内容 → JSON 解析
    ↓
校验 type == "bililive_follow"
    ↓
校验 version 是否支持
    ↓
弹出确认对话框：
  "即将导入 X 个关注用户和 Y 个标签，是否继续？"
    ↓
用户确认 →
  ├─ 逐条导入关注用户（id 去重：已存在则跳过）
  ├─ 逐条导入标签（id 去重）
  └─ 恢复 pinnedIds
    ↓
调用 FollowService.instance.loadData() 刷新
    ↓
Toast 提示"导入成功，共导入 X 个关注用户"
```

### 去重策略

- **关注用户**：以 `id`（`siteId_roomId`）为主键，如果 `followBox` 中已存在相同 `id`，则跳过（保留现有的）
- **标签**：以 `id`（UUID）为主键，已存在则跳过
- **置顶 ID**：直接覆盖 `pinnedFollowIds` 集合

### 异常处理

| 场景 | 处理方式 |
|------|----------|
| 文件类型不匹配 | Toast "请选择有效的 JSON 文件" |
| JSON 格式错误 | Toast "文件格式错误，解析失败" |
| type 字段不匹配 | Toast "不支持的文件格式" |
| version 超出支持范围 | Toast "文件版本不兼容，请更新 App" |
| 用户取消选择文件 | 静默退出 |
| 导入过程中 Hive 写入失败 | Toast 显示错误详情 |

---

## 6. 文件变更清单

### 新增文件

| 文件 | 说明 |
|------|------|
| `simple_live_app/lib/services/follow_export_service.dart` | 导出/导入核心逻辑（与 UI 解耦，方便测试） |

### 修改文件

| 文件 | 改动 |
|------|------|
| `simple_live_app/lib/modules/follow_user/follow_user_page.dart` | AppBar 右侧添加 PopupMenuButton 菜单，调用导出/导入服务 |
| `simple_live_app/lib/modules/follow_user/follow_user_controller.dart` | 添加导出/导入方法（委托给 FollowExportService） |

---

## 7. 服务接口设计

```dart
// follow_export_service.dart

class FollowExportService {
  /// 导出关注数据到 JSON 文件
  static Future<void> exportFollowData();

  /// 从 JSON 文件导入关注数据
  static Future<void> importFollowData();
}
```

静态方法设计而非实例化服务，因为该功能是零散的辅助操作，不需要生命周期管理或状态维护。

---

## 8. 依赖分析

所有依赖均已在 `pubspec.yaml` 中存在：

| 依赖 | 用途 |
|------|------|
| `file_picker` | 文件保存/选择对话框 |
| `dart:convert` | JSON 序列化/反序列化 |
| `dart:io` | 文件读写 |
| `flutter_smart_dialog` | Toast 提示 |
| `share_plus` | 文件分享（可选扩展） |

无需新增任何依赖。

---

## 9. 向后兼容

- 导入功能向前兼容：`version` 字段设计为递增，未来扩展格式时可通过版本号做迁移逻辑
- 不破坏现有 Hive 数据结构
- 不影响现有关注页功能
