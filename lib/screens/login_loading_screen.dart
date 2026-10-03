import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../theme/app_colors.dart';
import '../widgets/custom_text.dart';

/// A short branded transition shown immediately after a successful login.
/// It keeps the authentication result intact while Home initializes the
/// user's cart in the background.
class LoginLoadingScreen extends StatefulWidget {
  final Map<String, dynamic> userData;

  const LoginLoadingScreen({
    super.key,
    required this.userData,
  });

  @override
  State<LoginLoadingScreen> createState() => _LoginLoadingScreenState();
}

class _LoginLoadingScreenState extends State<LoginLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _openHome();
  }

  Future<void> _openHome() async {
    await Future.delayed(const Duration(milliseconds: 1100));

    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/home',
      arguments: widget.userData,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 36.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 132.w,
                height: 132.w,
                padding: EdgeInsets.all(4.w),
                child: Image.asset(
                  'assets/nu_icon.png',
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(height: 20.h),
              CustomText(
                text: 'NUBD Exchange',
                fontSize: 23.sp,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
              SizedBox(height: 7.h),
              CustomText(
                text: 'Signing you in...',
                fontSize: 14.sp,
                fontWeight: FontWeight.w500,
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: 150.w,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.r),
                  child: const LinearProgressIndicator(
                    minHeight: 5,
                    backgroundColor: Color(0xFFE7E6EF),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.accentAmber,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 12.h),
              CustomText(
                text: 'Signing in to your account...',
                fontSize: 12.sp,
                fontWeight: FontWeight.w400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
