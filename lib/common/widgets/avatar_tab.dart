import 'package:flutter/material.dart';
import 'package:mon_stage_en_images/common/models/user.dart';

class AvatarTab extends StatelessWidget {
  const AvatarTab({super.key, required this.user, this.size = 36.0});

  final User user;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        user.avatar,
        style: TextStyle(fontSize: size),
      ),
    );
  }
}
