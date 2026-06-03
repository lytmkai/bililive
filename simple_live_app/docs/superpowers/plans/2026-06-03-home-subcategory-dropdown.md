# 首页分区下拉菜单支持子分区 + 收藏功能

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 首页左上角分区切换下拉菜单支持展开父分区查看子分区，点击子分区跳转到分类详情页，支持收藏分区并在下拉菜单中展示。

**Architecture:** 将当前 `PopupMenuButton` 替换为基于 `showModalBottomSheet` 的自定义可展开菜单。父分区点击切换首页内容，子分区点击通过现有的 `AppNavigator.toCategoryDetail()` 跳转到已有的 `CategoryDetailPage`。收藏数据用 Hive Box (`FavCategory`) 存储。

**Tech Stack:** Flutter / GetX / Hive / simple_live_core

---

## 现有基础设施（复用，不用改）

| 组件 | 作用 | 状态 |
|------|------|------|
| `CategoryDetailPage` + `CategoryDetailController` | 子分区房间列表，`getListByArea` + areaName 客户端过滤 | ✅ 海外 IP 可用 |
| `AppNavigator.toCategoryDetail()` | 跳转到分类详情页 | ✅ 已有 |
| `getCategores()` → `areas` (HomeController) | 完整分区树（含子分区） | ✅ 已缓存 |

---

## Task 1: 创建 FavCategory Hive 模型

**Files:** Create: `lib/models/db/fav_category.dart`

- [ ] **Step 1: 创建模型文件**

```dart
// lib/models/db/fav_category.dart
import 'package:hive/hive.dart';

part 'fav_category.g.dart';

@HiveType(typeId: 5)
class FavCategory extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String parentAreaName;
  @HiveField(2)
  final String areaName;
  @HiveField(3)
  final String areaId;
  @HiveField(4)
  final String parentAreaId;

  FavCategory({
    required this.id,
    required this.parentAreaName,
    required this.areaName,
    required this.areaId,
    required this.parentAreaId,
  });
}
```

- [ ] **Step 2: 运行 build_runner**

```bash
cd dart_simple_live/simple_live_app
flutter pub run build_runner build --delete-conflicting-outputs
```

Expected: `lib/models/db/fav_category.g.dart` generated.

---

## Task 2: 注册 Adapter + 扩展 DBService

**Files:** Modify: `lib/main.dart`, `lib/services/db_service.dart`

- [ ] **Step 1: main.dart**

Find `Hive.registerAdapter(FollowUserTagAdapter())` and add after:
```dart
Hive.registerAdapter(FavCategoryAdapter());
```

Add import:
```dart
import 'package:simple_live_app/models/db/fav_category.dart';
```

- [ ] **Step 2: DBService**

Add import:
```dart
import 'package:simple_live_app/models/db/fav_category.dart';
```

Add field:
```dart
late Box<FavCategory> favBox;
```

Add in `init()`:
```dart
favBox = await Hive.openBox("FavCategory");
```

Add CRUD methods at end:
```dart
List<FavCategory> getFavCategories() => favBox.values.toList();
bool isFavCategory(String areaId) => favBox.values.any((e) => e.areaId == areaId);
Future addFavCategory(FavCategory fav) async => await favBox.put(fav.areaId, fav);
Future removeFavCategory(String areaId) async => await favBox.delete(areaId);
```

---

## Task 3: 改造首页分区下拉菜单

**Files:** Modify: `lib/modules/home/home_page.dart`, `lib/modules/home/home_controller.dart`

- [ ] **Step 1: HomeController 添加菜单支持**

Edit `lib/modules/home/home_controller.dart`:

Add imports:
```dart
import 'package:simple_live_app/services/db_service.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:collection/collection.dart';
```

Add after `areas` field:
```dart
var favCategories = <FavCategory>[].obs;
```

In `onInit()`, add after `loadAreas()`:
```dart
loadFavorites();
```

