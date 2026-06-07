import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:simple_live_app/app/constant.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/models/db/fav_category.dart';
import 'package:simple_live_app/modules/category/custom_category_controller.dart';
import 'package:simple_live_app/modules/home/home_controller.dart';
import 'package:simple_live_app/modules/home/home_list_view.dart';
import 'package:simple_live_app/routes/app_navigation.dart';
import 'package:simple_live_core/simple_live_core.dart';

class HomePage extends GetView<HomeController> {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        leading: Obx(() {
          final ctrl = controller.currentController;
          final isLoading = ctrl.pageLoadding.value;
          if (isLoading) {
            final progress = ctrl.loadingProgress.value;
            // 刚开始加载时（progress==0）用不定圈，有进度后用百分比
            return Padding(
              padding: const EdgeInsets.all(10),
              child: SizedBox(
                width: 36,
                height: 36,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress > 0 ? progress : null,
                      strokeWidth: 2.5,
                    ),
                    if (progress > 0)
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }
          return IconButton(
            onPressed: () => ctrl.refreshData(),
            icon: const Icon(Icons.refresh),
            tooltip: '刷新',
          );
        }),
        title: _buildSectionSelector(context),
        actions: [
          IconButton(
            onPressed: controller.toSearch,
            icon: const Icon(Icons.search),
          )
        ],
      ),
      body: _buildBody(),
    );
  }

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

  void _showCategoryMenu(BuildContext context) {
    controller.loadFavorites();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _CategoryMenuSheet(
        controller: controller,
        areas: controller.areas.toList(),
        favs: controller.favCategories.toList(),
      ),
    );
  }

  Widget _buildBody() {
    return Obx(() {
      final index = controller.selectedSectionIndex.value;
      if (controller.sectionNames.length <= 1 && controller.isLoadingAreas.value) {
        return const Center(child: CircularProgressIndicator());
      }
      return HomeListView(
        Constant.kBiliBili,
        externalController: controller.getController(index),
        key: ValueKey('section_$index'),
      );
    });
  }
}

/// 分区选择底部菜单（快照模式：打开时读取当前数据，不依赖 Obx）
class _CategoryMenuSheet extends StatelessWidget {
  final HomeController controller;
  final List<LiveCategory> areas;
  final List<FavCategory> favs;

  const _CategoryMenuSheet({
    required this.controller,
    required this.areas,
    required this.favs,
  });

  @override
  Widget build(BuildContext context) {
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
            child: Text('切换分区',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ),
          const Divider(),
          _SectionTile(
            title: '推荐',
            isFavorite: false,
            onTap: () {
              controller.switchSection(0);
              Navigator.pop(context);
            },
          ),
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
          const Divider(height: 1),
          for (var i = 0; i < areas.length; i++)
            _ParentCategoryTile(
              category: areas[i],
              onSelect: () {
                controller.switchSection(i + (controller.hasCustomSubCategory ? 2 : 1));
                Navigator.pop(context);
              },
              onSubSelect: (name) {
                Navigator.pop(context);
                Future.delayed(Duration.zero, () {
                  controller.navigateToSubCategory(areas[i], name);
                });
              },
              onSubPin: (sub) {
                final saved = SavedSubCategory.fromLiveSubCategory(
                  sub,
                  parentName: areas[i].name,
                );
                controller.setCustomSubCategory(saved);
                Navigator.pop(context);
              },
            ),
          if (favs.isNotEmpty) ...[
            const Divider(indent: 16, endIndent: 16),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text('我的收藏',
                  style: TextStyle(fontSize: 14, color: Colors.grey)),
            ),
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
          ],
        ],
      ),
    );
  }
}

/// 父分区可展开项目
class _ParentCategoryTile extends StatefulWidget {
  final LiveCategory category;
  final VoidCallback onSelect;
  final void Function(String areaName) onSubSelect;
  final void Function(LiveSubCategory sub) onSubPin;

  const _ParentCategoryTile({
    required this.category,
    required this.onSelect,
    required this.onSubSelect,
    required this.onSubPin,
  });

  @override
  State<_ParentCategoryTile> createState() => _ParentCategoryTileState();
}

class _ParentCategoryTileState extends State<_ParentCategoryTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: widget.onSelect,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(widget.category.name,
                      style: const TextStyle(fontSize: 16)),
                ),
                GestureDetector(
                  onTap: () => setState(() => _expanded = !_expanded),
                  child: SizedBox(
                    width: 36,
                    height: 36,
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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
                      onTap: () => widget.onSubPin(sub),
                        child: const SizedBox(
                          width: 36,
                          height: 36,
                          child: Icon(Icons.push_pin_outlined,
                              size: 18, color: Colors.grey),
                        ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// 简单分区项（推荐）
class _SectionTile extends StatelessWidget {
  final String title;
  final bool isFavorite;
  final VoidCallback onTap;

  const _SectionTile({
    required this.title,
    required this.isFavorite,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            if (isFavorite)
              const Icon(Icons.star, size: 18, color: Colors.amber)
            else
              const SizedBox(width: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}

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
                child: Icon(Icons.push_pin_outlined,
                    size: 18, color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
