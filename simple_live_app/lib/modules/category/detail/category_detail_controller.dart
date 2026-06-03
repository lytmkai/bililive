import 'package:flutter/widgets.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/fav_category.dart';
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_core/simple_live_core.dart';

class CategoryDetailController extends BasePageController<LiveRoomItem> {
  final Site site;
  final LiveSubCategory subCategory;
  final String? parentAreaName;
  /// 同父分区下所有子分区名，用于增强匹配（和 HomeListController 同策略）
  final List<String>? siblingNames;

  /// 房间池：所有已获取但尚未展示的直播间
  final List<LiveRoomItem> _roomPool = [];

  /// 去重集合
  final Set<String> _seenRoomIds = {};

  /// 推荐 API 页码
  int _recApiPage = 1;

  /// 代次计数器
  int _gen = 0;

  bool _fetching = false;

  /// getAreaRooms 每页返回 30 间已过滤的房间，少量页面足够填充池子
  static const int _batchSize = 6;

  CategoryDetailController({
    required this.site,
    required this.subCategory,
    this.parentAreaName,
    this.siblingNames,
  }) {
    pageSize = 15;
  }

  // ━━━━━━━━━━━━━━━━ 公共方法 ━━━━━━━━━━━━━━━━

  /// 手动刷新（AppBar 按钮调用）
  Future<void> manualRefresh() async {
    _gen++;
    _roomPool.clear();
    _seenRoomIds.clear();
    _recApiPage = 1;
    _fetching = false;
    currentPage = 1;
    list.value = [];
    loadding = false;
    await loadData();
  }

  @override
  Future<void> refreshData() async => manualRefresh();

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addPostFrameCallback((_) => manualRefresh());
  }

  /// 收藏/取消收藏当前子分区
  void toggleFavorite() {
    final db = DBService.instance;
    final sub = subCategory;
    if (db.isFavCategory(sub.id)) {
      db.removeFavCategory(sub.id);
    } else {
      db.addFavCategory(FavCategory(
        id: sub.id,
        parentAreaName: parentAreaName ?? '',
        areaName: sub.name,
        areaId: sub.id,
        parentAreaId: sub.parentId,
      ));
    }
    update();
  }

  // ━━━━━━━━━━━━━━━━ 池子逻辑 ━━━━━━━━━━━━━━━━

  /// 补充房间池
  Future<void> _refillPool() async {
    if (_fetching) return;
    _fetching = true;
    final gen = _gen;

    var retries = 0;
    try {
      await _refillFromArea(gen);
      while (_roomPool.isEmpty && retries < 2 && _gen == gen) {
        retries++;
        debugPrint(
            '[CatDetail] pool empty, retry #$retries from p$_recApiPage');
        await _refillFromArea(gen);
      }
      if (_roomPool.isEmpty) {
        debugPrint(
            '[CatDetail] pool still empty after $retries retries');
      } else {
        debugPrint(
            '[CatDetail] pool: ${_roomPool.length} rooms (retries=$retries)');
      }
    } finally {
      if (_gen == gen) _fetching = false;
    }
  }

  /// 通过 getAreaRooms 直接拉取指定子分区房间（房间已按 area_id 预过滤，无需客户端匹配）
  Future<void> _refillFromArea(int gen) async {
    var totalFetched = 0;
    var totalAdded = 0;

    for (var i = 0; i < _batchSize; i++) {
      if (_gen != gen) return;

      try {
        final result = await site.liveSite.getAreaRooms(
          subCategory.id,
          page: _recApiPage,
        );
        _recApiPage++;
        var items = result.items;
        totalFetched += items.length;

        for (final item in items) {
          if (_seenRoomIds.add(item.roomId)) {
            _roomPool.add(item);
            totalAdded++;
          }
        }

        if (!result.hasMore) break;
      } catch (e) {
        debugPrint('[CatDetail] getAreaRooms p$_recApiPage failed: $e');
        _recApiPage++;
      }
    }

    if (totalFetched > 0) {
      debugPrint(
          '[CatDetail] area batch done: fetched=$totalFetched added=$totalAdded pool=${_roomPool.length}');
    }
  }

  // ━━━━━━━━━━━━━━━━ 分页接口 ━━━━━━━━━━━━━━━━

  @override
  Future<List<LiveRoomItem>> getData(int page, int pageSize) async {
    if (_roomPool.length < pageSize) {
      await _refillPool();
    }

    if (_roomPool.isEmpty) return [];

    final count = pageSize < _roomPool.length ? pageSize : _roomPool.length;
    final items = _roomPool.sublist(0, count);
    _roomPool.removeRange(0, count);
    return items;
  }
}