Add methods:
```dart
void loadFavorites() {
  favCategories.value = DBService.instance.getFavCategories();
}

void navigateToSubCategory(LiveCategory parent, String subName) {
  final sub = parent.children.firstWhereOrNull((c) => c.name == subName);
  if (sub != null) {
    final site = Sites.allSites[Constant.kBiliBili]!;
    AppNavigator.toCategoryDetail(site: site, category: sub, parentAreaName: parent.name);
  }
}
```

- [ ] **Step 2: HomePage 替换 PopupMenuButton**

Edit `lib/modules/home/home_page.dart`:

Add imports at top:
```dart
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_app/models/db/fav_category.dart';
```

Replace the entire `AppBar` in `build()` (the current `title: Obx(...)` with `PopupMenuButton`):

```dart
appBar: AppBar(
  leading: const SizedBox(width: 0),
  leadingWidth: 0,
  title: _buildSectionSelector(context),
  actions: [
    IconButton(
      icon: Icon(controller.searchPreview.value ? Remix.eye_off_line : Remix.eye_line),
      onPressed: () => controller.searchPreview.toggle(),
      tooltip: "预览模式",
    ),
    IconButton(
      icon: const Icon(Remix.search_2_line),
      onPressed: () => AppNavigator.toSearch(),
      tooltip: "搜索",
    ),
  ],
),
```

Add `_buildSectionSelector` and `_showCategoryMenu` methods inside `HomePage` class:

```dart
Widget _buildSectionSelector(BuildContext context) {
  return GestureDetector(
    onTap: () => _showCategoryMenu(context),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 12),
        Obx(() {
          final sections = controller.sections;
          final index = controller.selectedSectionIndex.value;
          return Text(
            index < sections.length ? sections[index] : '推荐',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          );
        }),
        const Icon(Icons.arrow_drop_down, size: 20),
      ],
    ),
  );
}

void _showCategoryMenu(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _CategoryMenuSheet(controller: controller),
  );
}
```

- [ ] **Step 3: 添加菜单组件类**

Add the following three classes at the bottom of `home_page.dart` (outside `HomePage`):

```dart
class _CategoryMenuSheet extends StatelessWidget {
  final HomeController controller;
  const _CategoryMenuSheet({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final areas = controller.areas;
      final favs = controller.favCategories;
      return DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.3,
        expand: false,
        builder: (_, scroller) => ListView(
          controller: scroller,
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('切换分区', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            _SectionTile(
              title: '推荐',
              isFavorite: false,
              onTap: () { controller.switchSection(0); Navigator.pop(context); },
            ),
            const Divider(height: 1),
            for (var i = 0; i < areas.length; i++)
              _ParentCategoryTile(
                category: areas[i],
                onSelect: () { controller.switchSection(i + 1); Navigator.pop(context); },
                onSubSelect: (name) { controller.navigateToSubCategory(areas[i], name); Navigator.pop(context); },
              ),
            if (favs.isNotEmpty) ...[
              const Divider(indent: 16, endIndent: 16),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text('我的收藏', style: TextStyle(fontSize: 14, color: Colors.grey)),
              ),
              for (final f in favs)
                _SectionTile(
                  title: '${f.parentAreaName} · ${f.areaName}',
                  isFavorite: true,
                  onTap: () {
                    final sub = LiveSubCategory(id: f.areaId, name: f.areaName, parentId: f.parentAreaId);
                    AppNavigator.toCategoryDetail(site: Sites.allSites[Constant.kBiliBili]!, category: sub);
                    Navigator.pop(context);
                  },
                ),
            ],
          ],
        ),
      );
    });
  }
}

class _ParentCategoryTile extends StatefulWidget {
  final LiveCategory category;
  final VoidCallback onSelect;
  final void Function(String areaName) onSubSelect;

  const _ParentCategoryTile({required this.category, required this.onSelect, required this.onSubSelect});
  @override State<_ParentCategoryTile> createState() => _ParentCategoryTileState();
}

class _ParentCategoryTileState extends State<_ParentCategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      InkWell(
        onTap: widget.onSelect,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(children: [
            Expanded(child: Text(widget.category.name, style: const TextStyle(fontSize: 16))),
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: SizedBox(
                width: 36, height: 36,
                child: Icon(_expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, size: 20, color: Colors.grey),
              ),
            ),
          ]),
        ),
      ),
      if (_expanded)
        ...widget.category.children.map((sub) => InkWell(
          onTap: () => widget.onSubSelect(sub.name),
          child: Padding(
            padding: const EdgeInsets.only(left: 36, right: 20, top: 8, bottom: 8),
            child: Row(children: [
              const Icon(Icons.subdirectory_arrow_right, size: 16, color: Colors.grey),
              const SizedBox(width: 4),
              Text(sub.name, style: const TextStyle(fontSize: 14)),
            ]),
          ),
        )),
    ]);
  }
}

class _SectionTile extends StatelessWidget {
  final String title;
  final bool isFavorite;
  final VoidCallback onTap;

  const _SectionTile({required this.title, required this.isFavorite, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(children: [
          if (isFavorite) const Icon(Icons.star, size: 18, color: Colors.amber) else const SizedBox(width: 18),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontSize: 16)),
        ]),
      ),
    );
  }
}
```

