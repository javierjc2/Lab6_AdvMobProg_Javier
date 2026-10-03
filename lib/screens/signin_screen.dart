import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../models/login_type.dart';
import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../utils/validators.dart';
import '../widgets/custom_text.dart';

/// Enhancement 2: Custom sign-in UI, wired to [UserService] and the
/// authentication logic (calls the login API, persists the session to
/// SharedPreferences, then hands the resulting user data to Home).
class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});

  @override
  State<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  // Lab Activity 5: choose which backend to authenticate against.
  LoginType _loginType = LoginType.dummyJson;
  bool get _isFirebase => _loginType == LoginType.firebase;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Enhancement 2: Authenticate through UserService, persist the session,
  // then navigate to Home with the logged-in user's data.
  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    final userService = UserService();
    setState(() => _isLoading = true);

    try {
      final Map<String, dynamic> response;

      if (_isFirebase) {
        // Firebase: FirebaseAuth SDK (email + password). The SDK keeps the
        // session and refreshes the ID token on its own.
        response = await userService.loginWithFirebase(
          email: _usernameController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        // DummyJSON: REST call to /auth/login (also persists the session).
        response = await userService.loginUser(
          _usernameController.text.trim(),
          _passwordController.text,
        );
        await userService.saveUserData(response);
      }

      if (!mounted) return;
      setState(() => _isLoading = false);

      // Keep the existing successful-login flow, but show a short branded
      // loading screen before Home so the transition feels intentional.
      Navigator.pushReplacementNamed(
        context,
        '/login-loading',
        arguments: response,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Login failed: ${UserService.friendlyError(e)}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhancement 2: Own sign-in header/branding.
                  Row(
                    children: [
                      Container(
                        width: 42.w,
                        height: 42.w,
                        padding: EdgeInsets.all(2.w),
                        child: Image.asset(
                          'assets/nu_icon.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      CustomText(
                        text: 'Welcome!',
                        fontSize: 26.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ],
                  ),

                  SizedBox(height: 20.h),

                  // Login type toggle: DummyJSON vs Firebase
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<LoginType>(
                      segments: const [
                        ButtonSegment(
                          value: LoginType.dummyJson,
                          label: Text('DummyJSON'),
                          icon: Icon(Icons.api),
                        ),
                        ButtonSegment(
                          value: LoginType.firebase,
                          label: Text('Firebase'),
                          icon: Icon(Icons.local_fire_department_outlined),
                        ),
                      ],
                      selected: {_loginType},
                      onSelectionChanged: _isLoading
                          ? null
                          : (selection) => setState(() {
                                _loginType = selection.first;
                                _usernameController.clear();
                                _passwordController.clear();
                                _formKey.currentState?.reset();
                              }),
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Username (DummyJSON) or Email (Firebase)
                  TextFormField(
                    controller: _usernameController,
                    textInputAction: TextInputAction.next,
                    keyboardType: _isFirebase
                        ? TextInputType.emailAddress
                        : TextInputType.text,
                    decoration: InputDecoration(
                      labelText: _isFirebase ? 'Email address' : 'Username',
                      prefixIcon: Icon(
                        _isFirebase ? Icons.mail_outline : Icons.person_outline,
                      ),
                    ),
                    validator: (value) => _isFirebase
                        ? Validators.email(value)
                        : ((value == null || value.trim().isEmpty)
                            ? 'Please enter your username'
                            : null),
                  ),
                  SizedBox(height: 20.h),

                  // Password
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                      ),
                    ),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Please enter your password'
                        : null,
                  ),
                  SizedBox(height: 32.h),

                  // Log In button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      child: _isLoading
                          ? SizedBox(
                              width: 20.w,
                              height: 20.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Log In'),
                    ),
                  ),

                  // Sign-up is only available for Firebase (DummyJSON has no
                  // real registration endpoint).
                  if (_isFirebase)
                    Center(
                      child: TextButton(
                        onPressed: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, '/signup'),
                        child: const Text("Don't have an account? Sign up"),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
