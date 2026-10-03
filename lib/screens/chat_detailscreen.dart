import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../services/chat_service.dart';
import '../theme/app_colors.dart';
import '../widgets/chat_avatar.dart';
import '../widgets/custom_text.dart';

/// Delivery state of one of MY messages.
enum _MessageStatus { sending, delivered, seen }

/// Enhancement 3: redesigned conversation screen.
///
///  * gradient "me" bubbles vs. plain "them" bubbles, with a tail on the last
///    bubble of each group
///  * sending states: clock + "Sending..." -> single check (delivered) ->
///    double blue check (seen)
///  * new messages fade/slide in, the page itself fades/slides in too
class ChatDetailScreen extends StatefulWidget {
  final Map<String, dynamic> tappedUser;

  const ChatDetailScreen({super.key, required this.tappedUser});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final ChatService _chatService = ChatService();
  final TextEditingController _msgCtrl = TextEditingController();
  final FocusNode _msgFocus = FocusNode();
  final ScrollController _scrollCtrl = ScrollController();

  late final String _myId;
  late final String _otherId;
  late final String _otherName;

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _sub;
  QuerySnapshot<Map<String, dynamic>>? _snapshot;
  Object? _error;

  // Message ids already seen, and the subset that should play the
  // fade/slide-in (only brand-new messages, never the loaded history).
  final Set<String> _knownIds = {};
  final Set<String> _animateIds = {};

  @override
  void initState() {
    super.initState();
    _myId = _chatService.currentUid ?? '';
    _otherId = (widget.tappedUser['uid'] ?? '').toString();
    _otherName = ChatService.displayName(widget.tappedUser);

    // One subscription drives both the UI and the "mark as seen" write.
    _sub = _chatService
        .getMessage(_myId, _otherId)
        .listen(
          (snap) {
            if (!mounted) return;
            _registerNewMessages(snap.docs);
            setState(() {
              _snapshot = snap;
              _error = null;
            });
            _chatService.markMessagesAsRead(snap.docs);
          },
          onError: (Object e) {
            if (mounted) setState(() => _error = e);
          },
        );
  }

  @override
  void dispose() {
    _sub?.cancel();
    _msgCtrl.dispose();
    _msgFocus.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _registerNewMessages(List<QueryDocumentSnapshot<Map<String, dynamic>>> docs) {
    final now = DateTime.now();
    for (final d in docs) {
      if (_knownIds.add(d.id)) {
        final ts = d.data()['timestamp'];
        final fresh = d.metadata.hasPendingWrites ||
            (ts is Timestamp && now.difference(ts.toDate()).inSeconds.abs() < 15);
        if (fresh) _animateIds.add(d.id);
      }
    }
  }

  // ---------------------------------------------------------------- sending

  void _send() {
    final text = _msgCtrl.text.trim();
    if (text.isEmpty || _myId.isEmpty) return;

    _msgCtrl.clear();
    _msgFocus.requestFocus();

    // Not awaited on purpose: Firestore shows the message instantly as a
    // pending write ("Sending...") and acknowledges it when the server has it.
    _chatService.sendMessage(_otherId, text).catchError((Object e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e')),
      );
    });

    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            ChatAvatar(
              name: _otherName,
              seed: _otherId,
              radius: 18,
              heroTag: 'avatar_$_otherId',
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomText(
                    text: _otherName,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  CustomText(
                    text: (widget.tappedUser['email'] ?? '').toString(),
                    fontSize: 11.sp,
                    color: Colors.white70,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessages()),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: CustomText(
            text: 'Error loading messages.\nCheck your Firestore security rules.',
            fontSize: 14.sp,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (_snapshot == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }

    final docs = _snapshot!.docs; // newest first
    if (docs.isEmpty) return _buildEmptyChat();

    // The newest message I sent gets the "Sending... / Delivered / Seen" caption.
    final latestOutgoing = docs.indexWhere((d) => d.data()['senderId'] == _myId);

    return ListView.builder(
      controller: _scrollCtrl,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: docs.length,
      itemBuilder: (context, index) {
        final doc = docs[index];
        final data = doc.data();
        final isMe = data['senderId'] == _myId;
        final time = _timeOf(data);

        final older = index + 1 < docs.length ? docs[index + 1] : null;
        final newer = index > 0 ? docs[index - 1] : null;

        final showDate = older == null || !_sameDay(_timeOf(older.data()), time);
        final sameAsOlder = older != null &&
            !showDate &&
            older.data()['senderId'] == data['senderId'];
        final isLastInGroup =
            newer == null || newer.data()['senderId'] != data['senderId'];

        _MessageStatus? status;
        if (isMe) {
          status = doc.metadata.hasPendingWrites
              ? _MessageStatus.sending
              : (data['isRead'] == true
                  ? _MessageStatus.seen
                  : _MessageStatus.delivered);
        }

        Widget bubble = _MessageBubble(
          text: (data['message'] ?? '').toString(),
          time: _formatTime(time),
          isMe: isMe,
          status: status,
          isLastInGroup: isLastInGroup,
          showCaption: isMe && index == latestOutgoing,
          topGap: sameAsOlder ? 2 : 10,
        );

        if (_animateIds.contains(doc.id)) {
          bubble = _Entrance(
            fromRight: isMe,
            onEnd: () => _animateIds.remove(doc.id),
            child: bubble,
          );
        }

        return Column(
          key: ValueKey(doc.id),
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDate) _DateChip(label: _dayLabel(time)),
            bubble,
          ],
        );
      },
    );
  }

  Widget _buildEmptyChat() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOut,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.9 + 0.1 * t, child: child),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.waving_hand_outlined, size: 52.sp, color: Colors.grey),
            const SizedBox(height: 12),
            CustomText(
              text: 'Say hi to $_otherName!',
              fontSize: 15.sp,
              fontWeight: FontWeight.w600,
            ),
            const SizedBox(height: 4),
            CustomText(
              text: 'No messages yet.',
              fontSize: 12.sp,
              color: Colors.grey,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = isDark ? const Color(0xFF5B57C7) : AppColors.primaryNavy;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1D1D29) : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: isDark ? Colors.white12 : Colors.grey.shade300,
                  ),
                ),
                child: TextField(
                  controller: _msgCtrl,
                  focusNode: _msgFocus,
                  minLines: 1,
                  maxLines: 5,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15),
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: TextStyle(fontFamily: 'Poppins'),
                    filled: false,
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // The send button wakes up (colour + scale) once there is text.
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _msgCtrl,
              builder: (context, value, _) {
                final canSend = value.text.trim().isNotEmpty;
                return AnimatedScale(
                  scale: canSend ? 1 : 0.88,
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOut,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: canSend ? accent : Colors.grey.shade500,
                    ),
                    child: IconButton(
                      tooltip: 'Send',
                      icon: const Icon(Icons.send_rounded, color: Colors.white),
                      onPressed: canSend ? _send : null,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- helpers

  static DateTime _timeOf(Map<String, dynamic> data) {
    final ts = data['timestamp'];
    return ts is Timestamp ? ts.toDate() : DateTime.now();
  }

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static String _formatTime(DateTime t) {
    final h = t.hour % 12 == 0 ? 12 : t.hour % 12;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.hour >= 12 ? 'PM' : 'AM'}';
  }

  static String _dayLabel(DateTime d) {
    final now = DateTime.now();
    if (_sameDay(d, now)) return 'Today';
    if (_sameDay(d, now.subtract(const Duration(days: 1)))) return 'Yesterday';
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final year = d.year == now.year ? '' : ', ${d.year}';
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}$year';
  }
}