---

## Task 4: 分类详情页收藏按钮

**Files:** Modify: `lib/modules/category/detail/category_detail_controller.dart`, `category_detail_page.dart`, `lib/routes/app_navigation.dart`, `lib/routes/app_pages.dart`

- [ ] **Step 1: 扩展 CategoryDetailController 接受 parentAreaName**

Edit `lib/modules/category/detail/category_detail_controller.dart`:

Add imports:
```dart
import 'package:simple_live_app/models/db/fav_category.dart';
import 'package:simple_live_app/services/db_service.dart';
```

Add field + update constructor:
```dart
final String? parentAreaName;

CategoryDetailController({
  required this.site,
  required this.subCategory,
  this.parentAreaName,
});
```

Add `toggleFavorite()`:
```dart
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
```

- [ ] **Step 2: CategoryDetailPage AppBar 加收藏按钮**

Edit `lib/modules/category/detail/category_detail_page.dart`:

Add import:
```dart
import 'package:simple_live_app/services/db_service.dart';
```

Replace `appBar:` with:
```dart
appBar: AppBar(
  title: Text(controller.subCategory.name),
  actions: [
    IconButton(
      icon: Obx(() {
        final isFav = DBService.instance.isFavCategory(controller.subCategory.id);
        return Icon(isFav ? Icons.star : Icons.star_border, color: isFav ? Colors.amber : null);
      }),
      onPressed: () => controller.toggleFavorite(),
    ),
  ],
),
```

- [ ] **Step 3: 更新路由支持 parentAreaName**

Edit `lib/routes/app_navigation.dart`:
```dart
static void toCategoryDetail({
  required Site site,
  required LiveSubCategory category,
  String? parentAreaName,
}) {
  Get.toNamed(RoutePath.kCategoryDetail, arguments: [site, category, parentAreaName]);
}
```

Edit `lib/routes/app_pages.dart`, find the CategoryDetail binding and change to:
```dart
binding: BindingsBuilder.put(
  () => CategoryDetailController(
    site: Get.arguments[0],
    subCategory: Get.arguments[1],
    parentAreaName: Get.arguments.length > 2 ? Get.arguments[2] : null,
  ),
),
```

---

## Task 5: 验证

- [ ] **Step 1: flutter analyze**

```bash
cd dart_simple_live/simple_live_app && flutter analyze
```
Expected: No issues found.

- [ ] **Step 2: build_runner 确认生成文件**

```bash
cd dart_simple_live/simple_live_app && flutter pub run build_runner build --delete-conflicting-outputs
```
Expected: No errors. `fav_category.g.dart` fresh.

---

## Self-Review

- [x] Home dropdown → sub-category navigation → favorite button: all covered
- [x] No placeholders: all code blocks are concrete, executable
- [x] Type consistency: `FavCategory` ↔ DBService methods align
- [x] Backward compatibility: `parentAreaName` optional (defaults null) — existing callers (`custom_category_view.dart`, `category_list_view.dart`) pass only `[site, category]`, which works correctly with `Get.arguments.length > 2` guard in `app_pages.dart`
