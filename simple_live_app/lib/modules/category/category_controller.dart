import 'dart:async';

import 'package:get/get.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/category/category_list_controller.dart';

class CategoryController extends GetxController {
  StreamSubscription<dynamic>? streamSubscription;

  @override
  void onInit() {
    streamSubscription = EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 2) {
          refreshOrScrollTop();
        }
      },
    );

    // Register site controllers (kept for potential future multi-site support)
    for (var site in Sites.supportSites) {
      Get.put(CategoryListController(site), tag: site.id);
    }

    super.onInit();
  }

  void refreshOrScrollTop() {
    // Custom category view has no scroll-to-top behavior; no-op for now.
  }

  @override
  void onClose() {
    streamSubscription?.cancel();
    super.onClose();
  }
}
