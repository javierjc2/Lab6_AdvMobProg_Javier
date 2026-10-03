import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../providers/theme_provider.dart';
import '../utils/session_helper.dart';
import '../widgets/custom_text.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the ThemeProvider instance
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: CustomText(
          text: 'Settings',
          fontSize: 20.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        children: [
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ListTile(
              leading: Icon(
                themeProvider.isDark ? Icons.dark_mode : Icons.light_mode,
                size: 24.sp,
              ),
              title: CustomText(
                text: 'Dark Mode',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              trailing: Switch(
                value: themeProvider.isDark,
                onChanged: (bool value) {
                  themeProvider.toggleTheme();
                },
              ),
            ),
          ),
          SizedBox(height: 12.h),
          // Lab Activity 5: Logout in settings -> clears the session and
          // goes back to the sign-in screen.
          Card(
            elevation: 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: ListTile(
              leading: Icon(
                Icons.logout,
                size: 24.sp,
                color: const Color(0xFFE5533C),
              ),
              title: CustomText(
                text: 'Log Out',
                fontSize: 16.sp,
                fontWeight: FontWeight.w500,
              ),
              onTap: () => confirmAndLogout(context),
            ),
          ),
        ],
      ),
    );
  }
}
