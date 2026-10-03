import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../models/login_type.dart';
import '../models/user.dart';
import '../models/cart.dart';
import '../providers/cart_provider.dart';
import '../services/user_service.dart';
import '../utils/session_helper.dart';
import '../utils/validators.dart';
import '../widgets/custom_text.dart';
import 'settings_screen.dart';

/// Profile information plus a live view of the user's cart and cart activity.
///
/// Lab Activity 5 (Enhancement 3): the user is (re)loaded through
/// `UserService().getUserData()` and the details shown depend on the
/// [LoginType] (DummyJSON vs Firebase). The user can also update their
/// username, change their password and delete their account.
class ProfileScreen extends StatefulWidget {
  final User user;

  const ProfileScreen({super.key, required this.user});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _service = UserService();
  late User _user = widget.user;

  bool get _isFirebase => _user.loginType == LoginType.firebase;

  @override
  void initState() {
    super.initState();
    _refreshUser();
  }

  /// Fetch the latest user data via UserService().getUserData().
  Future<void> _refreshUser() async {
    try {
      final fresh = await _service.getUser();
      if (mounted) setState(() => _user = fresh);
    } catch (e) {
      debugPrint('Could not refresh user: $e');
    }
  }

  void _toast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  // ---------------------------------------------------------------- actions

