# Custom Default Home Sub-Category Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Allow users to pin a specific B站 sub-category as their default home tab, loading its rooms via `getAreaRooms` instead of the recommendation API + client-side filtering.

**Architecture:** A `SavedSubCategory` model (already exists in `custom_category_controller.dart`) is persisted to `LocalStorageService`. `HomeController` inserts the pinned sub-category into `sectionNames` at position 1. `HomeListController` gains a dual-mode data-loading path: when `subCategory` is set, it uses `getAreaRooms` (6-page batches, no client filtering); otherwise uses the existing `getRecommendRooms` path. The bottom sheet UI gains pin/unpin icons on sub-category rows.

**Tech Stack:** Flutter, GetX, Hive, dart_simple_live (simple_live_core)

---

### Task 1: Storage — Add key and settings methods

**Files:**
- Modify: `simple_live_app/lib/services/local_storage_service.dart:173`
- Modify: `simple_live_app/lib/app/controller/app_settings_controller.dart:147`

- [ ] **Step 1: Add storage key constant**

In `local_storage_service.dart`, add after line 172 (`kCustomCategories`):

```dart
  /// 首页默认分区
  static const String kHomeDefaultCategory = "HomeDefaultCategory";
```

- [ ] **Step 2: Add Rx field, load, and set methods to AppSettingsController**

In `app_settings_controller.dart`, add the import at the top:

```dart
import 'dart:convert';
import 'package:simple_live_app/modules/category/custom_category_controller.dart';
```

Add the field after line 21 (`var firstRun = false;`):

```dart
  var homeDefaultCategory = Rxn<SavedSubCategory>();
```

In `onInit()`, before `super.onInit()` (line 147), add:

```dart
    loadHomeDefaultCategory();
```

Add the two methods after `initHomeSort()` (after line 188):

```dart
  void loadHomeDefaultCategory() {
    final raw = LocalStorageService.instance
        .getValue<String>(LocalStorageService.kHomeDefaultCategory, '');
    if (raw.isEmpty) return;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      homeDefaultCategory.value = SavedSubCategory.fromJson(json);
    } catch (_) {
      homeDefaultCategory.value = null;
    }
  }

  void setHomeDefaultCategory(SavedSubCategory? cat) {
    homeDefaultCategory.value = cat;
    if (cat == null) {
      LocalStorageService.instance
          .removeValue(LocalStorageService.kHomeDefaultCategory);
    } else {
      final encoded = jsonEncode(cat.toJson());
      LocalStorageService.instance
          .setValue(LocalStorageService.kHomeDefaultCategory, encoded);
    }
  }
```

- [ ] **Step 3: Commit**

```bash
git add simple_live_app/lib/services/local_storage_service.dart simple_live_app/lib/app/controller/app_settings_controller.dart
git commit -m "feat: add home default category storage and settings"
```

---

### Task 2: HomeListController — Dual-mode data loading

**Files:**
- Modify: `simple_live_app/lib/modules/home/home_list_controller.dart:7-37`

- [ ] **Step 1: Add `subCategory` field and adjust `_batchSize`**

Replace the existing field declarations (lines 7-37) with:

```dart
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
```

- [ ] **Step 2: Add `_refillFromArea` method for sub-category mode**

Add after `_refillFromRecommendations` (after line 146):

```dart
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
```

- [ ] **Step 3: Branch `_refillPool` to choose data source**

Replace the existing `_refillPool` method (lines 62-89) with:

```dart
  /// 补充房间池
  Future _refillPool() async {
    if (_fetching) return;
    _fetching = true;
    final gen = _generation;

    var retries = 0;
    try {
      if (subCategory != null) {
        await _refillFromArea(gen);
        while (_roomPool.isEmpty && retries < 2 && _generation == gen) {
          retries++;
          debugPrint(
              '[HomeList] pool empty, retry #$retries from p$_recApiPage');
          await _refillFromArea(gen);
        }
      } else {
        await _refillFromRecommendations(gen);
        while (_roomPool.isEmpty && retries < 2 && _generation == gen) {
          retries++;
          debugPrint(
              '[HomeList] pool empty after batch, retry #$retries from p$_recApiPage');
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
```

