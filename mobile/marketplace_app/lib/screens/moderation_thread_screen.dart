import 'package:flutter/material.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class ModerationThreadScreen extends StatefulWidget {
  final int threadId;

  const ModerationThreadScreen({
    super.key,
    required this.threadId,
  });

  @override
  State<ModerationThreadScreen> createState() =>
      _ModerationThreadScreenState();
}

class _ModerationThreadScreenState extends State<ModerationThreadScreen> {
  final ApiService _apiService = ApiService();
  final TextEditingController _messageController = TextEditingController();

  ModerationThread? _thread;
  bool _isLoading = true;
  bool _isSending = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadThread();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadThread() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final thread = await _apiService.getModerationThread(widget.threadId);
      if (!mounted) return;
      setState(() {
        _thread = thread;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _thread == null || _thread!.isClosed) return;

    setState(() => _isSending = true);

    try {
      final message =
          await _apiService.sendModerationMessage(widget.threadId, content);
      if (!mounted) return;

      setState(() {
        _thread = ModerationThread(
          id: _thread!.id,
          annonceId: _thread!.annonceId,
          annonceTitle: _thread!.annonceTitle,
          annonceStatus: _thread!.annonceStatus,
          ownerId: _thread!.ownerId,
          ownerName: _thread!.ownerName,
          createdAt: _thread!.createdAt,
          lastMessageAt: message.sentAt,
          isClosed: _thread!.isClosed,
          messages: [..._thread!.messages, message],
        );
      });

      _messageController.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chat avec l\'admin'),
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 56, color: Color(0xFF6B7280)),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadThread,
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      );
    }

    if (_thread == null) {
      return const Center(
        child: Text('Conversation introuvable'),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _loadThread,
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: _thread!.messages.length,
              itemBuilder: (context, index) {
                final message = _thread!.messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
        ),
        _buildComposer(),
      ],
    );
  }

  Widget _buildHeader() {
    final thread = _thread!;
    final statusLabel = thread.annonceStatus.toLowerCase() == 'underreview'
        ? 'En révision'
        : thread.annonceStatus;

    final colors = Theme.of(context).extension<AppColors>()!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          bottom: BorderSide(color: colors.border),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            thread.annonceTitle,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            thread.isClosed ? '$statusLabel • clôturé' : statusLabel,
            style: TextStyle(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ModerationMessage message) {
    final isMe = message.isMe;
    final colors = Theme.of(context).extension<AppColors>()!;
    final background = isMe ? colors.primary : colors.surfaceElevated1;
    final foreground = isMe ? colors.textOnPrimary : colors.textPrimary;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.isFromAdmin ? 'Admin' : message.senderName,
              style: TextStyle(
                color: isMe ? colors.textOnPrimary.withValues(alpha: 0.7) : colors.textTertiary,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              message.content,
              style: TextStyle(color: foreground),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer() {
    final isClosed = _thread?.isClosed ?? true;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                enabled: !isClosed && !_isSending,
                minLines: 1,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: isClosed
                      ? 'Conversation clôturée'
                      : 'Ecrire a l\'admin...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: isClosed || _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
            ),
          ],
        ),
      ),
    );
  }
}
