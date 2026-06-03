import 'package:get/get.dart';
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
          scrollToTopOrRefresh();
        }
      },
    );
    super.onInit();
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

  void filterData() {
    // 先拷贝再赋值，避免遍历时 RxList 被并发修改
    switch (filterMode.value) {
      case 0:
        list.assignAll(FollowService.instance.followList.toList());
        break;
      case 1:
        list.assignAll(FollowService.instance.liveList.toList());
        break;
      case 2:
        list.assignAll(FollowService.instance.notLiveList.toList());
        break;
    }
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
