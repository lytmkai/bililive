import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/category/add_category_picker.dart';
import 'package:simple_live_app/modules/category/custom_category_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_app/widgets/shadow_card.dart';

class CustomCategoryView extends StatelessWidget {
  final Site site;

  const CustomCategoryView({super.key, required this.site});

  CustomCategoryViewController get controller {
    if (!Get.isRegistered<CustomCategoryViewController>()) {
      Get.put(CustomCategoryViewController());
    }
    return Get.find<CustomCategoryViewController>();
  }

  @override
  Widget build(BuildContext context) {
    return KeepAliveWrapper(
      child: Obx(
        () => Scaffold(
          appBar: AppBar(
            title: Text(
              controller.isPinMode
                  ? '点击要固定的分区'
                  : controller.isDeleteMode
                      ? '点击要删除的分区'
                      : '直播分区',
            ),
            actions: [
              // Pin mode toggle
              IconButton(
                onPressed: controller.togglePinMode,
                icon: Icon(
                  controller.isPinMode
                      ? Icons.push_pin
                      : Icons.push_pin_outlined,
                  color: controller.isPinMode
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                tooltip: '设为首页默认',
              ),
              // Delete mode toggle
              IconButton(
                onPressed: controller.toggleDeleteMode,
                icon: Icon(
                  controller.isDeleteMode ? Remix.delete_bin_2_fill : Remix.delete_bin_line,
                  color: controller.isDeleteMode
                      ? Theme.of(context).colorScheme.error
                      : null,
                ),
                tooltip: '删除分区',
              ),
            ],
          ),
          body: controller.savedList.isEmpty
              ? _buildEmptyView(context)
              : _buildGridView(context),
          floatingActionButton: controller.isNormalMode
              ? FloatingActionButton.small(
                  onPressed: () => AddCategoryPicker.show(context, site: site),
                  child: const Icon(Remix.add_line),
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Remix.apps_2_line,
            size: 64,
            color: Theme.of(context).colorScheme.primary.withAlpha(100),
          ),
          AppStyle.vGap12,
          Text(
            '暂无收藏分区',
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(150),
            ),
          ),
          AppStyle.vGap8,
          Text(
            '点击右下角 + 按钮添加',
            style: TextStyle(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridView(BuildContext context) {
    // 在 Obx 作用域内读取，确保 pin 状态变化时刷新
    final pinnedId =
        AppSettingsController.instance.homeDefaultCategory.value?.id;
    final isPinMode = controller.isPinMode;
    final isDeleteMode = controller.isDeleteMode;

    return Padding(
      padding: AppStyle.edgeInsetsA12,
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.75,
        ),
        itemCount: controller.savedList.length,
        itemBuilder: (_, i) {
          return _buildGridItem(
            context,
            controller.savedList[i],
            pinnedId,
            isPinMode,
            isDeleteMode,
          );
        },
      ),
    );
  }

  Widget _buildGridItem(
    BuildContext context,
    SavedSubCategory item,
    String? pinnedId,
    bool isPinMode,
    bool isDeleteMode,
  ) {
    final isPinned = pinnedId == item.id;

    return GestureDetector(
      onTap: () {
        if (isPinMode) {
          if (isPinned) {
            HomeController.instance.clearCustomSubCategory();
          } else {
            HomeController.instance.setCustomSubCategory(item);
          }
          controller.togglePinMode();
        } else if (isDeleteMode) {
          if (isPinned) {
            HomeController.instance.clearCustomSubCategory();
          }
          controller.remove(item.id);
          controller.toggleDeleteMode();
        } else {
          AppNavigator.toCategoryDetail(
            site: site,
            category: item.toLiveSubCategory(),
          );
        }
      },
      child: ShadowCard(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isDeleteMode
                ? Border.all(
                    color: Theme.of(context).colorScheme.error.withAlpha(120),
                    width: 2,
                  )
                : isPinned
                    ? Border.all(
                        color: Colors.green.withAlpha(150),
                        width: 2,
                      )
                    : isPinMode
                        ? Border.all(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withAlpha(120),
                            width: 2,
                          )
                        : null,
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox.expand(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    NetImage(
                      item.pic ?? "",
                      width: 40,
                      height: 40,
                      borderRadius: 8,
                    ),
                    AppStyle.vGap4,
                    Text(
                      item.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.parentName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withAlpha(120),
                      ),
                    ),
                  ],
                ),
              ),
              if (isDeleteMode)
                Positioned(
                  top: 4,
                  right: 4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Remix.close_line,
                      size: 14,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
