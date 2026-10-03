import 'package:flutter/material.dart';
import '../models/cart.dart';
import '../services/cart_service.dart';

/// Describes a cart change made during the current signed-in session.
class CartActivity {
  final String title;
  final String action;
  final int quantity;
  final double unitPrice;
  final DateTime timestamp;

  const CartActivity({
    required this.title,
    required this.action,
    required this.quantity,
    required this.unitPrice,
    required this.timestamp,
  });
}

class CartProvider with ChangeNotifier {
  final CartService _cartService = CartService();
  Cart? _userCart;
  bool _isLoading = false;
  final List<CartActivity> _activities = [];

  Cart? get userCart => _userCart;
  bool get isLoading => _isLoading;

  /// Newest cart actions first. This is intentionally session-local so
  /// logging out cannot leak one user's activity into another session.
  List<CartActivity> get activities => List.unmodifiable(_activities);

  void _recordActivity({
    required String title,
    required String action,
    required int quantity,
    required double unitPrice,
  }) {
    _activities.insert(
      0,
      CartActivity(
        title: title,
        action: action,
        quantity: quantity,
        unitPrice: unitPrice,
        timestamp: DateTime.now(),
      ),
    );

    // Keep the profile compact even after many cart edits.
    if (_activities.length > 20) {
      _activities.removeRange(20, _activities.length);
    }
  }

  // Enhancement 3: Load the signed-in user's real cart from the API, keyed
  // off the userId that comes from the User model instead of a hardcoded
  // placeholder. Falls back to an empty cart if the user has none yet.
  Future<void> fetchUserCart(int userId) async {
    if (_userCart != null && _userCart!.userId == userId) return;

    _isLoading = true;
    notifyListeners();

    final remoteCart = await _cartService.getCartByUserId(userId);

    _userCart =
        remoteCart ??
        Cart(
          id: 1,
          products: [],
          total: 0.0,
          discountedTotal: 0.0,
          userId: userId,
          totalProducts: 0,
          totalQuantity: 0,
        );

    _isLoading = false;
    notifyListeners();
  }

  // Enhancement 3: Reset the in-memory cart on logout so the next
  // signed-in user doesn't inherit the previous session's cart.
  void clearCart() {
    _userCart = null;
    _activities.clear();
    notifyListeners();
  }

  // FIXED: Positional named parameters to link up with your detail screen action handlers error-free
  Future<bool> addProductToCart({
    required int userId,
    required int productId,
    required int quantity,
    required String title,
    required double price,
    required String thumbnail,
  }) async {
    await _cartService.addToCart(userId, productId, quantity);

    _userCart ??= Cart(
      id: 1,
      products: [],
      total: 0.0,
      discountedTotal: 0.0,
      userId: userId,
      totalProducts: 0,
      totalQuantity: 0,
    );

    List<CartProduct> localList = List.from(_userCart!.products);
    final existingIndex = localList.indexWhere(
      (element) => element.id == productId,
    );

    if (existingIndex >= 0) {
      final currentItem = localList[existingIndex];
      final newQuantity = currentItem.quantity + quantity;
      final newRowTotal = currentItem.price * newQuantity;

      localList[existingIndex] = CartProduct(
        id: currentItem.id,
        title: currentItem.title,
        price: currentItem.price,
        quantity: newQuantity,
        total: newRowTotal,
        discountPercentage: currentItem.discountPercentage,
        discountedTotal: newRowTotal,
        thumbnail: currentItem.thumbnail,
      );

      _recordActivity(
        title: currentItem.title,
        action: 'Added',
        quantity: quantity,
        unitPrice: currentItem.price,
      );
    } else {
      final double rowTotal = price * quantity;
      localList.add(
        CartProduct(
          id: productId,
          title: title,
          price: price,
          quantity: quantity,
          total: rowTotal,
          discountPercentage: 0.0,
          discountedTotal: rowTotal,
          thumbnail: thumbnail,
        ),
      );

      _recordActivity(
        title: title,
        action: 'Added',
        quantity: quantity,
        unitPrice: price,
      );
    }

    _calculateCartSummaries(localList);
    return true;
  }

  // FIXED: Explicitly defined method allowing the interactive vertical plus and minus steppers to run!
  void updateItemQuantity(int productId, int deltaAmount) {
    if (_userCart == null) return;

    List<CartProduct> localList = List.from(_userCart!.products);
    final itemIndex = localList.indexWhere(
      (element) => element.id == productId,
    );

    if (itemIndex >= 0) {
      final currentItem = localList[itemIndex];
      final targetQuantity = currentItem.quantity + deltaAmount;

      if (targetQuantity <= 0) {
        // Remove product row entirely if the quantity falls to zero or below.
        localList.removeAt(itemIndex);
        _recordActivity(
          title: currentItem.title,
          action: 'Removed',
          quantity: currentItem.quantity,
          unitPrice: currentItem.price,
        );
      } else {
        final double newRowTotal = currentItem.price * targetQuantity;
        localList[itemIndex] = CartProduct(
          id: currentItem.id,
          title: currentItem.title,
          price: currentItem.price,
          quantity: targetQuantity,
          total: newRowTotal,
          discountPercentage: currentItem.discountPercentage,
          discountedTotal: newRowTotal,
          thumbnail: currentItem.thumbnail,
        );

        _recordActivity(
          title: currentItem.title,
          action: deltaAmount > 0 ? 'Added' : 'Subtracted',
          quantity: deltaAmount.abs(),
          unitPrice: currentItem.price,
        );
      }

      _calculateCartSummaries(localList);
    }
  }

  // Internal calculator logic consolidator loop
  void _calculateCartSummaries(List<CartProduct> directList) {
    double overallTotalSum = 0.0;
    int itemsCountSummary = 0;

    for (var item in directList) {
      overallTotalSum += item.total;
      itemsCountSummary += item.quantity;
    }

    _userCart = Cart(
      id: _userCart!.id,
      products: directList,
      total: overallTotalSum,
      discountedTotal: overallTotalSum,
      userId: _userCart!.userId,
      totalProducts: directList.length,
      totalQuantity: itemsCountSummary,
    );

    notifyListeners();
  }
}
