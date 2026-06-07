import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
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
        ],
      ),
    );
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
}
