import 'package:flutter/foundation.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

class HomeListController extends BasePageController<LiveRoomItem> {
  final Site site;

  /// 父分区对象，null 表示"推荐"（全站推荐，不过滤）
  final LiveCategory? category;

  /// 房间池：所有已获取但尚未展示的直播间
  final List<LiveRoomItem> _roomPool = [];

  /// 去重集合：已加入池子的 roomId
  final Set<String> _seenRoomIds = {};

  /// 推荐 API 页码（单调递增，超过上限后循环回第 1 页）
  int _recApiPage = 1;
  static const int _maxApiPage = 20;

  bool _fetching = false;

  /// 代次计数器：每次 refreshData() +1，异步操作中检测代次变化以中止
  int _generation = 0;

  HomeListController(this.site, {this.category}) {
    pageSize = 15;
  }

  /// 过滤分区需要更大的拉取量（12 页 × 30 间 = 360 间/批 vs 推荐 4 页 = 120 间/批）
  int get _batchSize => category != null ? 12 : 4;

  @override
  Future refreshData() async {
    _generation++;
    final gen = _generation;

    _roomPool.clear();
    _seenRoomIds.clear();
    _recApiPage = 1;
    _fetching = false;
    currentPage = 1;
    list.value = [];
    loadding = false;

    await loadData();
    if (_generation != gen) return;
  }

  /// 补充房间池
  ///
  /// 统一使用推荐 API + 客户端增强过滤（放弃 getList，海外 IP 不可用）。
  /// 过滤分区拉 12 页/批（360 间），推荐 tab 拉 4 页（120 间）。
  Future _refillPool() async {
    if (_fetching) return;
    _fetching = true;
    final gen = _generation;
    try {
      await _refillFromRecommendations(gen);
    } finally {
      if (_generation == gen) {
        _fetching = false;
      }
    }
  }

  /// 通过 getRecommendRooms 拉取全站推荐 + 增强客户端过滤
  ///
  /// 过滤策略（按优先级）：
  /// 1. parentAreaName 精确匹配 (parentAreaName == cat.name)
  /// 2. areaName 与子分区列表的双向模糊匹配
  ///    — B站 API 返回的 areaName 和分类列表里的子分区名可能有细微差异
  ///    — 双向：item.areaName contains subName OR subName contains item.areaName
  Future _refillFromRecommendations(int gen) async {
    for (var i = 0; i < _batchSize; i++) {
      if (_generation != gen) return;
      if (_recApiPage > _maxApiPage) _recApiPage = 1;

      try {
        var result =
            await site.liveSite.getRecommendRooms(page: _recApiPage);
        _recApiPage++;
        var items = result.items;

        if (category != null) {
          items = _matchPartition(items, category!);
        }

        for (var item in items) {
          if (_seenRoomIds.add(item.roomId)) {
            _roomPool.add(item);
          }
        }

        if (!result.hasMore) break;
      } catch (e) {
        debugPrint(
            '[HomeList] getRecommendRooms failed: p$_recApiPage — $e');
        _recApiPage++;
      }
    }
  }

  /// 增强分区匹配算法
  ///
  /// 对推荐流中的每一间房，依次检查：
  /// 1. parentAreaName == cat.name → 父分区名精确匹配（B站 API 最可靠字段）
  /// 2. areaName 与子分区列表中任一个子分区名的双向模糊匹配
  ///
  /// 返回所有匹配的房间列表。
  List<LiveRoomItem> _matchPartition(
      List<LiveRoomItem> rooms, LiveCategory cat) {
    // 预计算子分区名集合，避免每次循环遍历完整列表
    final subNames = cat.children.map((s) => s.name).toSet();

    return rooms.where((item) {
      // 策略 1：父分区名精确匹配
      if (item.parentAreaName == cat.name) return true;

      // 策略 2：子分区名双向模糊匹配
      if (item.areaName != null) {
        for (var subName in subNames) {
          if (item.areaName!.contains(subName) ||
              subName.contains(item.areaName!)) {
            return true;
          }
        }
      }

      return false;
    }).toList();
  }

  @override
  Future<List<LiveRoomItem>> getData(int page, int pageSize) async {
    if (_roomPool.length < pageSize) {
      await _refillPool();
    }

    if (_roomPool.isEmpty) return [];

    var count =
        pageSize < _roomPool.length ? pageSize : _roomPool.length;
    var items = _roomPool.sublist(0, count);
    _roomPool.removeRange(0, count);
    return items;
  }
}
