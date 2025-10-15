import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/data/models/menu_model.dart';

void main() {
  group('MenuResponse', () {
    test('should parse valid JSON correctly', () {
      final json = {
        'result_code': '200',
        'menu': [
          {
            'id': 1,
            'parent_id': 0,
            'cat_name': '{"cn":"饮料","en":"Beverages"}',
            'category_sn': 'CAT001',
            'cat_pic': 'https://example.com/image.jpg',
            'cat_pic1': 'https://example.com/image1.jpg',
            'sort_sn': 1,
            'child': [],
          }
        ],
        'desc': 'success',
      };

      final result = MenuResponse.fromJson(json);

      expect(result.resultCode, '200');
      expect(result.menu.length, 1);
      expect(result.desc, 'success');
      expect(result.isSuccess, true);
    });

    test('should handle empty menu array', () {
      final json = {
        'result_code': '200',
        'menu': [],
        'desc': 'success',
      };

      final result = MenuResponse.fromJson(json);

      expect(result.menu.length, 0);
      expect(result.isSuccess, true);
    });

    test('should handle missing optional fields', () {
      final json = {
        'result_code': '200',
        'menu': [],
      };

      final result = MenuResponse.fromJson(json);

      expect(result.desc, null);
      expect(result.isSuccess, true);
    });
  });

  group('MenuCategory', () {
    test('should parse valid JSON correctly', () {
      final json = {
        'id': 1,
        'parent_id': 0,
        'cat_name': '{"cn":"饮料","en":"Beverages"}',
        'category_sn': 'CAT001',
        'cat_pic': 'https://example.com/image.jpg',
        'cat_pic1': 'https://example.com/image1.jpg',
        'sort_sn': 1,
        'child': [],
      };

      final result = MenuCategory.fromJson(json);

      expect(result.id, 1);
      expect(result.parentId, 0);
      expect(result.catName, '{"cn":"饮料","en":"Beverages"}');
      expect(result.categorySn, 'CAT001');
      expect(result.catPic, 'https://example.com/image.jpg');
      expect(result.catPic1, 'https://example.com/image1.jpg');
      expect(result.sortSn, 1);
      expect(result.child.length, 0);
    });

    test('should parse multi-language category name', () {
      final json = {
        'id': 1,
        'parent_id': 0,
        'cat_name': '{"cn":"饮料","en":"Beverages"}',
        'category_sn': 'CAT001',
        'sort_sn': 1,
        'child': [],
      };

      final result = MenuCategory.fromJson(json);

      expect(result.catNameEn, 'Beverages');
      expect(result.catNameCn, '饮料');
    });

    test('should fallback to Chinese when English name is missing', () {
      final json = {
        'id': 1,
        'parent_id': 0,
        'cat_name': '{"cn":"饮料"}',
        'category_sn': 'CAT001',
        'sort_sn': 1,
        'child': [],
      };

      final result = MenuCategory.fromJson(json);

      expect(result.catNameEn, '饮料');
      expect(result.catNameCn, '饮料');
    });

    test('should handle invalid JSON in cat_name', () {
      final json = {
        'id': 1,
        'parent_id': 0,
        'cat_name': 'Not JSON',
        'category_sn': 'CAT001',
        'sort_sn': 1,
        'child': [],
      };

      final result = MenuCategory.fromJson(json);

      expect(result.catNameEn, 'Not JSON');
      expect(result.catNameCn, '');
    });

    test('should identify parent categories correctly', () {
      final parentJson = {
        'id': 1,
        'parent_id': 0,
        'cat_name': '{}',
        'category_sn': 'CAT001',
        'sort_sn': 1,
        'child': [],
      };

      final childJson = {
        'id': 2,
        'parent_id': 1,
        'cat_name': '{}',
        'category_sn': 'CAT002',
        'sort_sn': 2,
        'child': [],
      };

      final parent = MenuCategory.fromJson(parentJson);
      final child = MenuCategory.fromJson(childJson);

      expect(parent.isParent, true);
      expect(child.isParent, false);
    });

    test('should check if category has children', () {
      final withChildrenJson = {
        'id': 1,
        'parent_id': 0,
        'cat_name': '{}',
        'category_sn': 'CAT001',
        'sort_sn': 1,
        'child': [
          {
            'id': 2,
            'parent_id': 1,
            'cat_name': '{}',
            'category_sn': 'CAT002',
            'sort_sn': 2,
            'child': [],
          }
        ],
      };

      final withoutChildrenJson = {
        'id': 1,
        'parent_id': 0,
        'cat_name': '{}',
        'category_sn': 'CAT001',
        'sort_sn': 1,
        'child': [],
      };

      final withChildren = MenuCategory.fromJson(withChildrenJson);
      final withoutChildren = MenuCategory.fromJson(withoutChildrenJson);

      expect(withChildren.hasChildren, true);
      expect(withoutChildren.hasChildren, false);
    });

    test('should get all subcategories recursively', () {
      final json = {
        'id': 1,
        'parent_id': 0,
        'cat_name': '{}',
        'category_sn': 'CAT001',
        'sort_sn': 1,
        'child': [
          {
            'id': 2,
            'parent_id': 1,
            'cat_name': '{}',
            'category_sn': 'CAT002',
            'sort_sn': 2,
            'child': [
              {
                'id': 3,
                'parent_id': 2,
                'cat_name': '{}',
                'category_sn': 'CAT003',
                'sort_sn': 3,
                'child': [],
              }
            ],
          }
        ],
      };

      final category = MenuCategory.fromJson(json);
      final allSubs = category.allSubcategories;

      expect(allSubs.length, 2); // Should include both level 1 and level 2 children
      expect(allSubs[0].id, 2);
      expect(allSubs[1].id, 3);
    });

    test('should handle missing optional fields with defaults', () {
      final json = {
        'id': 1,
        'parent_id': 0,
        'category_sn': '',
        'sort_sn': 0,
      };

      final result = MenuCategory.fromJson(json);

      expect(result.catName, '{}');
      expect(result.catPic, null);
      expect(result.catPic1, null);
      expect(result.child.length, 0);
    });
  });
}
