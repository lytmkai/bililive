import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:simple_live_app/widgets/settings/settings_card.dart';

class AudioSettingsPage extends GetView<AppSettingsController> {
  const AudioSettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("音频设置"),
      ),
      body: ListView(
        padding: AppStyle.edgeInsetsA12,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsA12.copyWith(top: 0),
            child: Text(
              "录音",
              style: Get.textTheme.titleSmall,
            ),
          ),
          SettingsCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Obx(
                  () => ListTile(
                    leading: const Icon(Icons.folder_outlined),
                    title: const Text("音频存储路径"),
                    subtitle: Text(
                      controller.audioSavePath.value.isNotEmpty
                          ? controller.audioSavePath.value
                          : "未设置（默认保存至应用文档目录）",
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: TextButton(
                      onPressed: _selectSavePath,
                      child: Text(
                        controller.audioSavePath.value.isNotEmpty
                            ? "更改"
                            : "选择",
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "设置后录音文件将自动保存至该目录，不设置则使用默认路径。",
              style: TextStyle(
                fontSize: 12,
                color: Get.theme.disabledColor,
              ),
            ),
          ),
          const Padding(
            padding: AppStyle.edgeInsetsA12,
            child: Text(
              "需要自行去系统设置授予 SimpleLive 的存储权限",
              style: TextStyle(
                fontSize: 12,
                color: Colors.orange,
              ),
            ),
          ),
          const SizedBox(height: 8),
          SettingsCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.headphones_outlined),
                  title: const Text("查看录音文件"),
                  trailing: const Icon(
                    Icons.chevron_right,
                    color: Colors.grey,
                  ),
                  onTap: _showRecordedFiles,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SettingsCard(
            child: ListTile(
              leading: const Icon(Icons.folder_open_outlined),
              title: const Text("打开存储文件夹"),
              trailing: const Icon(
                Icons.chevron_right,
                color: Colors.grey,
              ),
              onTap: _openSaveDir,
            ),
          ),
        ],
      ),
    );
  }

  /// 显示录音文件列表
  void _showRecordedFiles() {
    var saveDir = controller.audioSavePath.value;
    if (saveDir.isEmpty) {
      SmartDialog.showToast("请先设置音频存储路径");
      return;
    }

    var dir = Directory(saveDir);
    if (!dir.existsSync()) {
      SmartDialog.showToast("存储目录不存在");
      return;
    }

    var files = dir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.m4a'))
        .toList()
      ..sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

    if (files.isEmpty) {
      SmartDialog.showToast("暂无录音文件");
      return;
    }

    Get.bottomSheet(
      Container(
        constraints: BoxConstraints(
          maxHeight: Get.height * 0.6,
        ),
        decoration: BoxDecoration(
          color: Get.theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: AppStyle.edgeInsetsH12.copyWith(bottom: 8),
              child: Row(
                children: [
                  Text(
                    "录音文件 (${files.length})",
                    style: Get.textTheme.titleMedium,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => Get.back(),
                    child: const Text("关闭"),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: files.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  var file = files[index];
                  var sizeStr = _formatFileSize(file.lengthSync());
                  var modTime = _formatDateTime(file.lastModifiedSync());
                  return ListTile(
                    leading: const Icon(Icons.audiotrack, color: Colors.grey),
                    title: Text(
                      file.path.split('/').last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text("$sizeStr · $modTime"),
                    trailing: IconButton(
                      icon: const Icon(Icons.share_outlined),
                      onPressed: () {
                        Get.back();
                        _shareFile(file);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 分享录音文件
  void _shareFile(File file) {
    SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path)],
        text: "录音文件分享",
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return "$bytes B";
    if (bytes < 1024 * 1024) return "${(bytes / 1024).toStringAsFixed(1)} KB";
    return "${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB";
  }

  String _formatDateTime(DateTime dt) {
    return "${dt.month}/${dt.day} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }

  Future<void> _selectSavePath() async {
    String? dir;
    if (Platform.isAndroid) {
      dir = await FilePicker.platform.getDirectoryPath();
    } else {
      dir = await FilePicker.platform.saveFile(
        allowedExtensions: ['mp3'],
        type: FileType.custom,
        fileName: "recording_test.mp3",
      );
      if (dir != null) {
        dir = Directory(dir).parent.path;
      }
    }
    if (dir == null) return;

    // 验证路径可用
    var testFile = File("$dir/.simple_live_write_test");
    try {
      await testFile.writeAsString("test");
      await testFile.delete();
    } catch (e) {
      SmartDialog.showToast("路径不可写，请选择其他目录");
      return;
    }

    controller.setAudioSavePath(dir);
    SmartDialog.showToast("音频保存路径已设置");
  }

  /// 打开存储文件夹
  void _openSaveDir() async {
    var saveDir = controller.audioSavePath.value;
    if (saveDir.isEmpty) {
      var appDir = await getApplicationDocumentsDirectory();
      saveDir = appDir.path;
    }
    var dir = Directory(saveDir);
    if (!dir.existsSync()) {
      SmartDialog.showToast("存储目录不存在");
      return;
    }
    try {
      var result = await OpenFilex.open(saveDir);
      if (result.type != ResultType.done) {
        SmartDialog.showToast("无法打开文件夹，请手动前往路径查看");
      }
    } catch (e) {
      SmartDialog.showToast("无法打开文件夹，请手动前往路径查看");
    }
  }
}
