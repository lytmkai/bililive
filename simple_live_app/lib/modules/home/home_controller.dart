import 'dart:async';

import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/fav_category.dart';
import 'package:simple_live_app/modules/home/home_list_controller.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/routes/route_path.dart';
import 'package:simple_live_app/services/db_service.dart';
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

  /// 收藏的子分区列表
  var favCategories = <FavCategory>[].obs;

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
    loadFavorites();
  }

  /// 初始化默认的 "推荐" 控制器（category=null，不分过滤）
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
      // 启动时预加载热门分区的首屏数据
      _preWarmPartitions();
    } catch (e) {
      sectionNames.value = ["推荐"];
    } finally {
      isLoadingAreas.value = false;
    }
  }

  /// 获取或创建指定索引的分区控制器
  ///
  /// index=0 → "推荐" (category=null)
  /// index>0 → 对应 areas[index-1] 的分区（传 LiveCategory 对象）
  HomeListController getController(int index) {
    if (!_controllers.containsKey(index)) {
      final site = Sites.allSites[Constant.kBiliBili]!;
      LiveCategory? category;
      if (index > 0 && index - 1 < areas.length) {
        category = areas[index - 1];
      }
      final ctrl = HomeListController(site, category: category);
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
      ctrl.refreshData();
    }
  }

  void refreshOrScrollTop() {
    currentController.scrollToTopOrRefresh();
  }

  void toSearch() {
    Get.toNamed(RoutePath.kSearch);
  }

  /// 加载收藏的分区列表
  void loadFavorites() {
    favCategories.value = DBService.instance.getFavCategories();
  }

  /// 通过子分区名查找子分区对象并跳转到分类详情页
  void navigateToSubCategory(LiveCategory parent, String subName) {
    final sub = parent.children.firstWhereOrNull((c) => c.name == subName);
    if (sub != null) {
      final site = Sites.allSites[Constant.kBiliBili]!;
      final siblingNames = parent.children.map((c) => c.name).toList();
      AppNavigator.toCategoryDetail(
        site: site,
        category: sub,
        parentAreaName: parent.name,
        siblingNames: siblingNames,
      );
    }
  }

  /// 启动时预加载前 N 个分区的首屏数据（错开执行避免瞬间高并发）
  void _preWarmPartitions() {
    if (areas.isEmpty) return;
    final warmCount = areas.length < 3 ? areas.length : 3;
    for (var i = 0; i < warmCount; i++) {
      Future.delayed(Duration(milliseconds: (i + 1) * 500), () {
        final ctrl = getController(i + 1);
        if (!_activeControllers.contains(i + 1)) {
          _activeControllers.add(i + 1);
          ctrl.refreshData();
        }
      });
    }
  }

  @override
  void onClose() {
    streamSubscription?.cancel();
    super.onClose();
  }
}
