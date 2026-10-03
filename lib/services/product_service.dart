import 'dart:convert';
import 'package:flutter/foundation.dart'; // Required for debugPrint operations
import 'package:http/http.dart' as http;
import '../models/product.dart';

class ProductService {
  static const String baseUrl = 'https://dummyjson.com';

  Future<List<Product>> getAllProducts() async {
    try {
      final response = await http.get(Uri.parse(baseUrl));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> productsJson = data['products'] ?? [];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      // FIXED: Exchanged print with debugPrint framework to clear out the production hint warning
      debugPrint("Error fetching all storefront products: $e");
      return [];
    }
  }

  Future<Product?> getProductById(int id) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$id'));
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return Product.fromJson(data);
      }
      return null;
    } catch (e) {
      // FIXED: Exchanged print with debugPrint framework to clear out the production hint warning
      debugPrint("Error fetching product by ID identifier: $e");
      return null;
    }
  }
}
