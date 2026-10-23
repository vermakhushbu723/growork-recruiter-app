import 'dart:async';

import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/widgets/empty_state.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../core/utils/extensions.dart';
import '../../../../core/widgets/ui_kit.dart';
import 'call_screen.dart';

class _Bubble {
  const _Bubble(this.text, this.isMe);
  final String text;
  final bool isMe;
}

/// Who to chat with: an existing conversation, or a user to start one
/// with (the server reuses an existing 1:1 conversation if there is one).
class ChatTarget {
  const ChatTarget({
    this.conversationId,
    this.userId,
    required this.name,
    this.context = '',
  });

  final String? conversationId;
  final String? userId;
  final String name;

  /// What the chat is about, e.g. the job title.
  final String context;
}

class ChatRoomScreen extends StatefulWidget {
  const ChatRoomScreen({super.key, required this.target});

  final ChatTarget target;

  @override
  State<ChatRoomScreen> createState() => _ChatRoomScreenState();
}

class _ChatRoomScreenState extends State<ChatRoomScreen> {
  final _controller = TextEditingController();
  final List<_Bubble> _messages = [];
  late String? _conversationId = widget.target.conversationId;
  late String _subtitle = widget.target.context;
  bool _loading = true;
  bool _sending = false;
  String? _error;
  Timer? _poll;

  String get chatName => widget.target.name;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    try {
      if (_conversationId == null) {
        final userId = widget.target.userId;
        if (userId == null || userId.isEmpty) {
          throw ApiException('This person can’t be messaged yet.');
        }
        final c = jMap(
          await api.post('/chats/start', {
            'userId': userId,
            'context': widget.target.context,
          }),
        );
        _conversationId = jStr(c['id']);
      }
      await _refresh();
      // Simple polling keeps the conversation live without sockets.
      _poll = Timer.periodic(const Duration(seconds: 5), (_) => _refresh());
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _refresh() async {
    final id = _conversationId;
    if (id == null) return;
    try {
      final d = jMap(await api.get('/chats/$id/messages'));
      if (!mounted) return;
      final context = jStr(jMap(d['conversation'])['context']);
      setState(() {
        if (context.isNotEmpty) _subtitle = context;
        _messages
          ..clear()
          ..addAll([
            for (final m in jMapList(d['messages']))
              _Bubble(jStr(m['text']), jBool(m['isMe'])),
          ]);
      });
    } on ApiException catch (_) {
      // Keep showing what we have; the next poll retries.
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final id = _conversationId;
    if (text.isEmpty || id == null || _sending) return;
    setState(() => _sending = true);
    final ok = await context.runApi(
      () => api.post('/chats/$id/messages', {'text': text}),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      if (ok) {
        _messages.add(_Bubble(text, true));
        _controller.clear();
      }
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final initial = chatName.isNotEmpty
        ? chatName.substring(0, 1).toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Row(
          children: [
            CircleAvatar(
              radius: 16,
              backgroundColor: context.tagBgColor,
              child: Text(
                initial,
                style: TextStyle(
                  color: context.accentColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    chatName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (_subtitle.isNotEmpty)
                    Text(
                      _subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textTheme.bodySmall?.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Voice call',
            icon: Icon(Icons.call_outlined, color: context.accentColor),
            onPressed: () =>
                context.push(RoutePaths.call, extra: CallArgs(name: chatName)),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? EmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'Chat unavailable',
                    message: _error,
                  )
                : _messages.isEmpty
                ? EmptyState(
                    icon: Icons.waving_hand_outlined,
                    title: 'Say hello to $chatName',
                    message: 'Your messages will appear here',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final m = _messages[index];
                      return Align(
                        alignment: m.isMe
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            constraints: BoxConstraints(
                              // Narrower bubbles on tablets / landscape.
                              maxWidth: constraints.maxWidth > 600
                                  ? constraints.maxWidth * 0.55
                                  : constraints.maxWidth * 0.78,
                            ),
                            decoration: BoxDecoration(
                              color: m.isMe
                                  ? AppColors.primary
                                  : context.surfaceColor,
                              border: m.isMe
                                  ? null
                                  : Border.all(color: context.borderColor),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(m.isMe ? 16 : 4),
                                bottomRight: Radius.circular(m.isMe ? 4 : 16),
                              ),
                              boxShadow: context.cardShadow,
                            ),
                            child: Text(
                              m.text,
                              style: TextStyle(
                                fontSize: 11.5,
                                height: 1.35,
                                color: m.isMe
                                    ? Colors.white
                                    : context.textMainColor,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          _InputBar(controller: _controller, onSend: _send),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  const _InputBar({required this.controller, required this.onSend});

  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.surfaceColor,
        border: Border(top: BorderSide(color: context.borderColor)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(6, 8, 10, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              IconButton(
                tooltip: 'Attach',
                icon: Icon(
                  Icons.attach_file_rounded,
                  color: context.textSubColor,
                ),
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  builder: (sheetContext) => SheetBody(
                    title: 'Share',
                    children: [
                      for (final o in const [
                        (Icons.description_outlined, 'Document'),
                        (Icons.image_outlined, 'Photo'),
                        (Icons.photo_camera_outlined, 'Camera'),
                        (Icons.local_offer_outlined, 'Offer Letter'),
                      ])
                        SheetOption(
                          icon: o.$1,
                          label: o.$2,
                          onTap: () {
                            Navigator.pop(sheetContext);
                            context.showSnackBar('${o.$2} picker coming soon');
                          },
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.send,
                  decoration: InputDecoration(
                    hintText: 'Type a message',
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: context.isDark
                            ? AppColors.inputBorderDark
                            : AppColors.inputBorder,
                        width: 1.3,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(
                        color: context.accentColor,
                        width: 2,
                      ),
                    ),
                  ),
                  onSubmitted: (_) => onSend(),
                ),
              ),
              const SizedBox(width: 8),
              Material(
                color: AppColors.primary,
                shape: const CircleBorder(),
                elevation: 2,
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: onSend,
                  child: const SizedBox(
                    width: 38,
                    height: 38,
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 17,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