  Future<void> _updateUsername() async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Update username',
        confirmLabel: 'Save',
        fields: [
          _FieldSpec(
            label: 'New username',
            initial: _user.username,
            validator: Validators.username,
          ),
        ],
      ),
    );
    if (values == null) return;

    try {
      final newUsername = values[0].trim();

      if (_isFirebase) {
        await _service.updateUsername(username: newUsername);
      } else {
        await _service.updateDummyUsername(id: _user.id, username: newUsername);
      }

      if (!mounted) return;
      setState(() {
        _user = _user.copyWith(username: newUsername);
      });

      await _refreshUser();
      _toast('Username updated');
    } catch (e) {
      _toast('Update failed: ${UserService.friendlyError(e)}');
    }
  }

  Future<void> _changePassword() async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Change password',
        confirmLabel: 'Change',
        fields: [
          // Firebase re-authenticates with the current password first.
          if (_isFirebase)
            _FieldSpec(
              label: 'Current password',
              obscure: true,
              validator: (v) => Validators.required(v, 'current password'),
            ),
          const _FieldSpec(
            label: 'New password',
            obscure: true,
            validator: Validators.password,
          ),
          _FieldSpec(
            label: 'Confirm new password',
            obscure: true,
            matchesIndex: _isFirebase ? 1 : 0,
          ),
        ],
      ),
    );
    if (values == null) return;

    try {
      if (_isFirebase) {
        await _service.resetPasswordFromCurrentPassword(
          currentPassword: values[0],
          newPassword: values[1],
          email: _user.email,
        );
      } else {
        // DummyJSON only simulates the update (nothing is stored).
        await _service.changeDummyPassword(
          id: _user.id,
          newPassword: values[0],
        );
      }
      _toast('Password changed');
    } catch (e) {
      _toast('Change failed: ${UserService.friendlyError(e)}');
    }
  }

  Future<void> _deleteAccount() async {
    final values = await showDialog<List<String>>(
      context: context,
      builder: (_) => _FormDialog(
        title: 'Delete account?',
        message: 'This permanently deletes your account. '
            '${_isFirebase ? 'Enter your password to confirm.' : ''}',
        confirmLabel: 'Delete',
        destructive: true,
        fields: [
          if (_isFirebase)
            _FieldSpec(
              label: 'Password',
              obscure: true,
              validator: (v) => Validators.required(v, 'password'),
            ),
        ],
      ),
    );
    if (values == null) return;

    try {
      if (_isFirebase) {
        await _service.deleteAccount(email: _user.email, password: values[0]);
      } else {
        await _service.deleteDummyAccount(id: _user.id);
      }
      if (!mounted) return;
      context.read<CartProvider>().clearCart();
      Navigator.of(context).pushNamedAndRemoveUntil('/signin', (r) => false);
    } catch (e) {
      _toast('Delete failed: ${UserService.friendlyError(e)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: AppBar(
        title: CustomText(
          text: _user.firstName.isNotEmpty ? _user.firstName : _user.username,
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          final cart = cartProvider.userCart;

          return ListView(
            padding: EdgeInsets.fromLTRB(20.w, 20.w, 20.w, 28.w),
            children: [
              // ==================================================
              // AVATAR + NAME
              // ==================================================
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 44.r,
                      backgroundColor: colors.primary.withValues(alpha: 0.16),
                      backgroundImage: _user.image.isNotEmpty
                          ? NetworkImage(_user.image)
                          : null,
                      child: _user.image.isEmpty
                          ? Icon(
                              Icons.person,
                              size: 44.sp,
                              color: colors.primary,
                            )
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    CustomText(
                      text: _user.fullName.isNotEmpty
                          ? _user.fullName
                          : _user.username,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    SizedBox(height: 2.h),
                    CustomText(
                      text: '@${_user.username}',
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // ==================================================
              // USER DATA
              // ==================================================
              _sectionTitle(context, 'Account Details', Icons.person_outline),
              SizedBox(height: 8.h),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    _infoTile(
                      context: context,
                      icon: Icons.verified_user_outlined,
                      label: 'Signed in with',
                      value: _user.loginType.label,
                    ),
                    const Divider(height: 1),
                    _infoTile(
                      context: context,
                      icon: Icons.mail_outline,
                      label: 'Email',
                      value: _user.email,
                    ),
                    const Divider(height: 1),
                    // Details depend on the LoginType.
                    if (_isFirebase) ...[
                      _infoTile(
                        context: context,
                        icon: Icons.cake_outlined,
                        label: 'Age',
                        value: _user.age > 0 ? '${_user.age}' : '',
                      ),
                      const Divider(height: 1),
                      _infoTile(
                        context: context,
                        icon: Icons.phone_outlined,
                        label: 'Contact No.',
                        value: _user.contactNo,
                      ),
                      const Divider(height: 1),
                      _infoTile(
                        context: context,
                        icon: Icons.badge_outlined,
                        label: 'UID',
                        value: _user.uid,
                      ),
                    ] else ...[
                      _infoTile(
                        context: context,
                        icon: Icons.wc_outlined,
                        label: 'Gender',
                        value: _user.gender,
                      ),
                      const Divider(height: 1),
                      _infoTile(
                        context: context,
                        icon: Icons.badge_outlined,
                        label: 'User ID',
                        value: '#${_user.id}',
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // ==================================================
              // ACCOUNT ACTIONS
              // ==================================================
              _sectionTitle(context, 'Account', Icons.manage_accounts_outlined),
              SizedBox(height: 8.h),
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.edit_outlined),
                      title: const Text('Update username'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _updateUsername,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.password_outlined),
                      title: const Text('Change password'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _changePassword,
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(
                        Icons.delete_outline,
                        color: Color(0xFFE5533C),
                      ),
                      title: const Text(
                        'Delete account',
                        style: TextStyle(color: Color(0xFFE5533C)),
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _deleteAccount,
                    ),
                  ],
                ),
              ),

              SizedBox(height: 24.h),

              // ==================================================
              // CURRENT CART DETAILS
              // ==================================================
              _sectionTitle(context, 'Cart Details', Icons.shopping_cart_outlined),
              SizedBox(height: 8.h),
              if (cartProvider.isLoading)
                _loadingCard(context)
              else if (cart == null || cart.products.isEmpty)
                _emptyCartCard(context)
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(12.w),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            _summaryPill(
                              context: context,
                              icon: Icons.inventory_2_outlined,
                              label: 'Products',
                              value: '${cart.totalProducts}',
                            ),
                            SizedBox(width: 8.w),
                            _summaryPill(
                              context: context,
                              icon: Icons.format_list_numbered,
                              label: 'Items',
                              value: '${cart.totalQuantity}',
                            ),
                            SizedBox(width: 8.w),
                            _summaryPill(
                              context: context,
                              icon: Icons.payments_outlined,
                              label: 'Total',
                              value: '\$${cart.total.toStringAsFixed(2)}',
                            ),
                          ],
                        ),
                        SizedBox(height: 8.h),
                        ...cart.products.map((item) => _cartDetailTile(context, item)),
                      ],
                    ),
                  ),
                ),

              SizedBox(height: 24.h),

              // ==================================================
              // CART ACTIVITY
              // ==================================================
              _sectionTitle(context, 'Recent Cart Activity', Icons.history),
              SizedBox(height: 8.h),
              if (cartProvider.activities.isEmpty)
                _noActivityCard(context)
              else
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      for (int i = 0; i < cartProvider.activities.length; i++) ...[
                        _activityTile(context, cartProvider.activities[i]),
                        if (i != cartProvider.activities.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),

              SizedBox(height: 28.h),

              // ==================================================
              // LOG OUT
              // ==================================================
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => confirmAndLogout(context),
                  icon: const Icon(Icons.logout),
                  label: const Text('Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE5533C),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 14.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title, IconData icon) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 19.sp, color: colors.primary),
        SizedBox(width: 7.w),
        CustomText(
          text: title,
          fontSize: 16.sp,
          fontWeight: FontWeight.w700,
        ),
      ],
    );
  }

  Widget _infoTile({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = Theme.of(context).colorScheme;

    return ListTile(
      leading: Icon(icon, color: colors.secondary),
      title: CustomText(
        text: label,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
      trailing: SizedBox(
        width: 190.w,
        child: Text(
          value.isNotEmpty ? value : '-',
          textAlign: TextAlign.end,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _summaryPill({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String value,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 7.w),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(11.r),
        ),
        child: Column(
          children: [
            Icon(icon, size: 17.sp, color: colors.primary),
            SizedBox(height: 4.h),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.sp,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartDetailTile(BuildContext context, CartProduct item) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.only(top: 8.h),
      padding: EdgeInsets.all(9.w),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(9.r),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9.r),
              child: Image.network(
                item.thumbnail,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.shopping_bag_outlined,
                  size: 24.sp,
                  color: colors.onSurfaceVariant,
                ),
              ),
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${item.quantity} × \$${item.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          Text(
            '\$${item.total.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w800,
              color: colors.secondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _activityTile(BuildContext context, CartActivity activity) {
    final colors = Theme.of(context).colorScheme;
    final bool isSubtract =
        activity.action == 'Subtracted' || activity.action == 'Removed';
    final IconData icon = activity.action == 'Removed'
        ? Icons.remove_shopping_cart_outlined
        : isSubtract
            ? Icons.remove_circle_outline
            : Icons.add_shopping_cart_outlined;

    final String quantityText = activity.action == 'Removed'
        ? 'Removed ${activity.quantity} item${activity.quantity == 1 ? '' : 's'}'
        : '${activity.action} ${activity.quantity} item${activity.quantity == 1 ? '' : 's'}';

    return ListTile(
      dense: true,
      leading: CircleAvatar(
        radius: 18.r,
        backgroundColor: isSubtract
            ? const Color(0xFFFFE8E4)
            : const Color(0xFFFFF4D5),
        child: Icon(
          icon,
          size: 18.sp,
          color: isSubtract
              ? const Color(0xFFE5533C)
              : colors.secondary,
        ),
      ),
      title: Text(
        activity.title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 13.sp,
          fontWeight: FontWeight.w700,
          color: colors.onSurface,
        ),
      ),
      subtitle: Text(
        '$quantityText • \$${activity.unitPrice.toStringAsFixed(2)} each',
        style: TextStyle(fontSize: 11.sp, color: colors.onSurfaceVariant),
      ),
      trailing: Text(
        _formatTime(activity.timestamp),
        style: TextStyle(fontSize: 10.sp, color: colors.onSurfaceVariant),
      ),
    );
  }

  Widget _loadingCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(22.w),
        child: Center(
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
      ),
    );
  }

  Widget _emptyCartCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(22.w),
        child: Column(
          children: [
            Icon(
              Icons.shopping_cart_outlined,
              size: 34.sp,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 7.h),
            Text(
              'Your cart is empty',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _noActivityCard(BuildContext context) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Padding(
        padding: EdgeInsets.all(18.w),
        child: Text(
          'Add or subtract products from the Cart tab to see the activity here.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

/// Describes one text field inside [_FormDialog].
class _FieldSpec {
  final String label;
  final String initial;
  final bool obscure;
  final String? Function(String?)? validator;

  /// If set, this field must equal the value of the field at that index.
  final int? matchesIndex;

  const _FieldSpec({
    required this.label,
    this.initial = '',
    this.obscure = false,
    this.validator,
    this.matchesIndex,
  });
}

/// Small reusable form dialog. Pops with the list of entered values (in
/// field order) or null when cancelled. Owns and disposes its controllers.
class _FormDialog extends StatefulWidget {
  final String title;
  final String? message;
  final String confirmLabel;
  final bool destructive;
  final List<_FieldSpec> fields;

  const _FormDialog({
    required this.title,
    required this.confirmLabel,
    required this.fields,
    this.message,
    this.destructive = false,
  });

  @override
  State<_FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<_FormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers = [
    for (final f in widget.fields) TextEditingController(text: f.initial),
  ];

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.message != null) Text(widget.message!.trim()),
              for (int i = 0; i < widget.fields.length; i++)
                TextFormField(
                  controller: _controllers[i],
                  obscureText: widget.fields[i].obscure,
                  decoration: InputDecoration(labelText: widget.fields[i].label),
                  validator: (v) {
                    final spec = widget.fields[i];
                    if (spec.matchesIndex != null) {
                      return v == _controllers[spec.matchesIndex!].text
                          ? null
                          : 'Passwords do not match';
                    }
                    return spec.validator?.call(v);
                  },
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          style: widget.destructive
              ? TextButton.styleFrom(foregroundColor: const Color(0xFFE5533C))
              : null,
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, [for (final c in _controllers) c.text.trim()]);
          },
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
