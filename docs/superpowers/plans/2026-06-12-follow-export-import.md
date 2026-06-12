# 关注数据导出/导入 实现计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为关注页添加一键导出/导入关注数据（含标签和置顶）的 JSON 文件功能

**Architecture:** 新建 `FollowExportService` 静态服务类封装导出/导入核心逻辑，关注页 AppBar 增加 PopupMenuButton 菜单入口，与 UI 层解耦

**Tech Stack:** Flutter/Dart, Hive, file_picker, flutter_smart_dialog

**设计文档:** `docs/superpowers/specs/2026-06-12-follow-export-import-design.md`

---

## 文件结构

| 操作 | 文件 | 职责 |
|------|------|------|
| 创建 | `simple_live_app/lib/services/follow_export_service.dart` | 导出/导入核心逻辑，JSON 序列化/反序列化，文件读写 |
| 修改 | `simple_live_app/lib/modules/follow_user/follow_user_page.dart` | AppBar 右侧加 PopupMenuButton，提供导出/导入入口 |
| 修改 | `simple_live_app/lib/modules/follow_user/follow_user_controller.dart` | 添加 exportData() / importData() 方法委托给 FollowExportService |

---

### Task 1: 导出服务 —— 核心导出逻辑

**Files:**
- Create: `simple_live_app/lib/services/follow_export_service.dart`

- [ ] **Step 1.1: 创建 follow_export_service.dart 文件，编写导出方法**

```dart
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';

class FollowExportService {
  /// 导出关注数据到 JSON 文件
  static Future<void> exportFollowData() async {
    try {
      // 收集数据
      final follows = DBService.instance.followBox.values.toList();
      if (follows.isEmpty) {
        SmartDialog.showToast('暂无关注数据可导出');
        return;
      }

      final tags = DBService.instance.tagBox.values.toList();
      final pinnedIds = AppSettingsController.instance.pinnedFollowIds.toList();

      // 组装 JSON
      final data = {
        'type': 'bililive_follow',
        'version': 1,
        'exportTime': DateTime.now().toIso8601String(),
        'follows': follows.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'pinnedIds': pinnedIds,
      };

      final jsonStr = jsonEncode(data);
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      // 日期后缀
      final dateStr = DateTime.now().toString().substring(0, 10);

      // FilePicker 保存
      final inlineSave = Platform.isAndroid || Platform.isIOS;
      final path = await FilePicker.platform.saveFile(
        allowedExtensions: ['json'],
        type: FileType.custom,
        fileName: 'bililive_follow_$dateStr.json',
        bytes: inlineSave ? bytes : null,
      );

      if (path == null) {
        return; // 用户取消
      }

      if (!inlineSave) {
        await File(path).writeAsBytes(bytes);
      }

      SmartDialog.showToast('导出成功');
    } catch (e) {
      SmartDialog.showToast('导出失败: $e');
    }
  }
}
```

- [ ] **Step 1.2: 编写导入方法（追加到同一文件）**

在 `FollowExportService` 类中添加：

```dart
  /// 从 JSON 文件导入关注数据
  static Future<void> importFollowData() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowedExtensions: ['json'],
        type: FileType.custom,
      );

      if (result == null || result.files.isEmpty) return;

      final filePath = result.files.single.path;
      if (filePath == null) {
        SmartDialog.showToast('无法读取文件');
        return;
      }

      final raw = await File(filePath).readAsString();
      final Map<String, dynamic> data;
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        SmartDialog.showToast('文件格式错误，解析失败');
        return;
      }

      // 校验类型
      if (data['type'] != 'bililive_follow') {
        SmartDialog.showToast('不支持的文件格式');
        return;
      }

      // 校验版本
      final version = data['version'] as int?;
      if (version == null || version < 1 || version > 1) {
        SmartDialog.showToast('文件版本不兼容，请更新 App');
        return;
      }

      // 解析数据
      final followsJson = data['follows'] as List<dynamic>? ?? [];
      final tagsJson = data['tags'] as List<dynamic>? ?? [];
      final pinnedIds = (data['pinnedIds'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toSet() ??
          <String>{};

      // 弹出确认对话框
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('导入关注数据'),
          content: Text('即将导入 ${followsJson.length} 个关注用户'
              '${tagsJson.isNotEmpty ? ' 和 ${tagsJson.length} 个标签' : ''}，是否继续？'),
          actions: [
            TextButton(
              onPressed: () => Get.back(result: false),
              child: const Text('取消'),
            ),
            TextButton(
              onPressed: () => Get.back(result: true),
              child: const Text('确定'),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      int importedCount = 0;
      // 导入关注用户（id 去重）
      for (final json in followsJson) {
        try {
          final follow = FollowUser.fromJson(json as Map<String, dynamic>);
          if (!DBService.instance.followBox.containsKey(follow.id)) {
            await DBService.instance.followBox.put(follow.id, follow);
            importedCount++;
          }
        } catch (_) {
          // 跳过单个解析失败的记录
        }
      }

      // 导入标签（id 去重）
      for (final json in tagsJson) {
        try {
          final tag = FollowUserTag.fromJson(json as Map<String, dynamic>);
          if (!DBService.instance.tagBox.containsKey(tag.id)) {
            await DBService.instance.tagBox.put(tag.id, tag);
          }
        } catch (_) {
          // 跳过单个解析失败的记录
        }
      }

      // 恢复置顶 ID（增量合并）
      if (pinnedIds.isNotEmpty) {
        final existing = AppSettingsController.instance.pinnedFollowIds;
        existing.addAll(pinnedIds);
        await AppSettingsController.instance.savePinnedFollowIds();
      }

      // 刷新关注列表
      await FollowService.instance.loadData();

      SmartDialog.showToast('导入成功，共导入 $importedCount 个关注用户');
    } catch (e) {
      SmartDialog.showToast('导入失败: $e');
    }
  }
```

