import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/modules/home/home_list_controller.dart';
import 'package:simple_live_app/widgets/live_room_card.dart';
import 'package:simple_live_app/widgets/page_grid_view.dart';

class HomeListView extends StatelessWidget {
  final String tag;
  final HomeListController? externalController;
  const HomeListView(this.tag, {Key? key, this.externalController})
      : super(key: key);
  HomeListController get controller =>
      externalController ?? Get.find<HomeListController>(tag: tag);
  @override
  Widget build(BuildContext context) {
    var c = MediaQuery.of(context).size.width ~/ 200;
    if (c < 2) {
      c = 2;
    }
    return PageGridView(
      pageController: controller,
      padding: AppStyle.edgeInsetsA12,
      firstRefresh: true,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      crossAxisCount: c,
      autoLoadMore: false,
      itemBuilder: (_, i) {
        var item = controller.list[i];
        return LiveRoomCard(controller.site, item);
      },
    );
  }
}
