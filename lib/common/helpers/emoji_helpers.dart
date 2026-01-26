import 'dart:math';

import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/models/themes.dart';

const _availableEmojis = [
  // Faces
  '🐶', '🐺', '🐱', '🦁', '🐯', '🐴', '🦄', '🐮', '🐷', '🐽',
  '🐸',
  '🐵',
  '🙈', '🙉', '🙊',

  // Pets & farm
  '🐹', '🐰', '🦊', '🐻', '🐼', '🐻‍❄️', '🐨', '🐮', '🐔',
  '🐤',
  '🐥',
  '🐣',
  '🐧', '🦆', '🦅', '🦉', '🦇',

  // Wild animals
  '🐗', '🐴', '🦓', '🦍', '🦧', '🐘', '🦛', '🦏', '🦒',
  '🐪', '🐫', '🦙', '🦌', '🦬',

  // Sea life
  '🐶', '🐱', '🐭', '🐹', '🐰', '🦊', '🐻', '🐼', '🐨',
  '🐟', '🐠', '🐡', '🦈', '🐬', '🐳', '🐋', '🦭', '🐙', '🦑',
  '🦀',
  '🦞',
  '🦐',

  // Reptiles & insects
  '🐍', '🦎', '🐢', '🐊', '🦖', '🦕',
  '🐝', '🐞', '🦋', '🐛', '🪲', '🪳', '🕷️', '🦂',

  // More birds
  '🦃', '🦚', '🦜', '🦢', '🦩', '🕊️', '🐦',

  // Extras
  '🦘', '🦥', '🦦', '🦨', '🦡', '🐿️', '🦔',
];

class EmojiHelpers {
  static const String unknownEmoji = '👻';

  static String get randomEmoji {
    return _availableEmojis[Random().nextInt(_availableEmojis.length)];
  }

  static Widget picker({required Function(String emoji) onSelected}) =>
      Container(
          decoration: BoxDecoration(
            border:
                Border.all(width: 5, color: studentTheme().colorScheme.primary),
          ),
          // height: 242,
          //width: 300,
          child: Wrap(
            direction: Axis.horizontal,
            children: _availableEmojis
                .map((emoji) => _EmojiChip(
                      emoji: emoji,
                      onTap: () => onSelected(emoji),
                    ))
                .toList(),
          ));
}

class _EmojiChip extends StatelessWidget {
  const _EmojiChip({required this.emoji, required this.onTap});

  final String emoji;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
