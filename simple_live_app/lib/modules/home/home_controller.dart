import 'dart:async';

import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/home/home_list_controller.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_core/simple_live_core.dart';

class HomeController extends GetxController {
  StreamSubscription<dynamic>? streamSubscription;

  /// B站分区列表（从 API 加载）
  var areas = <LiveCategory>[].obs;

  /// 分区名称列表："推荐" + 各分区名
  var sectionNames = <String>["推荐"].obs;

  /// 当前选中的分区索引，0 = "推荐"（默认）
  var selectedSectionIndex = 0.obs;

  /// 是否正在加载分区数据
  var isLoadingAreas = false.obs;

  /// 每个分区对应的 HomeListController（懒加载）
  final Map<int, HomeListController> _controllers = {};

  /// 已激活（加载过数据）的分区索引
  final Set<int> _activeControllers = {};

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
    _initDefaultController();
    _loadAreas();
  }

  /// 初始化默认的 "推荐" 控制器
  void _initDefaultController() {
    final site = Sites.allSites[Constant.kBiliBili]!;
    final ctrl = HomeListController(site);
    Get.put(ctrl, tag: 'home_section_0');
    _controllers[0] = ctrl;
  }

  /// 从 B站 API 加载分区列表
  Future<void> _loadAreas() async {
    isLoadingAreas.value = true;
    try {
      final site = Sites.allSites[Constant.kBiliBili]!;
      areas.value = await site.liveSite.getCategores();
      sectionNames.value = ["推荐", ...areas.map((a) => a.name)];
    } catch (e) {
      // 加载失败时保持默认的 "推荐"
      sectionNames.value = ["推荐"];
    } finally {
      isLoadingAreas.value = false;
    }
  }

  /// 获取或创建指定索引的分区控制器
  HomeListController getController(int index) {
    if (!_controllers.containsKey(index)) {
      final site = Sites.allSites[Constant.kBiliBili]!;
      String? parentAreaId;
      if (index > 0 && index - 1 < areas.length) {
        parentAreaId = areas[index - 1].id;
      }
      final ctrl = HomeListController(site, parentAreaId: parentAreaId);
      Get.put(ctrl, tag: 'home_section_$index');
      _controllers[index] = ctrl;
    }
    return _controllers[index]!;
  }

  /// 当前选中分区的控制器
  HomeListController get currentController =>
      getController(selectedSectionIndex.value);

  /// 切换分区
  void switchSection(int index) {
    if (index == selectedSectionIndex.value) return;
    selectedSectionIndex.value = index;
    final ctrl = getController(index);
    if (!_activeControllers.contains(index)) {
      _activeControllers.add(index);
      // 首次访问该分区时主动加载数据
      ctrl.refreshData();
    }
  }

  void refreshOrScrollTop() {
    currentController.scrollToTopOrRefresh();
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
