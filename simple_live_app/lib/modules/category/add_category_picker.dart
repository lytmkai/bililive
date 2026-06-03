import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:remixicon/remixicon.dart';
import 'package:simple_live_app/app/app_style.dart';
import 'package:simple_live_app/app/sites.dart';
import 'package:simple_live_app/modules/category/custom_category_controller.dart';
import 'package:simple_live_app/widgets/net_image.dart';
import 'package:simple_live_core/simple_live_core.dart';

class AddCategoryPicker extends StatefulWidget {
  final Site site;

  const AddCategoryPicker({super.key, required this.site});

  /// Show the picker as a bottom sheet
  static Future<void> show(BuildContext context, {required Site site}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => AddCategoryPicker(site: site),
    );
  }

  @override
  State<AddCategoryPicker> createState() => _AddCategoryPickerState();
}

class _AddCategoryPickerState extends State<AddCategoryPicker> {
  List<LiveCategory>? _categories;
  bool _loading = true;
  String? _error;
  final Set<String> _expandedCategories = {};

  CustomCategoryViewController get _customController {
    if (!Get.isRegistered<CustomCategoryViewController>()) {
      Get.put(CustomCategoryViewController());
    }
    return Get.find<CustomCategoryViewController>();
  }

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final result = await widget.site.liveSite.getCategores();
      if (mounted) {
        setState(() {
          _categories = result;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Image.asset(widget.site.logo, width: 24),
                  AppStyle.hGap8,
                  Text(
                    "${widget.site.name} - 添加分区",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Obx(() => Text(
                        "已选 ${_customController.savedList.length}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withAlpha(200),
                        ),
                      )),
                ],
              ),
            ),
            const Divider(height: 1),
            // Content
            Expanded(
              child: _buildContent(scrollController),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContent(ScrollController scrollController) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('加载失败: $_error'),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _loading = true;
                  _error = null;
                });
                _loadCategories();
              },
              icon: const Icon(Remix.restart_line),
              label: const Text('重试'),
            ),
          ],
        ),
      );
    }
    if (_categories == null || _categories!.isEmpty) {
      return const Center(child: Text('暂无分区数据'));
    }

    return ListView.builder(
      controller: scrollController,
      padding: AppStyle.edgeInsetsA12,
      itemCount: _categories!.length,
      itemBuilder: (_, i) {
        final category = _categories![i];
        return _buildCategorySection(category);
      },
    );
  }

  Widget _buildCategorySection(LiveCategory category) {
    final isExpanded = _expandedCategories.contains(category.id);
    final addedCount = category.children
        .where((sub) => _customController.contains(sub.id))
        .length;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppStyle.radius8,
        side: BorderSide(
          color: Theme.of(context).dividerColor.withAlpha(80),
        ),
      ),
      child: InkWell(
        borderRadius: AppStyle.radius8,
        onTap: () {
          setState(() {
            if (isExpanded) {
              _expandedCategories.remove(category.id);
            } else {
              _expandedCategories.add(category.id);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      category.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (addedCount > 0)
                    Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withAlpha(150),
                        borderRadius: AppStyle.radius4,
                      ),
                      child: Text(
                        '$addedCount',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  Text(
                    '${category.children.length}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(120),
                    ),
                  ),
                  AppStyle.hGap4,
                  Icon(
                    isExpanded
                        ? Remix.arrow_up_s_line
                        : Remix.arrow_down_s_line,
                    size: 20,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(150),
                  ),
                ],
              ),
              if (isExpanded) ...[
                AppStyle.vGap8,
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: category.children
                      .map((sub) =>
                          _buildSubCategoryChip(sub, category.name))
                      .toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubCategoryChip(LiveSubCategory sub, String parentName) {
    return Obx(() {
      final isAdded = _customController.contains(sub.id);
      return Material(
        color: isAdded
            ? Theme.of(context).colorScheme.primaryContainer.withAlpha(120)
            : Theme.of(context).colorScheme.surfaceContainerHighest.withAlpha(80),
        borderRadius: AppStyle.radius8,
        child: InkWell(
          borderRadius: AppStyle.radius8,
          onTap: isAdded
              ? () => _customController.remove(sub.id)
              : () => _customController.add(sub, parentName),
          child: Container(
            constraints: const BoxConstraints(minWidth: 80, maxWidth: 160),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sub.pic != null && sub.pic!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: NetImage(
                      sub.pic!,
                      width: 20,
                      height: 20,
                      borderRadius: 4,
                    ),
                  ),
                Flexible(
                  child: Text(
                    sub.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 13,
                      color: isAdded
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  isAdded ? Remix.checkbox_circle_fill : Remix.add_circle_line,
                  size: 18,
                  color: isAdded
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }
}
