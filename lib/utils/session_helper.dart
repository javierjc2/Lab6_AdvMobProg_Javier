import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/cart_provider.dart';
import '../services/user_service.dart';

/// Asks for confirmation, then clears the session (DummyJSON prefs and/or
/// Firebase sign-out), wipes the in-memory cart, and returns to Sign In.
///
/// Used by both the Profile screen and the Settings screen.
Future<void> confirmAndLogout(BuildContext context) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Log out?'),
      content: const Text('You will need to sign in again.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Log Out'),
        ),
      ],
    ),
  );
  if (confirmed != true || !context.mounted) return;
  await logoutAndRedirect(context);
}

Future<void> logoutAndRedirect(BuildContext context) async {
  final navigator = Navigator.of(context);
  final cart = context.read<CartProvider>();

  await UserService().logout();

  // Clear cart + activity so another account never sees this session's data.
  cart.clearCart();

  navigator.pushNamedAndRemoveUntil('/signin', (route) => false);
}
