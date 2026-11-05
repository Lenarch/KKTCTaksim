import 'package:flutter/material.dart';
import 'package:kktc_taksim/core/app_theme.dart';
import 'package:kktc_taksim/core/app_tokens.dart';
import 'package:kktc_taksim/core/formatters.dart';
import 'package:kktc_taksim/core/l10n.dart';
import 'package:kktc_taksim/core/labels.dart';
import 'package:kktc_taksim/core/ui_helpers.dart';
import 'package:kktc_taksim/data/backend.dart';
import 'package:kktc_taksim/data/repositories/shared_ride_repository.dart';
import 'package:kktc_taksim/models/chat_message.dart';
import 'package:kktc_taksim/models/shared_ride.dart';
import 'package:kktc_taksim/services/chat_read_state.dart';
import 'package:kktc_taksim/widgets/async_view.dart';

/// Paylaşımlı grubun üyeleri arasındaki sohbet (buluşma yeri, saat, bagaj vb.).
class GroupChatScreen extends StatefulWidget {
  final SharedRide ride;

  const GroupChatScreen({super.key, required this.ride});

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  SharedRideRepository get _repository => Backend.instance.sharedRides;
  late Stream<List<ChatMessage>> _messages = _repository.watchMessages(widget.ride.id);
  late final Stream<Set<String>> _blocked = _repository.watchBlocked();
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focus = FocusNode();
  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (_sending || normalizeMessage(text) == null) return;
    final l10n = context.l10n;
    setState(() => _sending = true);
    try {
      await _repository.sendMessage(widget.ride.id, text);
      _controller.clear();
      // Enter'la gönderince odak kayboluyor; arka arkaya yazılabilsin.
      _focus.requestFocus();
    } on SharedRideException catch (e) {
      if (mounted) showMessage(context, e.error == SharedRideError.notMember ? l10n.notGroupMember : l10n.actionFailed);
    } catch (_) {
      if (mounted) showMessage(context, l10n.actionFailed);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  String _displayName(ChatMessage message) {
    final name = message.senderName?.trim();
    return name == null || name.isEmpty ? context.l10n.unnamedPassenger : name;
  }

  /// Başkasının mesajına uzun basınca: şikâyet et / engelle.
  Future<void> _showMessageActions(ChatMessage message) async {
    final l10n = context.l10n;
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: Text(l10n.reportMessage),
              onTap: () => Navigator.pop(context, 'report'),
            ),
            ListTile(
              leading: Icon(Icons.block, color: Theme.of(context).colorScheme.error),
              title: Text(l10n.blockUser, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              onTap: () => Navigator.pop(context, 'block'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (action) {
      case 'report':
        await _report(message);
      case 'block':
        await _block(message);
    }
  }

  Future<void> _report(ChatMessage message) async {
    final l10n = context.l10n;
    final reason = await showDialog<ReportReason>(
      context: context,
      builder: (context) => SimpleDialog(
        title: Text(l10n.reportReasonTitle),
        children: [
          for (final reason in ReportReason.values)
            SimpleDialogOption(
              onPressed: () => Navigator.pop(context, reason),
              child: Text(reason.label(l10n)),
            ),
        ],
      ),
    );
    if (reason == null || !mounted) return;
    try {
      await _repository.report(widget.ride.id, message, reason);
      if (mounted) showMessage(context, l10n.reportSent);
    } catch (e) {
      debugPrint('Şikâyet gönderilemedi: $e');
      if (mounted) showMessage(context, l10n.actionFailed);
    }
  }

  Future<void> _block(ChatMessage message) async {
    final l10n = context.l10n;
    final name = _displayName(message);
    final confirmed = await confirm(
      context,
      title: l10n.blockUserTitle(name),
      message: l10n.blockUserMessage,
      confirmLabel: l10n.blockUser,
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    try {
      await _repository.block(message.senderId);
      if (mounted) showMessage(context, l10n.userBlocked(name));
    } catch (e) {
      debugPrint('Engellenemedi: $e');
      if (mounted) showMessage(context, l10n.actionFailed);
    }
  }

  Future<void> _unblock(String userId) async {
    final l10n = context.l10n;
    final confirmed = await confirm(
      context,
      title: l10n.unblockUser,
      message: l10n.unblockUserMessage,
      confirmLabel: l10n.unblockUser,
    );
    if (!confirmed || !mounted) return;
    try {
      await _repository.unblock(userId);
      if (mounted) showMessage(context, l10n.userUnblocked);
    } catch (e) {
      debugPrint('Engel kaldırılamadı: $e');
      if (mounted) showMessage(context, l10n.actionFailed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final userId = Backend.instance.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.groupChat),
            Text(
              '${l10n.groupChatTitle(widget.ride.from, widget.ride.to)} • ${context.serviceWeekdayDate(widget.ride.departure)} '
              '${context.serviceTimeLabel(widget.ride.departure)}',
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: AsyncView<List<ChatMessage>>(
              stream: _messages,
              onRetry: () => setState(() => _messages = _repository.watchMessages(widget.ride.id)),
              builder: (context, messages) {
                if (messages.isNotEmpty) {
                  // Rozetler build sırasında değil, kare çizildikten sonra güncellensin.
                  final latest = messages.last.sentAt;
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => ChatReadState.instance.markRead(widget.ride.id, latest));
                }
                if (messages.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.xxl),
                      child: Text(
                        l10n.chatEmpty,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  );
                }
                // En yeni mesaj altta; liste ters çevrilerek alttan başlar.
                return StreamBuilder<Set<String>>(
                  stream: _blocked,
                  initialData: const {},
                  builder: (context, blockedSnapshot) {
                    final blocked = blockedSnapshot.data ?? const {};
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[messages.length - 1 - index];
                        final mine = message.senderId == userId;
                        if (!mine && blocked.contains(message.senderId)) {
                          return _BlockedPlaceholder(onLongPress: () => _unblock(message.senderId));
                        }
                        return _MessageBubble(
                          message: message,
                          mine: mine,
                          name: _displayName(message),
                          onLongPress: mine ? null : () => _showMessageActions(message),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            child: Text(
              '${l10n.chatPrivacyNote} ${l10n.chatRulesNote}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('chatInput'),
                      controller: _controller,
                      focusNode: _focus,
                      maxLength: ChatMessage.maxLength,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(hintText: l10n.messageHint, counterText: ''),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  IconButton.filled(
                    tooltip: l10n.sendMessage,
                    onPressed: _sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppTheme.primaryYellow,
                      foregroundColor: AppTheme.primaryBlack,
                    ),
                    icon: const Icon(Icons.send),
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
  final ChatMessage message;
  final bool mine;
  final String name;

  /// Başkasının mesajında şikâyet/engelle menüsü.
  final VoidCallback? onLongPress;

  const _MessageBubble({required this.message, required this.mine, required this.name, this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = mine ? AppTheme.primaryYellow : theme.colorScheme.surfaceContainerHighest;
    final foreground = mine ? AppTheme.primaryBlack : theme.colorScheme.onSurface;
    final muted = foreground.withValues(alpha: 0.7);

    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.75),
        child: Container(
          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
          decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(AppRadius.lg)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!mine)
                Text(
                  name,
                  style: theme.textTheme.labelMedium?.copyWith(color: foreground, fontWeight: FontWeight.bold),
                ),
              Text(message.text, style: theme.textTheme.bodyMedium?.copyWith(color: foreground)),
              Align(
                alignment: Alignment.centerRight,
                child: Text(context.time(message.sentAt), style: theme.textTheme.labelSmall?.copyWith(color: muted)),
              ),
            ],
          ),
        ),
      ),
      ),
    );
  }
}

/// Engellenen kişinin mesajının yerinde duran kısa not; uzun basınca engel kaldırılabilir.
class _BlockedPlaceholder extends StatelessWidget {
  final VoidCallback onLongPress;

  const _BlockedPlaceholder({required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onLongPress: onLongPress,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.block, size: 16, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Text(
                context.l10n.blockedMessage,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
