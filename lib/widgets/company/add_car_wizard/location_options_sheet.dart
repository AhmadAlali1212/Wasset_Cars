import 'package:flutter/material.dart';

class LocationOptionsSheet extends StatelessWidget {
  final String location;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const LocationOptionsSheet({
    super.key,
    required this.location,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            location,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 14),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('تعديل الموقع'),
            onTap: onEdit,
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline),
            title: const Text('حذف الموقع'),
            onTap: onDelete,
          ),
        ],
      ),
    );
  }
}
