import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/follow_user/follow_user_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/services/follow_service.dart';
import 'package:simple_live_app/widgets/follow_user_item.dart';
import 'package:simple_live_app/widgets/status/app_empty_widget.dart';
import 'package:simple_live_app/widgets/status/app_error_widget.dart';
import 'package:simple_live_app/widgets/status/app_loadding_widget.dart';

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
          () {
            final fs = FollowService.instance;
            if (fs.updating.value) {
              final progress = fs.loadProgress.value;
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
              onPressed: controller.refreshData,
              icon: const Icon(Icons.refresh),
            );
          },
        ),
      ),
      body: Obx(
        () {
          if (controller.pageLoadding.value) {
            return const AppLoaddingWidget();
          }
          if (controller.pageError.value) {
            return AppErrorWidget(
              errorMsg: controller.errorMsg.value,
              onRefresh: () => controller.refreshData(),
            );
          }
          if (controller.pageEmpty.value) {
            return AppEmptyWidget(
              onRefresh: () => controller.refreshData(),
            );
          }
          return MasonryGridView.count(
            padding: const EdgeInsets.all(8),
            itemCount: controller.list.length,
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
            crossAxisCount: count,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          );
        },
      ),
    );
  }
}
