import 'package:simple_live_app/app/controller/base_controller.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_core/simple_live_core.dart';

class HomeListController extends BasePageController<LiveRoomItem> {
  final Site site;
  /// 分区ID，null 时为全站推荐
  String? parentAreaId;

  /// API 返回的完整结果缓存（B站 API 固定每页30条）
  List<LiveRoomItem> _cachedItems = [];
  int _apiPage = 0;

  HomeListController(this.site, {this.parentAreaId}) {
    pageSize = 8;
  }

  @override
  Future refreshData() async {
    _cachedItems = [];
    _apiPage = 0;
    currentPage = 1;
    list.value = [];
    await loadData();
  }

  @override
  Future<List<LiveRoomItem>> getData(int page, int pageSize) async {
    // 缓存耗尽时从 API 取新一页
    if (_cachedItems.isEmpty) {
      _apiPage++;
      var result = await site.liveSite.getRecommendRooms(
        page: _apiPage,
        parentAreaId: parentAreaId,
      );
      _cachedItems = result.items;
    }

    if (_cachedItems.isEmpty) return [];

    var count =
        pageSize < _cachedItems.length ? pageSize : _cachedItems.length;
    var items = _cachedItems.sublist(0, count);
    _cachedItems = _cachedItems.sublist(count);

    return items;
  }
}
