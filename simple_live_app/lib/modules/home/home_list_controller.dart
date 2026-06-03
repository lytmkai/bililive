import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

class HomeListController extends BasePageController<LiveRoomItem> {
  final Site site;
  /// 客户端侧过滤：按 parentAreaName 筛选，null 时不过滤（全站推荐）
  String? filterAreaName;

  /// API 返回的完整结果缓存（B站 API 固定每页30条）
  List<LiveRoomItem> _cachedItems = [];
  int _apiPage = 0;

  HomeListController(this.site, {this.filterAreaName}) {
    pageSize = 8;
  }

  @override
  Future refreshData() async {
    _cachedItems = [];
    // 不重置 _apiPage，改为每次刷新推进到下一页获取不同直播间
    currentPage = 1;
    list.value = [];
    await loadData();
  }

  @override
  Future<List<LiveRoomItem>> getData(int page, int pageSize) async {
    // 缓存耗尽时从 API 取新一页，如果开启分区筛选且结果不足则继续取更多页
    while (_cachedItems.isEmpty) {
      _apiPage++;
      var result = await site.liveSite.getRecommendRooms(page: _apiPage);
      var items = result.items;
      // 客户端侧按分区名筛选
      if (filterAreaName != null && filterAreaName!.isNotEmpty) {
        items = result.items
            .where((item) => item.parentAreaName == filterAreaName)
            .toList();
      }
      _cachedItems = items;
      if (!result.hasMore) break; // 没有更多数据时退出循环
    }

    if (_cachedItems.isEmpty) return [];

    var count =
        pageSize < _cachedItems.length ? pageSize : _cachedItems.length;
    var items = _cachedItems.sublist(0, count);
    _cachedItems = _cachedItems.sublist(count);

    return items;
  }
}
