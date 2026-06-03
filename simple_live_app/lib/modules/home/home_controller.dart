import 'dart:async';

import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/home/home_list_controller.dart';
import 'package:simple_live_app/routes/route_path.dart';

class HomeController extends GetxController {
  StreamSubscription<dynamic>? streamSubscription;

  @override
  void onInit() {
    super.onInit();
    streamSubscription = EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 0) {
          refreshOrScrollTop();
        }
      },
    );
    final site = Sites.allSites[Constant.kBiliBili]!;
    Get.put(HomeListController(site), tag: site.id);
  }

  void refreshOrScrollTop() {
    final site = Sites.allSites[Constant.kBiliBili]!;
    BasePageController controller =
        Get.find<HomeListController>(tag: site.id);
    controller.scrollToTopOrRefresh();
  }

  void toSearch() {
    Get.toNamed(RoutePath.kSearch);
  }

  @override
  void onClose() {
    streamSubscription?.cancel();
    super.onClose();
  }
}
