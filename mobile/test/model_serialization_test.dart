import 'package:flutter_test/flutter_test.dart';
import 'package:retailza/models/product_model.dart';
import 'package:retailza/models/customer_model.dart';
import 'package:retailza/models/announcement_model.dart';
import 'package:retailza/models/shop_model.dart';
import 'package:retailza/core/constants/shop_categories.dart';

void main() {
  group('Domain Model Serialization Tests', () {
    test('ProductModel fromJson & toJson parses accurately', () {
      final json = {
        'id': 101,
        'shop_id': 5,
        'name': 'Fortune Sunflower Oil 1L',
        'barcode': '8901234567890',
        'category': 'Cooking Oils',
        'unit': 'ltr',
        'purchase_price': 130.0,
        'selling_price': 155.0,
        'stock_quantity': 24.0,
        'min_stock_threshold': 6.0,
        'is_active': true,
        'is_low_stock': false,
      };

      final product = ProductModel.fromJson(json);
      expect(product.id, 101);
      expect(product.shopId, 5);
      expect(product.name, 'Fortune Sunflower Oil 1L');
      expect(product.sellingPrice, 155.0);
      expect(product.unit, 'ltr');

      final outputJson = product.toJson();
      expect(outputJson['id'], 101);
      expect(outputJson['selling_price'], 155.0);
    });

    test('CustomerModel with nested CreditTransactions parses accurately', () {
      final json = {
        'id': 42,
        'shop_id': 5,
        'name': 'Suresh Kumar',
        'mobile_number': '9876543210',
        'balance': 350.50,
        'recent_transactions': [
          {
            'id': 1,
            'customer_id': 42,
            'sale_id': 1001,
            'amount': 350.50,
            'transaction_type': 'DEBT',
            'note': 'Grocery credit purchase',
            'created_at': '2026-09-16T12:00:00Z',
          }
        ],
      };

      final customer = CustomerModel.fromJson(json);
      expect(customer.id, 42);
      expect(customer.name, 'Suresh Kumar');
      expect(customer.balance, 350.50);
      expect(customer.recentTransactions.length, 1);
      expect(customer.recentTransactions.first.amount, 350.50);
      expect(customer.recentTransactions.first.transactionType, 'DEBT');
    });

    test('AnnouncementModel parses admin broadcast accurately', () {
      final json = {
        'id': 7,
        'title': 'Thermal Printing Enabled',
        'message': 'Connect Bluetooth 58mm printer directly from Settings',
        'tag': 'FEATURE',
        'action_url': 'https://retailza.com/features',
        'is_active': true,
        'created_at': '2026-09-16T10:30:00Z',
      };

      final announcement = AnnouncementModel.fromJson(json);
      expect(announcement.id, 7);
      expect(announcement.title, 'Thermal Printing Enabled');
      expect(announcement.tag, 'FEATURE');
      expect(announcement.isActive, true);
    });

    test('ShopModel parses store information and category accurately', () {
      final json = {
        'id': 12,
        'owner_id': 3,
        'shop_name': 'Lakshmi Kirana Stores',
        'owner_name': 'Lakshmi Devi',
        'category': 'Electrical',
        'city': 'Bidar',
        'state': 'Karnataka',
        'upi_id': 'lakshmi@upi',
      };

      final shop = ShopModel.fromJson(json);
      expect(shop.id, 12);
      expect(shop.shopName, 'Lakshmi Kirana Stores');
      expect(shop.ownerName, 'Lakshmi Devi');
      expect(shop.category, 'Electrical');
      expect(shop.city, 'Bidar');
      expect(shop.state, 'Karnataka');
      expect(shop.upiId, 'lakshmi@upi');

      final output = shop.toJson();
      expect(output['category'], 'Electrical');
    });

    test('ShopCategories returns specific catalog presets based on store type', () {
      final provisionPresets = ShopCategories.getCatalogFor('Provision Store');
      expect(provisionPresets.any((p) => p.name.contains('Rice')), isTrue);
      expect(provisionPresets.any((p) => p.name.contains('Sugar')), isTrue);
      expect(provisionPresets.any((p) => p.name.contains('Tea')), isTrue);

      final electricalPresets = ShopCategories.getCatalogFor('Electrical');
      expect(electricalPresets.any((p) => p.name.contains('Switch')), isTrue);
      expect(electricalPresets.any((p) => p.name.contains('Board')), isTrue);
      expect(electricalPresets.any((p) => p.name.contains('Wire')), isTrue);
      expect(electricalPresets.any((p) => p.name.contains('Button')), isTrue);

      final ricePresets = ShopCategories.getCatalogFor('Rice & Grain Retail');
      expect(ricePresets.any((p) => p.name.contains('Basmati Rice')), isTrue);

      final furniturePresets = ShopCategories.getCatalogFor('Furniture');
      expect(furniturePresets.any((p) => p.name.contains('Chair')), isTrue);
    });
  });
}
