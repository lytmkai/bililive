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

  /// 防重入
  bool _loading = false;

  @override
  void onInit() {
    subscription = EventBus.instance.listen(Constant.kUpdateFollow, (p0) {
      loadData();
    });
    super.onInit();
  }

  /// 加载关注列表并检查直播状态
  Future<void> loadData() async {
    if (_loading) return;
    _loading = true;
    try {
      // 先拷贝出数据，避免在遍历时被其他代码修改
      final users = DBService.instance.followBox.values.toList();
      followList.value = users;

      if (users.isEmpty) {
        liveList.value = [];
        notLiveList.value = [];
        return;
      }

      updating.value = true;
      List<FollowUser> live = [];
      List<FollowUser> notLive = [];

      for (var user in users) {
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
          user.liveStatus.value = 0;
          notLive.add(user);
        }
      }

      // 原子性设置三个列表的值
      liveList.value = live;
      notLiveList.value = notLive;
      updating.value = false;
    } finally {
      _loading = false;
    }
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
