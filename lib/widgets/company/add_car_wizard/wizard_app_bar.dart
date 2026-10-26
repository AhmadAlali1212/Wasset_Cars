import 'package:flutter/material.dart';

class WizardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const WizardAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('إضافة سيارة جديدة'),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 0,
    );
  }
}
