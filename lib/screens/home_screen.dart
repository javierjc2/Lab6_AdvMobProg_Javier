import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../providers/cart_provider.dart';
import 'product_screen.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  // Enhancement 3: the raw user data handed off by SplashScreen/SignInScreen
  // (from UserService), turned into a typed User below.
  final Map<String, dynamic> userData;

  const HomeScreen({Key? key, required this.userData}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  late final User _user;

  @override
  void initState() {
    super.initState();
    // Enhancement 3: build the typed User model from the data that came
    // out of UserService (either a fresh login response or the data
    // restored from SharedPreferences on a persistent-auth relaunch).
    _user = User.fromJson(widget.userData);

    // Enhancement 3: as soon as Home mounts, load this specific user's
    // cart by their userId, instead of starting from a blank cart.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Provider.of<CartProvider>(
        context,
        listen: false,
      ).fetchUserCart(_user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      ProductScreen(userId: _user.id),
      const ChatScreen(),
      ProfileScreen(user: _user),
    ];

    // The chat FAB is pointless on the Chats tab itself (Index 1).
    bool hideFab = _currentIndex == 1;

    return Scaffold(
      body: screens[_currentIndex],
      floatingActionButton: hideFab
          ? null
          : FloatingActionButton(
              onPressed: () => setState(() => _currentIndex = 1),
              child: const Icon(Icons.chat),
            ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            activeIcon: Icon(Icons.storefront),
            label: 'Shop',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Chats',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
