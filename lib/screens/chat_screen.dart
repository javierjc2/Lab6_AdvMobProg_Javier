import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/custom_text.dart';
import 'chat_detailscreen.dart';

/// Second bottom-navigation tab: the chat list.
///
///  * Enhancement 1 - lists every registered user except the logged-in one.
///  * Enhancement 2 - a search bar filters the list by name or email.
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _searchChatController = TextEditingController();
  final ChatService _chatService = ChatService();

  // Created once so rebuilds (e.g. while typing in the search bar) do not
  // re-subscribe to Firestore.
  late final Stream<List<Map<String, dynamic>>> _usersStream =
      _chatService.getUsersStream();

  String _searchText = '';

  @override
  void dispose() {
    _searchChatController.dispose();
    super.dispose();
  }

  /// Matches the query against name, username and email (case-insensitive).
  List<Map<String, dynamic>> _filter(List<Map<String, dynamic>> users) {
    final q = _searchText.toLowerCase();
    if (q.isEmpty) return users;
    return users.where((u) {
      final haystack = [
        ChatService.displayName(u),
        u['username'] ?? '',
        u['email'] ?? '',
      ].join(' ').toLowerCase();
      return haystack.contains(q);
    }).toList();
  }

  void _openChat(Map<String, dynamic> user) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 320),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => ChatDetailScreen(tappedUser: user),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.08, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: _chatService.currentUid == null
          ? _message(
              Icons.lock_outline,
              'Chat is available for Firebase accounts.\n'
              'Sign in with a Firebase account to message other users.',
            )
          : Column(
              children: [
                _buildSearchBar(),
                Expanded(child: _buildUserList()),
              ],
            ),
    );
  }

  // ------------------------------------------------------------ search bar

  Widget _buildSearchBar() {
    final radius = BorderRadius.circular(30);
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 6.h),
      child: TextField(
        controller: _searchChatController,
        textInputAction: TextInputAction.search,
        onChanged: (value) => setState(() => _searchText = value.trim()),
        decoration: InputDecoration(
          hintText: 'Search by name or email...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchText.isNotEmpty
              ? IconButton(
                  tooltip: 'Clear',
                  icon: const Icon(Icons.cancel),
                  onPressed: () {
                    setState(() {
                      _searchChatController.clear();
                      _searchText = '';
                    });
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: radius,
            borderSide: BorderSide(
              color: Theme.of(context).colorScheme.primary,
              width: 1.5,
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------- user list

  Widget _buildUserList() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _usersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator.adaptive());
        }
        if (snapshot.hasError) {
          return _message(
            Icons.error_outline,
            'Error loading users.\nCheck your Firestore security rules.',
          );
        }

        final allUsers = snapshot.data ?? [];
        if (allUsers.isEmpty) {
          return _message(
            Icons.people_outline,
            'No other users yet.\nAsk a classmate to register an account.',
          );
        }

        final users = _filter(allUsers);
        if (users.isEmpty) {
          return _message(
            Icons.search_off,
            'No users match "$_searchText".',
          );
        }

        return ListView.builder(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          itemCount: users.length,
          itemBuilder: (context, index) => _buildUserTile(users[index], index),
        );
      },
    );
  }

  Widget _buildUserTile(Map<String, dynamic> user, int index) {
    final uid = (user['uid'] ?? '').toString();
    final name = ChatService.displayName(user);
    final email = (user['email'] ?? 'No email').toString();

    // Cascading fade/slide-in: lower rows take slightly longer to settle.
    final duration = Duration(milliseconds: 220 + 50 * math.min(index, 8));

    return TweenAnimationBuilder<double>(
      key: ValueKey(uid),
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(offset: Offset(0, 18 * (1 - t)), child: child),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          onTap: () => _openChat(user),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 6,
          ),
          leading: ChatAvatar(
            name: name,
            seed: uid,
            radius: 24,
            heroTag: 'avatar_$uid',
          ),
          title: CustomText(
            text: name,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: CustomText(
            text: email,
            fontSize: 12.sp,
            fontWeight: FontWeight.w300,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: const Icon(Icons.chevron_right),
        ),
      ),
    );
  }

  Widget _message(IconData icon, String text) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56.sp, color: Colors.grey),
            SizedBox(height: 12.h),
            CustomText(
              text: text,
              fontSize: 14.sp,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
