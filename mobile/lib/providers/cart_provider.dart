import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../models/customer_model.dart';
import '../models/sale_model.dart';
import '../services/sale_service.dart';

class CartItem {
  final ProductModel product;
  double quantity;

  CartItem({
    required this.product,
    required this.quantity,
  });

  double get subtotal => double.parse((product.sellingPrice * quantity).toStringAsFixed(2));
}

class CartProvider extends ChangeNotifier {
  final SaleService _saleService = SaleService();

  final Map<int, CartItem> _items = {};
  CustomerModel? _selectedCustomer;
  String _paymentMode = 'CASH'; // CASH, UPI, CREDIT
  double _discount = 0.0;
  bool _isCheckingOut = false;
  String? _checkoutError;

  Map<int, CartItem> get items => _items;
  List<CartItem> get itemList => _items.values.toList();
  int get itemCount => _items.length;
  CustomerModel? get selectedCustomer => _selectedCustomer;
  String get paymentMode => _paymentMode;
  double get discount => _discount;
  bool get isCheckingOut => _isCheckingOut;
  String? get checkoutError => _checkoutError;

  double get totalAmount {
    double total = 0.0;
    for (var item in _items.values) {
      total += item.subtotal;
    }
    return double.parse(total.toStringAsFixed(2));
  }

  double get finalAmount {
    double finalVal = totalAmount - _discount;
    return finalVal > 0 ? double.parse(finalVal.toStringAsFixed(2)) : 0.0;
  }

  void addToCart(ProductModel product, {double quantity = 1.0}) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += quantity;
    } else {
      _items[product.id] = CartItem(product: product, quantity: quantity);
    }
    notifyListeners();
  }

  void updateQuantity(int productId, double newQuantity) {
    if (newQuantity <= 0) {
      _items.remove(productId);
    } else if (_items.containsKey(productId)) {
      _items[productId]!.quantity = double.parse(newQuantity.toStringAsFixed(3));
    }
    notifyListeners();
  }

  void removeFromCart(int productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void setPaymentMode(String mode) {
    _paymentMode = mode;
    notifyListeners();
  }

  void setCustomer(CustomerModel? customer) {
    _selectedCustomer = customer;
    notifyListeners();
  }

  void setDiscount(double discountVal) {
    _discount = discountVal;
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    _selectedCustomer = null;
    _discount = 0.0;
    _paymentMode = 'CASH';
    _checkoutError = null;
    notifyListeners();
  }

  Future<SaleModel?> checkout({String paymentStatus = 'PAID'}) async {
    if (_items.isEmpty) {
      _checkoutError = "Cart is empty";
      notifyListeners();
      return null;
    }

    if ((_paymentMode == 'CREDIT' || paymentStatus == 'UNPAID') && _selectedCustomer == null) {
      _checkoutError = "Please select a customer for Khata / Unpaid sale";
      notifyListeners();
      return null;
    }

    _isCheckingOut = true;
    _checkoutError = null;
    notifyListeners();

    try {
      final itemsPayload = _items.values.map((item) {
        return {
          'product_id': item.product.id,
          'quantity': item.quantity,
        };
      }).toList();

      final sale = await _saleService.checkout(
        customerId: _selectedCustomer?.id,
        discount: _discount,
        paymentMode: _paymentMode,
        paymentStatus: paymentStatus,
        items: itemsPayload,
      );

      clearCart();
      _isCheckingOut = false;
      notifyListeners();
      return sale;
    } catch (e) {
      _isCheckingOut = false;
      _checkoutError = e.toString();
      notifyListeners();
      return null;
    }
  }
}
