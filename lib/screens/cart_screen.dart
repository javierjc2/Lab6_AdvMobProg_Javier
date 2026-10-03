import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../models/cart.dart';
import '../theme/app_colors.dart';
import 'settings_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the CartProvider.
    //
    // Whenever the cart changes, this screen will automatically
    // update because CartProvider uses notifyListeners().
    final cartProvider = Provider.of<CartProvider>(context);
    final colors = Theme.of(context).colorScheme;

    // Get the current cart.
    final cart = cartProvider.userCart;

    // Delivery fee
    const double deliveryFee = 5.00;

    // If there is no cart yet, show an empty/loading message.
    if (cart == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: _buildAppBar(context),
        body: Center(
          child: Text(
            'Your cart is empty',
            style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant),
          ),
        ),
      );
    }

    // Check if there are products in the cart.
    final bool cartIsEmpty = cart.products.isEmpty;

    // The total comes from your CartProvider.
    final double subtotal = cart.total;

    // Total including delivery fee.
    final double total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: _buildAppBar(context),

      // ==========================================================
      // PAGE
      // ==========================================================
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // ======================================================
            // CART PRODUCTS
            // ======================================================
            Expanded(
              child: cartIsEmpty
                  ? Center(
                      child: Text(
                        'Your cart is empty',
                    style: TextStyle(fontSize: 18, color: colors.onSurfaceVariant),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
                      itemCount: cart.products.length,
                      itemBuilder: (context, index) {
                        // Get the current product.
                        final CartProduct item = cart.products[index];

                        return _buildCartItem(context, cartProvider, item);
                      },
                    ),
            ),

            // ======================================================
            // PRICE SUMMARY
            // ======================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 12,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // ------------------------------------------------
                  // SUBTOTAL
                  // ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Subtotal:',
                        style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
                      ),
                      Text(
                        '\$${subtotal.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  // ------------------------------------------------
                  // DELIVERY FEE
                  // ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Delivery Fee:',
                        style: TextStyle(fontSize: 15, color: colors.onSurfaceVariant),
                      ),
                      Text(
                        '\$${deliveryFee.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 15,
                          color: colors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  Divider(color: Colors.grey.shade200, thickness: 1),

                  const SizedBox(height: 8),

                  // ------------------------------------------------
                  // TOTAL
                  // ------------------------------------------------
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total Price:',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: colors.onSurface,
                        ),
                      ),
                      Text(
                        '\$${total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colors.primary,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ------------------------------------------------
                  // CONFIRM ORDER BUTTON
                  // ------------------------------------------------
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: cartIsEmpty
                          ? null
                          : () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Order confirmed!'),
                                ),
                              );
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.secondary,
                        disabledBackgroundColor: Colors.grey.shade300,
                        foregroundColor: AppColors.textOnAmber,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Confirm Order',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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

  // ==============================================================
  // APP BAR
  // ==============================================================
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      elevation: 0,
      title: const Text(
        'Cart',
        style: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w500,
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  // ==============================================================
  // CART ITEM
  // ==============================================================
  Widget _buildCartItem(
    BuildContext context,
    CartProvider cartProvider,
    CartProduct item,
  ) {
    final bool hasDiscount = item.discountPercentage > 0;
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ========================================================
          // PRODUCT IMAGE
          // ========================================================
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(10),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.network(
                item.thumbnail,
                fit: BoxFit.contain,

                // If the image doesn't load,
                // show an icon instead.
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.shopping_bag_outlined,
                    size: 30,
                    color: colors.onSurfaceVariant,
                  );
                },
              ),
            ),
          ),

          const SizedBox(width: 12),

          // ========================================================
          // PRODUCT INFORMATION
          // ========================================================
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PRODUCT NAME
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.onSurface,
                  ),
                ),

                const SizedBox(height: 4),

                // PRICE
                Text(
                  '\$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 2),

                // DISCOUNT / LINE TOTAL
                Text(
                  hasDiscount
                      ? '${item.discountPercentage.round()}% off \u00b7 \$${item.discountedTotal.toStringAsFixed(2)} total'
                      : '\$${item.total.toStringAsFixed(2)} total',
                  style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // ========================================================
          // QUANTITY CONTROLS (vertical stepper)
          // ========================================================
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // PLUS BUTTON
              GestureDetector(
                onTap: () {
                  cartProvider.updateItemQuantity(item.id, 1);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: colors.secondary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, size: 18, color: Colors.white),
                ),
              ),

              const SizedBox(height: 6),

              // QUANTITY NUMBER
              Text(
                '${item.quantity}',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),

              const SizedBox(height: 6),

              // MINUS BUTTON
              GestureDetector(
                onTap: () {
                  cartProvider.updateItemQuantity(item.id, -1);
                },
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colors.secondary, width: 1.5),
                  ),
                  child: Icon(
                    Icons.remove,
                    size: 18,
                    color: colors.secondary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
