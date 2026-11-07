import 'package:flutter/material.dart';
import 'package:mators_car/screens/messages/chat_thread_screen.dart';
import 'package:mators_car/services/controllers/message_service.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';

/// قائمة المحادثات — نقطة الدخول لنظام الرسائل الحقيقي داخل التطبيق.
class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() =>
      _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final MessageService _messageService = MessageService();
  late Future<List<Map<String, dynamic>>> _conversationsFuture;

  @override
  void initState() {
    super.initState();
    _conversationsFuture = _messageService.getConversations();
  }

  Future<void> _refresh() async {
    setState(() {
      _conversationsFuture = _messageService.getConversations();
    });
    await _conversationsFuture;
  }

  String _formatRelativeTime(String? iso) {
    if (iso == null) return '';
    final time = DateTime.tryParse(iso);
    if (time == null) return '';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} يوم';
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
        title: const Text('الرسائل', style: TextStyle(color: Colors.black)),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _conversationsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonList(itemCount: 6);
            }
            if (snapshot.hasError) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  const SizedBox(height: 80),
                  Center(
                    child: Text(
                      'تعذر جلب المحادثات\n'
                      '${ApiException.userMessage(snapshot.error)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              );
            }

            final conversations = snapshot.data ?? [];
            if (conversations.isEmpty) {
              return ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 100),
                  Icon(
                    Icons.chat_bubble_outline,
                    size: 56,
                    color: Colors.black26,
                  ),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد محادثات بعد')),
                ],
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final c = conversations[index];
                final unread = (c['unread_count'] as num?)?.toInt() ?? 0;
                final partnerName = c['partner_name']?.toString() ?? 'مستخدم';
                final partnerId = (c['partner_id'] as num?)?.toInt() ?? 0;
                final lastMessage = c['last_message']?.toString() ?? '';
                final isMine = c['last_message_is_mine'] == true;

                return InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => ChatThreadScreen(
                              partnerId: partnerId,
                              partnerName: partnerName,
                            ),
                      ),
                    ).then((_) => _refresh());
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.1,
                          ),
                          child: Text(
                            partnerName.isNotEmpty ? partnerName[0] : '؟',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                partnerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                isMine ? 'أنت: $lastMessage' : lastMessage,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color:
                                      unread > 0
                                          ? Colors.black87
                                          : Colors.grey.shade600,
                                  fontSize: 12,
                                  fontWeight:
                                      unread > 0
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatRelativeTime(
                                c['last_message_at']?.toString(),
                              ),
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontSize: 10,
                              ),
                            ),
                            if (unread > 0) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$unread',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
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
