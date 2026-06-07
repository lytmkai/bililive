import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

class HomeListController extends BasePageController<LiveRoomItem> {
  final Site site;

  /// 父分区对象，null 表示"推荐"（全站推荐，不过滤）
  final LiveCategory? category;

  /// 子分区对象（自定义默认首页），非 null 时使用 getAreaRooms 加载
  final LiveSubCategory? subCategory;

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

  /// 加载进度 0.0~1.0，供 UI 显示百分比进度圈
  var loadingProgress = 0.0.obs;

  HomeListController(this.site, {this.category, this.subCategory}) {
    pageSize = 15;
  }

  /// 当 subCategory 不为 null 时，使用 getAreaRooms 直接加载（6页/批，房间已预过滤）
  /// 当 category 不为 null 时，使用推荐 API + 客户端增强过滤（25页/批）
  /// 否则为"推荐"模式（10页/批，不过滤）
  int get _batchSize {
    if (subCategory != null) return 6;
    return category != null ? 25 : 10;
  }

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
    loadingProgress.value = 0.0;

    await loadData();
    if (_generation != gen) return;
  }

  /// 补充房间池
  ///
  /// subCategory ≠ null → 使用 getAreaRooms 直接加载（无需客户端匹配）
  /// 否则 → 推荐 API + 客户端增强过滤（原有逻辑）。
  /// 最多重试 2 次空池补充。
  Future _refillPool() async {
    if (_fetching) return;
    _fetching = true;
    final gen = _generation;
    final useAreaApi = subCategory != null;

    var retries = 0;
    try {
      if (useAreaApi) {
        await _refillFromArea(gen);
      } else {
        await _refillFromRecommendations(gen);
      }
      while (_roomPool.isEmpty && retries < 2 && _generation == gen) {
        retries++;
        debugPrint(
            '[HomeList] pool empty after batch, retry #$retries from p$_recApiPage');
        if (useAreaApi) {
          await _refillFromArea(gen);
        } else {
          await _refillFromRecommendations(gen);
        }
      }
      if (_roomPool.isEmpty) {
        debugPrint(
            '[HomeList] pool still empty after $retries retries, giving up');
      } else {
        debugPrint(
            '[HomeList] pool filled: ${_roomPool.length} rooms (retries=$retries)');
      }
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
    var totalFetched = 0;
    var totalMatched = 0;
    var totalAdded = 0;

    for (var i = 0; i < _batchSize; i++) {
      if (_generation != gen) return;
      if (_recApiPage > _maxApiPage) _recApiPage = 1;

      try {
        var result =
            await site.liveSite.getRecommendRooms(page: _recApiPage);
        _recApiPage++;
        var items = result.items;
        totalFetched += items.length;

        if (category != null) {
          items = _matchPartition(items, category!);
          totalMatched += items.length;
        }

        var added = 0;
        for (var item in items) {
          if (_seenRoomIds.add(item.roomId)) {
            _roomPool.add(item);
            added++;
          }
        }
        totalAdded += added;

        // 更新加载进度
        loadingProgress.value = (i + 1) / _batchSize;

        if (!result.hasMore) {
          loadingProgress.value = 1.0;
          break;
        }
      } catch (e) {
        debugPrint(
            '[HomeList] getRecommendRooms failed: p$_recApiPage — $e');
        _recApiPage++;
      }
    }

    if (totalFetched > 0) {
      debugPrint(
          '[HomeList] batch done: fetched=$totalFetched matched=$totalMatched added=$totalAdded pool=${_roomPool.length}');
    }
  }

  /// 通过 getAreaRooms 直接拉取指定子分区房间（无需客户端过滤）
  Future _refillFromArea(int gen) async {
    var totalFetched = 0;
    var totalAdded = 0;

    for (var i = 0; i < _batchSize; i++) {
      if (_generation != gen) return;

      try {
        final result = await site.liveSite.getAreaRooms(
          subCategory!.id,
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

        loadingProgress.value = (i + 1) / _batchSize;

        if (!result.hasMore) {
          loadingProgress.value = 1.0;
          break;
        }
      } catch (e) {
        debugPrint('[HomeList] getAreaRooms p$_recApiPage failed: $e');
        _recApiPage++;
      }
    }

    if (totalFetched > 0) {
      debugPrint(
          '[HomeList] area batch done: fetched=$totalFetched added=$totalAdded pool=${_roomPool.length}');
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
    final parentMatch = <LiveRoomItem>[];
    final subMatch = <LiveRoomItem>[];

    for (var item in rooms) {
      // 策略 1：父分区名精确匹配
      if (item.parentAreaName == cat.name) {
        parentMatch.add(item);
        continue;
      }

      // 策略 1b：父分区名双向模糊匹配（B站 分类名可能有细微重命名）
      if (item.parentAreaName != null &&
          (item.parentAreaName!.contains(cat.name) ||
              cat.name.contains(item.parentAreaName!))) {
        parentMatch.add(item);
        continue;
      }

      // 策略 2：子分区名双向模糊匹配
      if (item.areaName != null) {
        var matched = false;
        for (var subName in subNames) {
          if (item.areaName!.contains(subName) ||
              subName.contains(item.areaName!)) {
            matched = true;
            break;
          }
        }
        if (matched) {
          subMatch.add(item);
        }
      }
    }

    if (parentMatch.isNotEmpty || subMatch.isNotEmpty) {
      debugPrint(
          '[HomeList] filter "${cat.name}": parent=${parentMatch.length} sub=${subMatch.length} / total=${rooms.length}');
    } else if (rooms.isNotEmpty) {
      // 全部未匹配 → 输出版本中房间的 parentAreaName 采样，方便调试
      var samples = rooms
          .take(3)
          .map((r) => '${r.parentAreaName ?? "null"}/${r.areaName ?? "null"}')
          .join(', ');
      debugPrint(
          '[HomeList] filter "${cat.name}" matched 0/${rooms.length}, samples: [$samples]');
    }

    // 父分区匹配排前面
    return [...parentMatch, ...subMatch];
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
