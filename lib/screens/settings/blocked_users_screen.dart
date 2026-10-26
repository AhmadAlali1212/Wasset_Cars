import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/block_service.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final BlockService _blockService = BlockService();
  late Future<List<Map<String, dynamic>>> _blockedFuture;

  @override
  void initState() {
    super.initState();
    _blockedFuture = _blockService.getMyBlockedUsers();
  }

  void _refresh() {
    setState(() {
      _blockedFuture = _blockService.getMyBlockedUsers();
    });
  }

  Future<void> _unblock(int userId) async {
    try {
      await _blockService.unblock(userId);
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تم إلغاء الحظر');
      _refresh();
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر إلغاء الحظر',
        debugMessage: e,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'المستخدمون المحظورون',
          style: TextStyle(color: Colors.black),
        ),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _blockedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const SkeletonList(itemCount: 4);
          }
          final blocks = snapshot.data ?? [];
          if (blocks.isEmpty) {
            return ListView(
              children: const [
                SizedBox(height: 100),
                Icon(Icons.block, size: 56, color: Colors.black26),
                SizedBox(height: 12),
                Center(child: Text('لا يوجد مستخدمون محظورون')),
              ],
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: blocks.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final blockedUser =
                  blocks[index]['blockedUser'] ?? blocks[index]['blocked_user'];
              final name =
                  blockedUser is Map
                      ? blockedUser['name']?.toString() ?? 'مستخدم'
                      : 'مستخدم';
              final userId =
                  blockedUser is Map
                      ? (blockedUser['id'] as num?)?.toInt()
                      : null;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(name),
                  trailing: TextButton(
                    onPressed: userId != null ? () => _unblock(userId) : null,
                    child: const Text('إلغاء الحظر'),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