Remove the old `_refillPool` comment block (lines 57-61): `/// 补充房间池\n///\n...`.

- [ ] **Step 4: Commit**

```bash
git add simple_live_app/lib/modules/home/home_list_controller.dart
git commit -m "feat: add subCategory mode to HomeListController with getAreaRooms data source"
```

---

### Task 3: HomeController — Custom section management

**Files:**
- Modify: `simple_live_app/lib/modules/home/home_controller.dart:1-163`

- [ ] **Step 1: Add imports**

Add after the existing imports (line 12):

```dart
import 'package:simple_live_app/app/controller/app_settings_controller.dart';
import 'package:simple_live_app/modules/category/custom_category_controller.dart';
```

- [ ] **Step 2: Add custom sub-category field**

Add after line 36 (`var favCategories`):

```dart
  /// 自定义默认首页子分区
  SavedSubCategory? get customSubCategory =>
      AppSettingsController.instance.homeDefaultCategory.value;

  bool get hasCustomSubCategory => customSubCategory != null;
```

- [ ] **Step 3: Adjust `onInit` to set initial selected index**

Replace `onInit` (lines 38-52) with:

```dart
  @override
  void onInit() {
    super.onInit();
    streamSubscription = EventBus.instance.listen(
      EventBus.kBottomNavigationBarClicked,
      (index) {
        if (index == 0) {
          refreshOrScrollTop();
        }
      },
    );
    _initDefaultController();
    // 如果有自定义子分区，默认选中它（索引 1）
    if (hasCustomSubCategory) {
      selectedSectionIndex.value = 1;
    }
    _initCustomController();
    _loadAreas();
    loadFavorites();
  }
```

- [ ] **Step 4: Add `_initCustomController` method**

Add after `_initDefaultController` (after line 64):

```dart
  /// 初始化自定义子分区控制器
  void _initCustomController() {
    if (!hasCustomSubCategory) return;
    final site = Sites.allSites[Constant.kBiliBili]!;
    final ctrl = HomeListController(
      site,
      subCategory: customSubCategory!.toLiveSubCategory(),
    );
    Get.put(ctrl, tag: 'home_section_1');
    _controllers[1] = ctrl;
    _activeControllers.add(1);
    ctrl.refreshData();
  }
```

- [ ] **Step 5: Adjust `_loadAreas` to insert custom name**

Replace the `_loadAreas` method (lines 67-80) with:

```dart
  /// 从 B站 API 加载分区列表
  Future<void> _loadAreas() async {
    isLoadingAreas.value = true;
    try {
      final site = Sites.allSites[Constant.kBiliBili]!;
      areas.value = await site.liveSite.getCategores();
      if (hasCustomSubCategory) {
        sectionNames.value = [
          "推荐",
          customSubCategory!.name,
          ...areas.map((a) => a.name),
        ];
      } else {
        sectionNames.value = ["推荐", ...areas.map((a) => a.name)];
      }
      // 启动时预加载热门分区的首屏数据
      _preWarmPartitions();
    } catch (e) {
      if (hasCustomSubCategory) {
        sectionNames.value = ["推荐", customSubCategory!.name];
      } else {
        sectionNames.value = ["推荐"];
      }
    } finally {
      isLoadingAreas.value = false;
    }
  }
```

- [ ] **Step 6: Adjust `getController` for custom section index**

Replace the `getController` method (lines 82-98) with:

```dart
  /// 获取或创建指定索引的分区控制器
  ///
  /// index=0 → "推荐" (category=null)
  /// index=1 → 自定义子分区 (如果 customSubCategory 不为 null)
  /// index>=2 (或 index>=1 无自定义时) → 父分区 areas[index-offset]
  HomeListController getController(int index) {
    if (!_controllers.containsKey(index)) {
      final site = Sites.allSites[Constant.kBiliBili]!;
      if (index == 1 && hasCustomSubCategory) {
        final ctrl = HomeListController(
          site,
          subCategory: customSubCategory!.toLiveSubCategory(),
        );
        Get.put(ctrl, tag: 'home_section_$index');
        _controllers[index] = ctrl;
      } else {
        final areaOffset = hasCustomSubCategory ? 2 : 1;
        final areaIndex = index - areaOffset;
        LiveCategory? category;
        if (areaIndex >= 0 && areaIndex < areas.length) {
          category = areas[areaIndex];
        }
        final ctrl = HomeListController(site, category: category);
        Get.put(ctrl, tag: 'home_section_$index');
        _controllers[index] = ctrl;
      }
    }
    return _controllers[index]!;
  }
```