注意：需要在文件顶部补全 import：

```dart
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/services/follow_service.dart';
```

- [ ] **Step 1.3: 检查并提交**

```bash
git add simple_live_app/lib/services/follow_export_service.dart
git commit -m "feat: add FollowExportService with export/import logic"
```

---

### Task 2: 关注页 Controller —— 添加导出/导入方法

**Files:**
- Modify: `simple_live_app/lib/modules/follow_user/follow_user_controller.dart`

- [ ] **Step 2.1: 在 controller 中添加导出/导入方法**

在 `FollowUserController` 类的末尾（`removeItem` 方法之后）添加：

```dart
  void exportData() => FollowExportService.exportFollowData();

  void importData() => FollowExportService.importFollowData();
```

并在文件顶部添加 import：

```dart
import 'package:simple_live_app/services/follow_export_service.dart';
```

- [ ] **Step 2.2: 检查并提交**

```bash
git add simple_live_app/lib/modules/follow_user/follow_user_controller.dart
git commit -m "feat: add export/import methods to FollowUserController"
```

---

### Task 3: 关注页 UI —— 添加菜单入口

**Files:**
- Modify: `simple_live_app/lib/modules/follow_user/follow_user_page.dart`

- [ ] **Step 3.1: 在 AppBar 的 title 后添加 actions 参数**

当前 AppBar 结构（约第 21-58 行）：

```dart
appBar: AppBar(
  title: const Text("关注用户"),
  leading: Obx(
    // ...刷新按钮/进度圈
  ),
  // ← 在这里添加 actions
  body: ...
),
```

在 `leading` 之后、`body` 之前插入 `actions`：

```dart
appBar: AppBar(
  title: const Text("关注用户"),
  leading: Obx(
    () {
      final fs = FollowService.instance;
      if (fs.updating.value) {
        // ...原有刷新进度圈代码保持不变
      }
      return IconButton(
        onPressed: controller.refreshData,
        icon: const Icon(Icons.refresh),
      );
    },
  ),
  actions: [
    PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert),
      onSelected: (value) {
        switch (value) {
          case 'export':
            controller.exportData();
            break;
          case 'import':
            controller.importData();
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'export',
          child: ListTile(
            leading: Icon(Icons.upload_file),
            title: Text('导出关注数据'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
        const PopupMenuItem(
          value: 'import',
          child: ListTile(
            leading: Icon(Icons.download_file),
            title: Text('导入关注数据'),
            contentPadding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    ),
  ],
  body: ...
),
```

同时确认 AppBar 的 `leading` 闭包中已有 `FollowService` 的 import（已在文件顶部），不需要额外 import。

- [ ] **Step 3.2: 检查并提交**

```bash
git add simple_live_app/lib/modules/follow_user/follow_user_page.dart
git commit -m "feat: add export/import menu to FollowUserPage AppBar"
```

---

### Task 4: 编译验证

- [ ] **Step 4.1: 运行静态分析检查**

```bash
cd simple_live_app && flutter analyze
```

Expected: 无新增错误或警告（或仅有与改动无关的预存警告）

- [ ] **Step 4.2: 运行测试**

```bash
cd simple_live_app && flutter test
```

Expected: 测试通过

- [ ] **Step 4.3: 如有错误，修复后提交**

```bash
git add -A && git commit -m "fix: resolve analyzer issues"
```

---

### 执行方式

**推荐: Subagent-Driven** — 每个 Task 派发独立子 agent，完成后 review 再进入下一个

**备选: Inline Execution** — 在当前 session 中顺序执行