// ============================================================================
// Message bubble
// ============================================================================

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.text,
    required this.time,
    required this.isMe,
    required this.status,
    required this.isLastInGroup,
    required this.showCaption,
    required this.topGap,
  });

  final String text;
  final String time;
  final bool isMe;
  final _MessageStatus? status; // null for incoming messages
  final bool isLastInGroup;
  final bool showCaption;
  final double topGap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    const big = Radius.circular(18);
    const tail = Radius.circular(4);
    final radius = BorderRadius.only(
      topLeft: big,
      topRight: big,
      bottomLeft: (!isMe && isLastInGroup) ? tail : big,
      bottomRight: (isMe && isLastInGroup) ? tail : big,
    );

    final BoxDecoration decoration = isMe
        ? BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? const [Color(0xFF4A47A3), Color(0xFF6561C9)]
                  : const [AppColors.primaryNavy, Color(0xFF4B47A8)],
            ),
          )
        : BoxDecoration(
            borderRadius: radius,
            color: isDark ? const Color(0xFF2A2A3A) : Colors.white,
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.07),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
          );

    final textColor = isMe
        ? Colors.white
        : (isDark ? const Color(0xFFF2F1F7) : AppColors.textDark);
    final metaColor = isMe
        ? Colors.white70
        : (isDark ? Colors.white54 : AppColors.textGrey);

    return Padding(
      padding: EdgeInsets.only(top: topGap),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.78,
            ),
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
            decoration: decoration,
            // IntrinsicWidth: short messages stay narrow while the time /
            // status row still sits at the bubble's bottom-right.
            child: IntrinsicWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CustomText(
                    text: text.isNotEmpty ? text : '[empty]',
                    fontSize: 15.sp,
                    color: textColor,
                  ),
                  const SizedBox(height: 3),
                  Align(
                    alignment: Alignment.centerRight,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomText(text: time, fontSize: 10.sp, color: metaColor),
                        if (status != null) ...[
                          const SizedBox(width: 4),
                          _StatusIcon(status: status!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (showCaption && status != null)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: CustomText(
                  key: ValueKey(status),
                  text: switch (status!) {
                    _MessageStatus.sending => 'Sending...',
                    _MessageStatus.delivered => 'Delivered',
                    _MessageStatus.seen => 'Seen',
                  },
                  fontSize: 10.sp,
                  color: isDark ? Colors.white54 : AppColors.textGrey,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Clock (sending) -> check (delivered) -> double blue check (seen).
class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.status});

  final _MessageStatus status;

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    final Color color;
    switch (status) {
      case _MessageStatus.sending:
        icon = Icons.access_time_rounded;
        color = Colors.white70;
      case _MessageStatus.delivered:
        icon = Icons.done_rounded;
        color = Colors.white70;
      case _MessageStatus.seen:
        icon = Icons.done_all_rounded;
        color = Colors.lightBlueAccent.shade100;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: animation, child: child),
      ),
      child: Icon(icon, key: ValueKey(status), size: 14, color: color),
    );
  }
}

class _DateChip extends StatelessWidget {
  const _DateChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: CustomText(
            text: label,
            fontSize: 11.sp,
            color: isDark ? Colors.white60 : AppColors.textGrey,
          ),
        ),
      ),
    );
  }
}

/// Fade + slide-up entrance for freshly arrived messages (my messages slide
/// in from the right, theirs from the left).
class _Entrance extends StatelessWidget {
  const _Entrance({
    required this.child,
    required this.fromRight,
    required this.onEnd,
  });

  final Widget child;
  final bool fromRight;
  final VoidCallback onEnd;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
      onEnd: onEnd,
      builder: (context, t, child) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset((fromRight ? 28 : -28) * (1 - t), 16 * (1 - t)),
          child: child,
        ),
      ),
      child: child,
    );
  }
}
