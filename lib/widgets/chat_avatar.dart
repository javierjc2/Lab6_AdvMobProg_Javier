import 'package:flutter/material.dart';

import 'custom_text.dart';

/// Round avatar showing the first letter of [name] on a colour that is
/// derived from [seed] (so a user always gets the same colour). When
/// [heroTag] is set the avatar flies between the chat list and the chat
/// screen.
class ChatAvatar extends StatelessWidget {
  const ChatAvatar({
    super.key,
    required this.name,
    required this.seed,
    this.radius = 24,
    this.heroTag,
  });

  final String name;
  final String seed;
  final double radius;
  final String? heroTag;

  static const List<Color> _palette = [
    Color(0xFF5C6BC0),
    Color(0xFF26A69A),
    Color(0xFFEF6C00),
    Color(0xFFAB47BC),
    Color(0xFF42A5F5),
    Color(0xFFEC407A),
    Color(0xFF66BB6A),
    Color(0xFF8D6E63),
  ];

  @override
  Widget build(BuildContext context) {
    final sum = seed.codeUnits.fold<int>(0, (a, b) => a + b);
    final color = _palette[sum % _palette.length];
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();

    final avatar = CircleAvatar(
      radius: radius,
      backgroundColor: color,
      child: CustomText(
        text: initial,
        fontSize: radius * 0.85,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );

    if (heroTag == null) return avatar;
    // Material keeps the text style correct while the Hero is mid-flight.
    return Hero(
      tag: heroTag!,
      child: Material(type: MaterialType.transparency, child: avatar),
    );
  }
}
