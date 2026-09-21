import 'package:flutter_test/flutter_test.dart';
import 'package:retailza/models/product_model.dart';
import 'package:retailza/models/customer_model.dart';
import 'package:retailza/providers/cart_provider.dart';

void main() {
  group('CartProvider Unit Tests', () {
    late CartProvider cart;
    late ProductModel product1;
    late ProductModel product2;

    setUp(() {
      cart = CartProvider();
      product1 = ProductModel(
        id: 1,
        shopId: 10,
        name: 'Aashirvaad Atta 5kg',
        category: 'Flour',
        barcode: '890103000001',
        purchasePrice: 200.0,
        sellingPrice: 240.0,
        stockQuantity: 20.0,
        minStockThreshold: 5.0,
        unit: 'Pack',
        isActive: true,
        isLowStock: false,
      );

      product2 = ProductModel(
        id: 2,
        shopId: 10,
        name: 'Tata Salt 1kg',
        category: 'Groceries',
        barcode: '890103000002',
        purchasePrice: 22.0,
        sellingPrice: 28.0,
        stockQuantity: 50.0,
        minStockThreshold: 10.0,
        unit: 'Pack',
        isActive: true,
        isLowStock: false,
      );
    });

    test('Initial cart is empty', () {
      expect(cart.items.isEmpty, true);
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
      expect(cart.finalAmount, 0.0);
      expect(cart.discount, 0.0);
      expect(cart.paymentMode, 'CASH');
      expect(cart.selectedCustomer, null);
    });

    test('Adding single item to cart computes subtotal and total', () {
      cart.addToCart(product1, quantity: 2.0);

      expect(cart.itemCount, 1);
      expect(cart.items.containsKey(1), true);
      expect(cart.items[1]!.quantity, 2.0);
      expect(cart.items[1]!.subtotal, 480.0); // 240.0 * 2
      expect(cart.totalAmount, 480.0);
      expect(cart.finalAmount, 480.0);
    });

    test('Adding existing item increments quantity correctly', () {
      cart.addToCart(product1, quantity: 1.0);
      cart.addToCart(product1, quantity: 2.0);

      expect(cart.itemCount, 1);
      expect(cart.items[1]!.quantity, 3.0);
      expect(cart.totalAmount, 720.0); // 240.0 * 3
    });

    test('Adding multiple distinct products computes correct aggregate total', () {
      cart.addToCart(product1, quantity: 1.0); // 240.0
      cart.addToCart(product2, quantity: 2.0); // 28.0 * 2 = 56.0

      expect(cart.itemCount, 2);
      expect(cart.totalAmount, 296.0);
      expect(cart.finalAmount, 296.0);
    });

    test('Applying discount updates finalAmount correctly', () {
      cart.addToCart(product1, quantity: 1.0); // 240.0
      cart.setDiscount(40.0);

      expect(cart.totalAmount, 240.0);
      expect(cart.discount, 40.0);
      expect(cart.finalAmount, 200.0);
    });

    test('Discount exceeding totalAmount bounds finalAmount to zero', () {
      cart.addToCart(product2, quantity: 1.0); // 28.0
      cart.setDiscount(50.0);

      expect(cart.finalAmount, 0.0);
    });

    test('Updating quantity to zero removes item from cart', () {
      cart.addToCart(product1, quantity: 1.0);
      cart.updateQuantity(1, 0.0);

      expect(cart.items.isEmpty, true);
      expect(cart.itemCount, 0);
      expect(cart.totalAmount, 0.0);
    });

    test('Directly removing item removes it from cart', () {
      cart.addToCart(product1, quantity: 1.0);
      cart.addToCart(product2, quantity: 1.0);

      expect(cart.itemCount, 2);
      cart.removeFromCart(product1.id);

      expect(cart.itemCount, 1);
      expect(cart.items.containsKey(product1.id), false);
      expect(cart.items.containsKey(product2.id), true);
    });

    test('Setting customer and payment mode changes state', () {
      final customer = CustomerModel(
        id: 5,
        shopId: 10,
        name: 'Ramesh Patel',
        mobileNumber: '9876543210',
        balance: 150.0,
      );

      cart.setCustomer(customer);
      cart.setPaymentMode('CREDIT');

      expect(cart.selectedCustomer?.name, 'Ramesh Patel');
      expect(cart.paymentMode, 'CREDIT');
    });

    test('clearCart resets all items, discounts, and customer selections', () {
      cart.addToCart(product1, quantity: 2.0);
      cart.setDiscount(20.0);
      cart.setPaymentMode('UPI');
      cart.setCustomer(CustomerModel(id: 1, shopId: 10, name: 'Test', balance: 0.0));

      cart.clearCart();

      expect(cart.items.isEmpty, true);
      expect(cart.totalAmount, 0.0);
      expect(cart.discount, 0.0);
      expect(cart.paymentMode, 'CASH');
      expect(cart.selectedCustomer, null);
    });
  });
}
