import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/home/home_list_view.dart';
import 'package:simple_live_app/app/constant.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: _buildSectionSwitcher(context),
        actions: [
          IconButton(
            onPressed: controller.toSearch,
            icon: const Icon(Icons.search),
          )
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildSectionSwitcher(BuildContext context) {
    return Obx(() {
      final names = controller.sectionNames;
      if (names.isEmpty) {
        return const Text('推荐');
      }
      final currentName = names[controller.selectedSectionIndex.value];
      return PopupMenuButton<int>(
        offset: const Offset(0, 36),
        padding: EdgeInsets.zero,
        onSelected: controller.switchSection,
        itemBuilder: (context) {
          return List.generate(names.length, (i) {
            return PopupMenuItem<int>(
              value: i,
              child: Text(
                names[i],
                style: TextStyle(
                  fontWeight: i == controller.selectedSectionIndex.value
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
              ),
            );
          });
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                currentName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      );
    });
  }

  Widget _buildBody() {
    return Obx(() {
      // 显式读取 .value 确保 GetX 正确追踪依赖
      final index = controller.selectedSectionIndex.value;
      if (controller.sectionNames.length <= 1 && controller.isLoadingAreas.value) {
        // 正在加载分区，显示过渡 loading
        return const Center(child: CircularProgressIndicator());
      }
      return HomeListView(
        Constant.kBiliBili,
        externalController: controller.getController(index),
        key: ValueKey('section_$index'),
      );
    });
  }
}
