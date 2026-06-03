import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
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
          body: controller.savedList.isEmpty
              ? _buildEmptyView(context)
              : _buildGridView(context),
          floatingActionButton: FloatingActionButton.small(
            onPressed: () => AddCategoryPicker.show(context, site: site),
            child: const Icon(Remix.add_line),
          ),
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
    final crossAxisCount = (MediaQuery.of(context).size.width / 80).floor();
    return Padding(
      padding: AppStyle.edgeInsetsA12,
      child: GridView.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: 0.85,
        ),
        itemCount: controller.savedList.length,
        itemBuilder: (_, i) {
          return _buildGridItem(context, controller.savedList[i]);
        },
      ),
    );
  }

  Widget _buildGridItem(BuildContext context, SavedSubCategory item) {
    return Stack(
      children: [
        ShadowCard(
          onTap: () {
            AppNavigator.toCategoryDetail(
              site: site,
              category: item.toLiveSubCategory(),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
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
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ],
          ),
        ),
        // Remove button in top-right corner
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            onTap: () => controller.remove(item.id),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(8),
                  bottomLeft: Radius.circular(8),
                ),
              ),
              child: Icon(
                Remix.close_line,
                size: 14,
                color: Theme.of(context).colorScheme.error,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
