import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/category/detail/category_detail_controller.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/widgets/keep_alive_wrapper.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';

class CategoryDetailPage extends GetView<CategoryDetailController> {
  const CategoryDetailPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var c = MediaQuery.of(context).size.width ~/ 200;
    if (c < 2) {
      c = 2;
    }
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.subCategory.name),
        actions: [
          Obx(() {
            final isLoading = controller.pageLoadding.value;
            if (isLoading) {
              final progress = controller.loadingProgress.value;
              return Padding(
                padding: const EdgeInsets.all(10),
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress > 0 ? progress : null,
                        strokeWidth: 2.5,
                      ),
                      if (progress > 0)
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                ),
              );
            }
            return IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '刷新',
              onPressed: controller.manualRefresh,
            );
          }),
          GetBuilder<CategoryDetailController>(
            builder: (ctrl) {
              final isFav =
                  DBService.instance.isFavCategory(ctrl.subCategory.id);
              return IconButton(
                icon: Icon(
                  isFav ? Icons.star : Icons.star_border,
                  color: isFav ? Colors.amber : null,
                ),
                onPressed: () => ctrl.toggleFavorite(),
              );
            },
          ),
        ],
      ),
      body: KeepAliveWrapper(
        child: PageGridView(
          pageController: controller,
          padding: AppStyle.edgeInsetsA12,
          firstRefresh: false,          // 初始加载由 controller.onInit 处理
          autoLoadMore: false,          // 显示加载更多按钮
          enablePullRefresh: false,      // 禁用下拉刷新
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          crossAxisCount: c,
          itemBuilder: (_, i) {
            var item = controller.list[i];
            return LiveRoomCard(controller.site, item);
          },
        ),
      ),
    );
  }
}
