import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/models/db/follow_user_tag.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/services/follow_service.dart';

class FollowExportService {
  /// 导出关注数据到 JSON 文件
  static Future<void> exportFollowData() async {
    try {
      final follows = DBService.instance.followBox.values.toList();
      if (follows.isEmpty) {
        SmartDialog.showToast('暂无关注数据可导出');
        return;
      }

      final tags = DBService.instance.tagBox.values.toList();
      final pinnedIds =
          AppSettingsController.instance.pinnedFollowIds.toList();

      final data = {
        'type': 'bililive_follow',
        'version': 1,
        'exportTime': DateTime.now().toIso8601String(),
        'follows': follows.map((e) => e.toJson()).toList(),
        'tags': tags.map((e) => e.toJson()).toList(),
        'pinnedIds': pinnedIds,
      };

      final bytes = Uint8List.fromList(utf8.encode(jsonEncode(data)));
      final dateStr = DateTime.now().toString().substring(0, 10);

      final inlineSave = Platform.isAndroid || Platform.isIOS;
      final path = await FilePicker.platform.saveFile(
        allowedExtensions: ['json'],
        type: FileType.custom,
        fileName: 'bililive_follow_$dateStr.json',
        bytes: inlineSave ? bytes : null,
      );

      if (path == null) return;

      if (!inlineSave) {
        await File(path).writeAsBytes(bytes);
      }

      SmartDialog.showToast('导出成功');
    } catch (e) {
      SmartDialog.showToast('导出失败: $e');
    }
  }

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
      Map<String, dynamic> data;
      try {
        data = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        SmartDialog.showToast('文件格式错误，解析失败');
        return;
      }

      if (data['type'] != 'bililive_follow') {
        SmartDialog.showToast('不支持的文件格式');
        return;
      }

      final version = data['version'] as int?;
      if (version == null || version < 1 || version > 1) {
        SmartDialog.showToast('文件版本不兼容，请更新 App');
        return;
      }

      final followsJson = data['follows'] as List<dynamic>? ?? [];
      final tagsJson = data['tags'] as List<dynamic>? ?? [];
      final pinnedIds =
          (data['pinnedIds'] as List<dynamic>?)?.cast<String>().toSet() ??
              <String>{};

      // 确认对话框
      final confirm = await Get.dialog<bool>(
        AlertDialog(
          title: const Text('导入关注数据'),
          content: Text(
            '即将导入 ${followsJson.length} 个关注用户'
            '${tagsJson.isNotEmpty ? ' 和 ${tagsJson.length} 个标签' : ''}'
            '，是否继续？',
          ),
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
          final follow =
              FollowUser.fromJson(json as Map<String, dynamic>);
          if (!DBService.instance.followBox.containsKey(follow.id)) {
            await DBService.instance.followBox.put(follow.id, follow);
            importedCount++;
          }
        } catch (_) {
          // 跳过单个解析失败记录
        }
      }

      // 导入标签（id 去重）
      for (final json in tagsJson) {
        try {
          final tag =
              FollowUserTag.fromJson(json as Map<String, dynamic>);
          if (!DBService.instance.tagBox.containsKey(tag.id)) {
            await DBService.instance.tagBox.put(tag.id, tag);
          }
        } catch (_) {
          // 跳过单个解析失败记录
        }
      }

      // 恢复置顶 ID
      if (pinnedIds.isNotEmpty) {
        AppSettingsController.instance.pinnedFollowIds.addAll(pinnedIds);
        await AppSettingsController.instance.savePinnedFollowIds();
      }

      // 刷新关注列表
      await FollowService.instance.loadData();

      SmartDialog.showToast('导入成功，共导入 $importedCount 个关注用户');
    } catch (e) {
      SmartDialog.showToast('导入失败: $e');
    }
  }
}
