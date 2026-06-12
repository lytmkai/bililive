import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/utils.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/services/follow_service.dart';

class FollowUserController extends BasePageController<FollowUser> {
  /// 0:全部 1:直播中 2:未直播
  var filterMode = 0.obs;

  @override
  void onInit() {
    EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 1) {
          refreshData();
        }
      },
    );
    super.onInit();
  }

  @override
  void onReady() {
    refreshData();
    super.onReady();
  }

  @override
  Future refreshData() async {
    try {
      await FollowService.instance.loadData();
      filterData();
      pageEmpty.value = list.isEmpty;
      pageError.value = false;
    } catch (e) {
      handleError(e, showPageError: true);
    } finally {
      pageLoadding.value = false;
      easyRefreshController.finishRefresh();
      easyRefreshController.resetLoadState();
    }
  }

  @override
  Future<List<FollowUser>> getData(int page, int pageSize) async {
    // FollowUserController doesn't use paginated network fetch.
    // Data is loaded via FollowService.loadData() and filtered via filterData().
    return [];
  }

  /// 置顶直播间数量
  int get pinnedCount {
    final pinnedIds = AppSettingsController.instance.pinnedFollowIds;
    var count = 0;
    for (final item in list) {
      if (pinnedIds.contains(item.id)) count++;
    }
    return count;
  }

  void filterData() {
    // 先拷贝再赋值，避免遍历时 RxList 被并发修改
    List<FollowUser> source;
    switch (filterMode.value) {
      case 0:
        source = FollowService.instance.followList.toList();
        break;
      case 1:
        source = FollowService.instance.liveList.toList();
        break;
      case 2:
        source = FollowService.instance.notLiveList.toList();
        break;
      default:
        source = [];
    }

    // 置顶排序：pinned 项排前面
    final pinnedIds = AppSettingsController.instance.pinnedFollowIds;
    source.sort((a, b) {
      final aPinned = pinnedIds.contains(a.id);
      final bPinned = pinnedIds.contains(b.id);
      if (aPinned && !bPinned) return -1;
      if (!aPinned && bPinned) return 1;
      return 0;
    });

    list.assignAll(source);
  }

  void setFilterMode(int mode) {
    filterMode.value = mode;
    filterData();
  }

  void removeItem(FollowUser item) async {
    var result = await Utils.showAlertDialog(
      "确定要取消关注${item.userName}吗?",
      title: "取消关注",
    );
    if (!result) return;
    await FollowService.instance.removeFollow(item.id);
    refreshData();
  }
}
