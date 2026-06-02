import 'dart:async';

import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/event_bus.dart';
import 'package:simple_live_app/app/log.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/follow_user.dart';
import 'package:simple_live_app/services/db_service.dart';

class FollowService extends GetxService {
  static FollowService get instance => Get.find<FollowService>();

  StreamSubscription<dynamic>? subscription;

  /// 关注用户列表
  RxList<FollowUser> followList = RxList<FollowUser>();

  /// 直播中的用户列表
  RxList<FollowUser> liveList = RxList<FollowUser>();

  /// 未直播的用户列表
  RxList<FollowUser> notLiveList = RxList<FollowUser>();

  /// 是否正在更新
  var updating = false.obs;

  @override
  void onInit() {
    subscription = EventBus.instance.listen(Constant.kUpdateFollow, (p0) {
      loadData();
    });
    super.onInit();
  }

  /// 加载关注列表并检查直播状态
  Future<void> loadData() async {
    followList.value = DBService.instance.followBox.values.toList();
    if (followList.isEmpty) {
      liveList.clear();
      notLiveList.clear();
      return;
    }

    updating.value = true;
    List<FollowUser> live = [];
    List<FollowUser> notLive = [];

    for (var user in followList.toList()) {
      try {
        var siteInfo = Sites.allSites[user.siteId];
        if (siteInfo == null) continue;
        var isLive =
            await siteInfo.liveSite.getLiveStatus(roomId: user.roomId);
        user.liveStatus.value = isLive ? 2 : 1;
        if (isLive) {
          live.add(user);
        } else {
          notLive.add(user);
        }
      } catch (e) {
        Log.logPrint(e);
        user.liveStatus.value = 0; // 读取失败
        notLive.add(user);
      }
    }

    liveList.value = live;
    notLiveList.value = notLive;
    updating.value = false;
  }

  /// 添加关注
  void addFollow(FollowUser follow) {
    DBService.instance.addFollow(follow);
    loadData();
  }

  /// 取消关注
  Future<void> removeFollow(String id) async {
    await DBService.instance.followBox.delete(id);
    loadData();
  }

  @override
  void onClose() {
    subscription?.cancel();
    super.onClose();
  }
}
