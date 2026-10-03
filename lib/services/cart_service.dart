import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/cart.dart';

class CartService {
  static const String baseUrl = 'https://dummyjson.com/carts';

  // Enhancement 3: Fetch a single user's cart by their User ID
  Future<Cart?> getCartByUserId(int userId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/$userId'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);

        if (data['carts'] != null && (data['carts'] as List).isNotEmpty) {
          final List<dynamic> cartList = data['carts'];
          return Cart.fromJson(cartList.first as Map<String, dynamic>);
        }
      }
      return null;
    } catch (e) {
      debugPrint("Error fetching user cart sequence: $e");
      return null;
    }
  }

  // Enhancement 3: Simulate pushing a product addition to the remote server API
  Future<bool> addToCart(int userId, int productId, int quantity) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': userId,
          'products': [
            {'id': productId, 'quantity': quantity},
          ],
        }),
      );

      // Fixed: Explicit status validation to clear out formatting type constraints
      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      }

      debugPrint(
        "Server rejected add validation payload with code: ${response.statusCode}",
      );
      return false;
    } catch (e) {
      debugPrint("Error pushing cart updates: $e");
      return false;
    }
  }
}
