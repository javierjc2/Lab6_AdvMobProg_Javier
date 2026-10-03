import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

class ProductDetails extends StatelessWidget {
  final dynamic product;
  // Enhancement 3: real signed-in user's ID (replaces the old hardcoded
  // placeholder used for addProductToCart).
  final int userId;

  const ProductDetails({
    Key? key,
    required this.product,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final int id = product is Map ? (product['id'] ?? 0) : (product.id ?? 0);
    final String title = product is Map
        ? (product['title'] ?? '')
        : (product.title ?? '');
    final double price = product is Map
        ? ((product['price'] as num? ?? 0).toDouble())
        : ((product.price as num? ?? 0).toDouble());
    final String thumbnail = product is Map
        ? (product['thumbnail'] ?? '')
        : (product.thumbnail ?? '');
    final String description = product is Map
        ? (product['description'] ?? 'No description available.')
        : (product.description ?? 'No description available.');

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey,
              child: Image.network(
                thumbnail,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.image_not_supported, size: 100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$${price.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 22,
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Description",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart),
                      label: const Text(
                        'Add to Cart',
                        style: TextStyle(fontSize: 18),
                      ),
                      onPressed: () async {
                        final scaffoldMessenger = ScaffoldMessenger.of(context);
                        final cartProvider = Provider.of<CartProvider>(
                          context,
                          listen: false,
                        );

                        //  CORRECT: Explicitly matching the named parameter keys required by your provider file
                        // Enhancement 3: use the real signed-in user's ID.
                        bool success = await cartProvider.addProductToCart(
                          userId: userId,
                          productId: id,
                          quantity: 1,
                          title: title,
                          price: price,
                          thumbnail: thumbnail,
                        );

                        if (success) {
                          scaffoldMessenger.showSnackBar(
                            const SnackBar(
                              content: Text('Item added to cart successfully!'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
