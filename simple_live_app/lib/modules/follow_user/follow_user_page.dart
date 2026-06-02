import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/follow_user/follow_user_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/filter_button.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';

class FollowUserPage extends GetView<FollowUserController> {
  const FollowUserPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    var count = MediaQuery.of(context).size.width ~/ 500;
    if (count < 1) count = 1;
    return Scaffold(
      appBar: AppBar(
        title: const Text("关注用户"),
        leading: Obx(
          () => FollowService.instance.updating.value
              ? const IconButton(
                  onPressed: null,
                  icon: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : IconButton(
                  onPressed: controller.refreshData,
                  icon: const Icon(Icons.refresh),
                ),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: AppStyle.edgeInsetsL8,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Obx(
                () => Row(
                  children: [
                    FilterButton(
                      text: "全部",
                      selected: controller.filterMode.value == 0,
                      onTap: () => controller.setFilterMode(0),
                    ),
                    AppStyle.hGap12,
                    FilterButton(
                      text: "直播中",
                      selected: controller.filterMode.value == 1,
                      onTap: () => controller.setFilterMode(1),
                    ),
                    AppStyle.hGap12,
                    FilterButton(
                      text: "未开播",
                      selected: controller.filterMode.value == 2,
                      onTap: () => controller.setFilterMode(2),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: PageGridView(
              crossAxisSpacing: 12,
              crossAxisCount: count,
              pageController: controller,
              firstRefresh: true,
              showPCRefreshButton: false,
              itemBuilder: (_, i) {
                var item = controller.list[i];
                var site = Sites.allSites[item.siteId]!;
                return FollowUserItem(
                  item: item,
                  onRemove: () => controller.removeItem(item),
                  onTap: () {
                    AppNavigator.toLiveRoomDetail(
                      site: site,
                      roomId: item.roomId,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
