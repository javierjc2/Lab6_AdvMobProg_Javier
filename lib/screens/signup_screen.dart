import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/custom_text.dart';

/// Lab Activity 5 (Enhancement 2): Firebase sign-up form.
///
/// Collects fName, lName, age, contactNo, username, emailAddress and a
/// validated password. The account is created with FirebaseAuth and the
/// profile fields are stored in Cloud Firestore (`users/{uid}`).
class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fName = TextEditingController();
  final _lName = TextEditingController();
  final _age = TextEditingController();
  final _contactNo = TextEditingController();
  final _username = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isLoading = false;
  bool _obscure = true;

  @override
  void dispose() {
    for (final c in [
      _fName,
      _lName,
      _age,
      _contactNo,
      _username,
      _email,
      _password,
      _confirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final userData = await UserService().registerWithProfile(
        fName: _fName.text.trim(),
        lName: _lName.text.trim(),
        age: int.parse(_age.text.trim()),
        contactNo: _contactNo.text.trim(),
        username: _username.text.trim(),
        email: _email.text.trim(),
        password: _password.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.pushNamedAndRemoveUntil(
        context,
        '/login-loading',
        (route) => false,
        arguments: userData,
      );
    } catch (e, stackTrace) {
      debugPrint('Sign-up failed: $e\n$stackTrace');
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sign up failed: ${UserService.friendlyError(e)}'),
        ),
      );
    }
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
    TextInputAction action = TextInputAction.next,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 14.h),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        textInputAction: action,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          suffixIcon: suffix,
        ),
        validator: validator,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: CustomText(
          text: 'Create Account',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _field(
                        controller: _fName,
                        label: 'First name',
                        icon: Icons.person_outline,
                        validator: (v) => Validators.required(v, 'first name'),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _field(
                        controller: _lName,
                        label: 'Last name',
                        icon: Icons.person_outline,
                        validator: (v) => Validators.required(v, 'last name'),
                      ),
                    ),
                  ],
                ),
                _field(
                  controller: _age,
                  label: 'Age',
                  icon: Icons.cake_outlined,
                  keyboardType: TextInputType.number,
                  validator: Validators.age,
                ),
                _field(
                  controller: _contactNo,
                  label: 'Contact number',
                  icon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  validator: Validators.contactNo,
                ),
                _field(
                  controller: _username,
                  label: 'Username',
                  icon: Icons.alternate_email,
                  validator: Validators.username,
                ),
                _field(
                  controller: _email,
                  label: 'Email address',
                  icon: Icons.mail_outline,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.email,
                ),
                _field(
                  controller: _password,
                  label: 'Password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  validator: Validators.password,
                  suffix: IconButton(
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                _field(
                  controller: _confirm,
                  label: 'Confirm password',
                  icon: Icons.lock_outline,
                  obscure: _obscure,
                  action: TextInputAction.done,
                  validator: (v) =>
                      v != _password.text ? 'Passwords do not match' : null,
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 18.h),
                  child: CustomText(
                    text:
                        'Password: 8+ characters with uppercase, lowercase, '
                        'a number and a special character.',
                    fontSize: 11.sp,
                  ),
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _signUp,
                    child: _isLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Sign Up'),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Already have an account? Log in'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
