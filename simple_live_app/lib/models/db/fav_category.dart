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
