import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/services/controllers/auth_service.dart';
import 'package:mators_car/services/controllers/message_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/common/skeleton_loader.dart';
import 'package:mators_car/widgets/common/report_user_sheet.dart';

/// محادثة حقيقية داخل التطبيق مع مستخدم آخر — بديل عملي عن الاعتماد
/// الكامل على واتساب خارجي، خصوصاً للتواصل حول مزاد/حجز/إعلان معيّن.
/// تحديث بالاستطلاع الدوري (polling) وليس WebSocket، كخطوة عملية أولى.
class ChatThreadScreen extends StatefulWidget {
  final int partnerId;
  final String partnerName;

  const ChatThreadScreen({
    super.key,
    required this.partnerId,
    required this.partnerName,
  });

  @override
  State<ChatThreadScreen> createState() => _ChatThreadScreenState();
}

class _ChatThreadScreenState extends State<ChatThreadScreen> {
  final MessageService _messageService = MessageService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = true;
  bool _isSending = false;
  int? _myUserId;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    final authService = Provider.of<AuthService>(context, listen: false);
    _myUserId = int.tryParse('${authService.currentUser?['id'] ?? ''}');
    _loadThread();
    _pollTimer = Timer.periodic(const Duration(seconds: 6), (_) => _loadThread(silent: true));
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadThread({bool silent = false}) async {
    if (!silent) setState(() => _isLoading = true);
    try {
      // السيرفر يرجع الأحدث أولاً؛ نعكس الترتيب لعرضه من الأقدم للأحدث بالأسفل
      final messages = (await _messageService.getThread(widget.partnerId)).reversed.toList();
      if (!mounted) return;
      setState(() {
        _messages = messages;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      if (!silent) {
        AppSnackbar.showError(context, title: 'تعذّر تحميل الرسائل', debugMessage: e);
      }
    }
  }

  Future<void> _sendMessage() async {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _inputController.clear();
    try {
      await _messageService.sendMessage(receiverId: widget.partnerId, content: text);
      await _loadThread(silent: true);
      if (mounted && _scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(context, title: 'تعذّر إرسال الرسالة', debugMessage: e);
      _inputController.text = text;
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Text(widget.partnerName, style: const TextStyle(color: Colors.black, fontSize: 16)),
        actions: [
          // ⬅️ جديد: إبلاغ/حظر مباشرة من نفس المحادثة
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onSelected: (value) {
              if (value == 'report') {
                ReportUserSheet.show(
                  context,
                  reportedUserId: widget.partnerId,
                  contextType: 'message',
                );
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'report', child: Text('إبلاغ / حظر')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const SkeletonList(itemCount: 6)
                : _messages.isEmpty
                    ? const Center(
                        child: Text('لا توجد رسائل بعد، ابدأ المحادثة الآن', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(16),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final msg = _messages[index];
                          final isMine = (msg['sender_id'] as num?)?.toInt() == _myUserId;
                          return _MessageBubble(content: msg['content']?.toString() ?? '', isMine: isMine);
                        },
                      ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputController,
                      textAlign: TextAlign.right,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'اكتب رسالتك...',
                        filled: true,
                        fillColor: const Color(0xFFF4F6F9),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(20),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isSending ? null : _sendMessage,
                    icon: _isSending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String content;
  final bool isMine;

  const _MessageBubble({required this.content, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        decoration: BoxDecoration(
          color: isMine ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 16),
          ),
        ),
        child: Text(
          content,
          textAlign: TextAlign.right,
          style: TextStyle(color: isMine ? Colors.white : Colors.black87, fontSize: 14),
        ),
      ),
    );
  }
}
