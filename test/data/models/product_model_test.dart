import 'package:flutter_test/flutter_test.dart';
import 'package:mobileorder/data/models/product_model.dart';

void main() {
  group('ProductResponse', () {
    test('should parse valid JSON correctly', () {
      final json = {
        'result_code': 200,
        'products': [
          {
            'status': 1,
            'cid': 1,
            'cate_id': 99,
            'product_pic': 'https://example.com/product.jpg',
            'product_id': 589,
            'product_name': '{"cn":"鸡肉","en":"Chicken"}',
            'note': 'Delicious chicken',
            'product_sn': '2080',
            'is_take_out': 1,
            'price': '6.80',
            'sort_sn': 1,
            'start_time': '07:00:00',
            'end_time': '22:00:00',
            'ingredient_name': '{"cn":"其他","en":"other"}',
            'ingredients_id': 3,
            'effective_start_time': 1615132800,
            'effective_end_time': 4102329600,
            'hasModifiers': 1,
          }
        ],
        'desc': 'success',
      };

      final result = ProductResponse.fromJson(json);

      expect(result.resultCode, 200);
      expect(result.products.length, 1);
      expect(result.desc, 'success');
      expect(result.isSuccess, true);
    });

    test('should handle empty products array', () {
      final json = {
        'result_code': 200,
        'products': [],
        'desc': 'success',
      };

      final result = ProductResponse.fromJson(json);

      expect(result.products.length, 0);
      expect(result.isSuccess, true);
    });
  });

  group('Product', () {
    test('should parse valid JSON correctly', () {
      final json = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_pic': 'https://example.com/product.jpg',
        'product_id': 589,
        'product_name': '{"cn":"鸡肉","en":"Chicken"}',
        'note': 'Delicious chicken',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': '6.80',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{"cn":"其他","en":"other"}',
        'ingredients_id': 3,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final result = Product.fromJson(json);

      expect(result.status, 1);
      expect(result.cid, 1);
      expect(result.cateId, 99);
      expect(result.productPic, 'https://example.com/product.jpg');
      expect(result.productId, 589);
      expect(result.productName, '{"cn":"鸡肉","en":"Chicken"}');
      expect(result.note, 'Delicious chicken');
      expect(result.productSn, '2080');
      expect(result.isTakeOut, 1);
      expect(result.price, '6.80');
      expect(result.sortSn, 1);
      expect(result.startTime, '07:00:00');
      expect(result.endTime, '22:00:00');
      expect(result.ingredientName, '{"cn":"其他","en":"other"}');
      expect(result.ingredientsId, 3);
      expect(result.effectiveStartTime, 1615132800);
      expect(result.effectiveEndTime, 4102329600);
      expect(result.hasModifiers, 1);
    });

    test('should parse multi-language product name', () {
      final json = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_id': 589,
        'product_name': '{"cn":"鸡肉","en":"Chicken"}',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': '6.80',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{"cn":"其他","en":"other"}',
        'ingredients_id': 3,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final result = Product.fromJson(json);

      expect(result.productNameEn, 'Chicken');
      expect(result.productNameCn, '鸡肉');
    });

    test('should parse multi-language ingredient name', () {
      final json = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_id': 589,
        'product_name': '{}',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': '6.80',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{"cn":"冷饮","en":"Cold Drinks"}',
        'ingredients_id': 1,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final result = Product.fromJson(json);

      expect(result.ingredientNameEn, 'Cold Drinks');
      expect(result.ingredientNameCn, '冷饮');
    });

    test('should check if product is active', () {
      final activeJson = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_id': 589,
        'product_name': '{}',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': '6.80',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{}',
        'ingredients_id': 3,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final inactiveJson = {...activeJson, 'status': 0};

      final active = Product.fromJson(activeJson);
      final inactive = Product.fromJson(inactiveJson);

      expect(active.isActive, true);
      expect(inactive.isActive, false);
    });

    test('should check if takeout is available', () {
      final takeoutJson = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_id': 589,
        'product_name': '{}',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': '6.80',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{}',
        'ingredients_id': 3,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final noTakeoutJson = {...takeoutJson, 'is_take_out': 0};

      final takeout = Product.fromJson(takeoutJson);
      final noTakeout = Product.fromJson(noTakeoutJson);

      expect(takeout.isTakeOutAvailable, true);
      expect(noTakeout.isTakeOutAvailable, false);
    });

    test('should check if product has modifiers', () {
      final withModifiersJson = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_id': 589,
        'product_name': '{}',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': '6.80',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{}',
        'ingredients_id': 3,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final withoutModifiersJson = {...withModifiersJson, 'hasModifiers': 0};

      final withModifiers = Product.fromJson(withModifiersJson);
      final withoutModifiers = Product.fromJson(withoutModifiersJson);

      expect(withModifiers.hasModifiersAvailable, true);
      expect(withoutModifiers.hasModifiersAvailable, false);
    });

    test('should parse price as double', () {
      final json = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_id': 589,
        'product_name': '{}',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': '6.80',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{}',
        'ingredients_id': 3,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final result = Product.fromJson(json);

      expect(result.priceValue, 6.80);
      expect(result.formattedPrice, '\$6.80');
    });

    test('should handle invalid price gracefully', () {
      final json = {
        'status': 1,
        'cid': 1,
        'cate_id': 99,
        'product_id': 589,
        'product_name': '{}',
        'product_sn': '2080',
        'is_take_out': 1,
        'price': 'invalid',
        'sort_sn': 1,
        'start_time': '07:00:00',
        'end_time': '22:00:00',
        'ingredient_name': '{}',
        'ingredients_id': 3,
        'effective_start_time': 1615132800,
        'effective_end_time': 4102329600,
        'hasModifiers': 1,
      };

      final result = Product.fromJson(json);

      expect(result.priceValue, 0.0);
    });

    test('should handle missing optional fields with defaults', () {
      final json = {
        'product_id': 589,
        'product_sn': '2080',
        'price': '6.80',
      };

      final result = Product.fromJson(json);

      expect(result.status, 0);
      expect(result.cid, 0);
      expect(result.cateId, 0);
      expect(result.productPic, null);
      expect(result.productName, '{}');
      expect(result.note, null);
      expect(result.isTakeOut, 0);
      expect(result.sortSn, 0);
      expect(result.startTime, '00:00:00');
      expect(result.endTime, '23:59:59');
      expect(result.ingredientName, '{}');
      expect(result.ingredientsId, 0);
      expect(result.effectiveStartTime, 0);
      expect(result.effectiveEndTime, 0);
      expect(result.hasModifiers, 0);
    });
  });
}
