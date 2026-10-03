import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/user_service.dart';
import '../theme/app_colors.dart';
import '../widgets/custom_text.dart';

/// Enhancement 1: Custom splash screen UI + persistent-login check.
///
/// On launch, this screen briefly shows the app's own branding, then asks
/// [UserService.isLoggedIn] whether a session was already saved to
/// SharedPreferences from a previous login:
///   - logged in     -> skip Sign In entirely and go straight to Home with
///                      the saved user data (this is the "persistent
///                      authentication" behavior).
///   - not logged in -> send the user to the Sign In screen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final UserService _userService = UserService();

  @override
  void initState() {
    super.initState();
    _checkAuthentication();
  }

  // Enhancement 1: Persistent authentication check.
  Future<void> _checkAuthentication() async {
    await Future.delayed(const Duration(milliseconds: 1500));

    final loggedIn = await _userService.isLoggedIn();

    if (!mounted) return;

    if (loggedIn) {
      final userData = await _userService.getUserData();
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/home', arguments: userData);
    } else {
      Navigator.pushReplacementNamed(context, '/signin');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 118.w,
              height: 118.w,
              padding: EdgeInsets.all(4.w),
              child: Image.asset(
                'assets/nu_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: 18.h),
            CustomText(
              text: 'NUBD Exchange',
              fontSize: 22.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
            SizedBox(height: 5.h),
            CustomText(
              text: 'Your campus marketplace',
              fontSize: 13.sp,
              fontWeight: FontWeight.w400,
            ),
            SizedBox(height: 32.h),
            SizedBox(
              width: 24.w,
              height: 24.w,
              child: const CircularProgressIndicator(
                strokeWidth: 2.5,
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.accentAmber,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}
