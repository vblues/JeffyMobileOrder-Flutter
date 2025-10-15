import 'dart:convert';

class MenuResponse {
  final String resultCode;
  final List<MenuCategory> menu;
  final String? desc;

  MenuResponse({
    required this.resultCode,
    required this.menu,
    this.desc,
  });

  factory MenuResponse.fromJson(Map<String, dynamic> json) {
    return MenuResponse(
      resultCode: json['result_code'].toString(),
      menu: (json['menu'] as List<dynamic>?)
              ?.map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      desc: json['desc'] as String?,
    );
  }

  bool get isSuccess => resultCode == '200';
}

class MenuCategory {
  final int id;
  final int parentId;
  final String catName; // JSON string {"cn":"...", "en":"..."}
  final String categorySn;
  final String? catPic;
  final String? catPic1;
  final int sortSn;
  final List<MenuCategory> child;

  MenuCategory({
    required this.id,
    required this.parentId,
    required this.catName,
    required this.categorySn,
    this.catPic,
    this.catPic1,
    required this.sortSn,
    required this.child,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      id: json['id'] as int,
      parentId: json['parent_id'] as int,
      catName: json['cat_name'] as String? ?? '{}',
      categorySn: json['category_sn'] as String? ?? '',
      catPic: json['cat_pic'] as String?,
      catPic1: json['cat_pic1'] as String?,
      sortSn: json['sort_sn'] as int? ?? 0,
      child: (json['child'] as List<dynamic>?)
              ?.map((e) => MenuCategory.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Parse cat_name JSON string and get English name
  String get catNameEn {
    try {
      final nameMap = json.decode(catName) as Map<String, dynamic>;
      return nameMap['en'] as String? ?? nameMap['cn'] as String? ?? '';
    } catch (e) {
      return catName;
    }
  }

  /// Parse cat_name JSON string and get Chinese name
  String get catNameCn {
    try {
      final nameMap = json.decode(catName) as Map<String, dynamic>;
      return nameMap['cn'] as String? ?? '';
    } catch (e) {
      return '';
    }
  }

  /// Check if this is a parent category
  bool get isParent => parentId == 0;

  /// Check if this category has children
  bool get hasChildren => child.isNotEmpty;

  /// Get all subcategories (flattened)
  List<MenuCategory> get allSubcategories {
    final List<MenuCategory> all = [];
    for (final cat in child) {
      all.add(cat);
      all.addAll(cat.allSubcategories);
    }
    return all;
  }

  @override
  String toString() {
    return 'MenuCategory(id: $id, name: $catNameEn, children: ${child.length})';
  }
}
