import 'package:flutter/material.dart';
import 'package:mators_car/services/controllers/dispute_service.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';

/// متابعة حالة النزاعات التي رفعتها أو رُفعت ضدي.
class MyDisputesScreen extends StatefulWidget {
  const MyDisputesScreen({super.key});

  @override
  State<MyDisputesScreen> createState() => _MyDisputesScreenState();
}

class _MyDisputesScreenState extends State<MyDisputesScreen> {
  final DisputeService _disputeService = DisputeService();
  late Future<List<Map<String, dynamic>>> _disputesFuture;

  @override
  void initState() {
    super.initState();
    _disputesFuture = _disputeService.getMyDisputes();
  }

  Future<void> _refresh() async {
    setState(() {
      _disputesFuture = _disputeService.getMyDisputes();
    });
    await _disputesFuture;
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'open':
        return 'مفتوح';
      case 'in_review':
        return 'قيد المراجعة';
      case 'resolved':
        return 'تم الحل';
      case 'rejected':
        return 'مرفوض';
      default:
        return status;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'in_review':
        return Colors.blue;
      default:
        return Colors.orange;
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
        title: const Text('نزاعاتي', style: TextStyle(color: Colors.black)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _disputesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 4);
            }
            final disputes = snapshot.data ?? [];
            if (disputes.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(Icons.gavel_outlined, size: 56, color: Colors.black26),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد نزاعات مرفوعة')),
                ],
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: disputes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final d = disputes[index];
                final status = d['status']?.toString() ?? 'open';
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('نزاع #${d['id']}', style: const TextStyle(fontWeight: FontWeight.bold)),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _statusColor(status).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _statusLabel(status),
                              style: TextStyle(color: _statusColor(status), fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(d['description']?.toString() ?? '', maxLines: 2, overflow: TextOverflow.ellipsis),
                      if ((d['admin_notes'] ?? '').toString().isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          'ملاحظة الدعم: ${d['admin_notes']}',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