- [ ] **Step 7: Add set/clear custom sub-category methods**

Add after `_preWarmPartitions` (after line 156):

```dart
  /// 设置自定义默认首页子分区
  void setCustomSubCategory(SavedSubCategory cat) {
    AppSettingsController.instance.setHomeDefaultCategory(cat);
    _controllers.remove(1);
    _activeControllers.remove(1);
    _initCustomController();
    _rebuildSectionNames();
    selectedSectionIndex.value = 1;
  }

  /// 清除自定义默认首页子分区
  void clearCustomSubCategory() {
    AppSettingsController.instance.setHomeDefaultCategory(null);
    _controllers.remove(1);
    _activeControllers.remove(1);
    _rebuildSectionNames();
    selectedSectionIndex.value = 0;
  }

  void _rebuildSectionNames() {
    if (hasCustomSubCategory) {
      sectionNames.value = [
        "推荐",
        customSubCategory!.name,
        ...areas.map((a) => a.name),
      ];
    } else {
      sectionNames.value = ["推荐", ...areas.map((a) => a.name)];
    }
  }
```

- [ ] **Step 8: Commit**

```bash
git add simple_live_app/lib/modules/home/home_controller.dart
git commit -m "feat: integrate custom sub-category into HomeController section management"
```

---

### Task 4: HomePage UI — Pin/unpin in bottom sheet and custom indicator

**Files:**
- Modify: `simple_live_app/lib/modules/home/home_page.dart:1-313`

- [ ] **Step 1: Add import**

Add after line 8:

```dart
import 'package:simple_live_app/modules/category/custom_category_controller.dart';
```

- [ ] **Step 2: Show custom indicator in section selector title**

In `_buildSectionSelector` (lines 68-91), replace the title row with:

```dart
  Widget _buildSectionSelector(BuildContext context) {
    return Obx(() {
      final names = controller.sectionNames;
      final currentName = names.isNotEmpty &&
              controller.selectedSectionIndex.value < names.length
          ? names[controller.selectedSectionIndex.value]
          : '推荐';
      final isCustom =
          controller.hasCustomSubCategory &&
          controller.selectedSectionIndex.value == 1;
      return GestureDetector(
        onTap: () => _showCategoryMenu(context),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isCustom)
              const Padding(
                padding: EdgeInsets.only(right: 4),
                child: Icon(Icons.push_pin, size: 14),
              ),
            Flexible(
              child: Text(
                currentName,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(width: 2),
            const Icon(Icons.arrow_drop_down, size: 20),
          ],
        ),
      );
    });
  }
```

- [ ] **Step 3: Add custom sub-category row to bottom sheet**

In `_CategoryMenuSheet.build` (lines 138-205), after the "推荐" `_SectionTile` (line 161) and before the `Divider(height: 1)` (line 162), add:

```dart
          if (controller.hasCustomSubCategory)
            _CustomSectionTile(
              title: controller.customSubCategory!.name,
              onTap: () {
                controller.switchSection(1);
                Navigator.pop(context);
              },
              onUnpin: () {
                controller.clearCustomSubCategory();
                Navigator.pop(context);
              },
            ),
```

- [ ] **Step 4: Add pin icon to sub-category rows in expanded parent categories**

In `_ParentCategoryTileState.build` (lines 228-279), replace the sub-category row (lines 260-276) with:

