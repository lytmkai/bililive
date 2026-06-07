import 'dart:convert';

import 'package:get/get.dart';
import 'package:simple_live_app/services/local_storage_service.dart';
import 'package:simple_live_core/simple_live_core.dart';

class SavedSubCategory {
  final String id;
  final String name;
  final String? pic;
  final String parentId;
  final String parentName;

  SavedSubCategory({
    required this.id,
    required this.name,
    required this.parentId,
    required this.parentName,
    this.pic,
  });

  factory SavedSubCategory.fromLiveSubCategory(
    LiveSubCategory subCategory, {
    required String parentName,
  }) {
    return SavedSubCategory(
      id: subCategory.id,
      name: subCategory.name,
      pic: subCategory.pic,
      parentId: subCategory.parentId,
      parentName: parentName,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'pic': pic,
        'parentId': parentId,
        'parentName': parentName,
      };

  factory SavedSubCategory.fromJson(Map<String, dynamic> json) {
    return SavedSubCategory(
      id: json['id'] as String,
      name: json['name'] as String,
      pic: json['pic'] as String?,
      parentId: json['parentId'] as String,
      parentName: json['parentName'] as String,
    );
  }

  LiveSubCategory toLiveSubCategory() {
    return LiveSubCategory(
      id: id,
      name: name,
      pic: pic,
      parentId: parentId,
    );
  }
}

class CustomCategoryViewController extends GetxController {
  static CustomCategoryViewController get instance =>
      Get.find<CustomCategoryViewController>();

  var savedList = <SavedSubCategory>[].obs;

  /// 操作模式：null=正常, pin=图钉模式, delete=删除模式
  var mode = Rx<String?>(null);
  bool get isPinMode => mode.value == 'pin';
  bool get isDeleteMode => mode.value == 'delete';
  bool get isNormalMode => mode.value == null;

  void togglePinMode() {
    mode.value = mode.value == 'pin' ? null : 'pin';
  }

  void toggleDeleteMode() {
    mode.value = mode.value == 'delete' ? null : 'delete';
  }

  @override
  void onInit() {
    super.onInit();
    loadFromStorage();
  }

  void loadFromStorage() {
    final raw = LocalStorageService.instance
        .getValue<String>(LocalStorageService.kCustomCategories, '');
    if (raw.isEmpty) return;
    try {
      final List<dynamic> decoded = json.decode(raw) as List<dynamic>;
      savedList.value = decoded
          .map((e) => SavedSubCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      savedList.value = [];
    }
  }

  Future<void> saveToStorage() async {
    final encoded = json.encode(savedList.map((e) => e.toJson()).toList());
    await LocalStorageService.instance
        .setValue(LocalStorageService.kCustomCategories, encoded);
  }

  bool contains(String subCategoryId) {
    return savedList.any((e) => e.id == subCategoryId);
  }

  Future<void> add(LiveSubCategory subCategory, String parentName) async {
    if (contains(subCategory.id)) return;
    savedList.add(
      SavedSubCategory.fromLiveSubCategory(
        subCategory,
        parentName: parentName,
      ),
    );
    await saveToStorage();
  }

  Future<void> remove(String subCategoryId) async {
    savedList.removeWhere((e) => e.id == subCategoryId);
    await saveToStorage();
  }
}
