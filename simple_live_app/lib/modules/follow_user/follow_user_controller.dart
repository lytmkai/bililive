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
    await FollowService.instance.loadData();
    filterData();
    super.refreshData();
  }

  @override
  Future<List<FollowUser>> getData(int page, int pageSize) async {
    if (page > 1) return [];
    filterData();
    // ignore: invalid_use_of_protected_member
    return list.value;
  }

  void filterData() {
    switch (filterMode.value) {
      case 0:
        list.assignAll(FollowService.instance.followList);
        break;
      case 1:
        list.assignAll(FollowService.instance.liveList);
        break;
      case 2:
        list.assignAll(FollowService.instance.notLiveList);
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