```dart
        if (_expanded)
          ...widget.category.children.map(
            (sub) => InkWell(
              onTap: () => widget.onSubSelect(sub.name),
              child: Padding(
                padding: const EdgeInsets.only(
                    left: 36, right: 12, top: 8, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.subdirectory_arrow_right,
                        size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(sub.name,
                          style: const TextStyle(fontSize: 14)),
                    ),
                    GestureDetector(
                      onTap: () {
                        final saved = SavedSubCategory.fromLiveSubCategory(
                          sub,
                          parentName: widget.category.name,
                        );
                        controller.setCustomSubCategory(saved);
                        Navigator.pop(context);
                      },
                      child: const SizedBox(
                        width: 36,
                        height: 36,
                        child: Icon(Icons.push_pin_outline,
                            size: 18, color: Colors.grey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
```

- [ ] **Step 5: Add pin icon to favorites in "我的收藏" section**

Replace the fav item builder (lines 184-200) with:

```dart
            for (final f in favs)
              _FavSectionTile(
                title: '${f.parentAreaName} · ${f.areaName}',
                onTap: () {
                  Navigator.pop(context);
                  Future.delayed(Duration.zero, () {
                    final sub = LiveSubCategory(
                      id: f.areaId,
                      name: f.areaName,
                      parentId: f.parentAreaId,
                    );
                    final site = Sites.allSites[Constant.kBiliBili]!;
                    AppNavigator.toCategoryDetail(site: site, category: sub);
                  });
                },
                onPin: () {
                  final saved = SavedSubCategory(
                    id: f.areaId,
                    name: f.areaName,
                    parentId: f.parentAreaId,
                    parentName: f.parentAreaName,
                  );
                  controller.setCustomSubCategory(saved);
                  Navigator.pop(context);
                },
              ),
```

- [ ] **Step 6: Add new widget classes at file bottom**

Add after `_SectionTile` (after line 313):

```dart
/// 自定义分区项（底部菜单中，带取消固定按钮）
class _CustomSectionTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final VoidCallback onUnpin;

  const _CustomSectionTile({
    required this.title,
    required this.onTap,
    required this.onUnpin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.push_pin, size: 18, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            GestureDetector(
              onTap: onUnpin,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.close, size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 收藏分区项（带固定图标）
class _FavSectionTile extends StatelessWidget {
  final String title;
  final VoidCallback onTap;
  final VoidCallback onPin;

  const _FavSectionTile({
    required this.title,
    required this.onTap,
    required this.onPin,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.star, size: 18, color: Colors.amber),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title, style: const TextStyle(fontSize: 16)),
            ),
            GestureDetector(
              onTap: onPin,
              child: const SizedBox(
                width: 36,
                height: 36,
                child: Icon(Icons.push_pin_outline,
                    size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 7: Commit**

```bash
git add simple_live_app/lib/modules/home/home_page.dart
git commit -m "feat: add pin/unpin UI for custom default sub-category in home bottom sheet"
```

---

### Task 5: Verification

**Files:** None (analysis only)

- [ ] **Step 1: Run static analysis**

```bash
cd simple_live_app && flutter analyze
```

Expected: No errors. Warnings may exist pre-existing but no new ones introduced.

- [ ] **Step 2: Verify no compile errors**

```bash
cd simple_live_app && flutter build apk --debug
```

Expected: Build succeeds.

- [ ] **Step 3: Manual verification checklist**

| Check | Expected |
|-------|----------|
| `AppSettingsController.homeDefaultCategory` starts null | No custom section inserted |
| Pin a sub-category from bottom sheet | sectionNames shows it at index 1, selectedSectionIndex switches to 1 |
| AppBar title shows pin icon for custom section | Push-pin icon visible next to name |
| Relaunch app | Custom section persists (Hive read on startup) |
| Unpin from bottom sheet | Section removed, falls back to "推荐" (index 0) |
| Loading indicator works for custom section | Progress percentage shows during pool fill |
| Custom section loads rooms via getAreaRooms | Check debug logs: `[HomeList] area batch done:` instead of `filter "..."` |

---

## Task Dependency Graph

```
Task 1 (Storage) ──┐
                   ├──> Task 3 (HomeController) ──> Task 4 (HomePage UI)
Task 2 (HomeListCtrl) ┘
```

## Parallel Execution Opportunities

- **Task 1** and **Task 2** are independent — run in parallel.
- **Task 3** depends on both 1 and 2.
- **Task 4** depends on 3.
- **Task 5** runs after all.
