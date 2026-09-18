import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/chat_provider.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key, this.initialPrompt});
  final String? initialPrompt;

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    final prompt = widget.initialPrompt;
    if (prompt != null && prompt.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(chatProvider.notifier).send(prompt);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    ref.read(chatProvider.notifier).send(text);
    _scrollDown();
  }

  void _scrollDown() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    ref.listen(chatProvider, (_, __) => _scrollDown());
    final bottom = MediaQuery.paddingOf(context).bottom + 72;

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 12, 8),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: AppColors.gradientAccent,
                    ),
                    child: const Icon(Icons.auto_awesome,
                        size: 18, color: Colors.black87),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('chat.title'.tr(),
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                        Text(
                          chat.sending ? 'Thinking…' : 'Ready',
                          style: TextStyle(
                            fontSize: 12,
                            color: chat.sending
                                ? AppColors.accent
                                : AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => ref.read(chatProvider.notifier).clear(),
                    icon: const Icon(Icons.delete_outline_rounded),
                  ),
                  IconButton(
                    onPressed: () => context.push('/voice/listening',
                        extra: {'accent': AppColors.accent}),
                    icon: const Icon(Icons.mic_none_rounded),
                  ),
                ],
              ),
            ),
            Expanded(
              child: chat.messages.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'chat.empty'.tr(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: AppColors.textSecondary, height: 1.4),
                            ),
                            const SizedBox(height: 20),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              alignment: WrapAlignment.center,
                              children: [
                                for (final p in [
                                  'Will it rain tomorrow?',
                                  'Temperature today',
                                  'UV index?',
                                ])
                                  ActionChip(
                                    label: Text(p),
                                    onPressed: () =>
                                        ref.read(chatProvider.notifier).send(p),
                                    backgroundColor: AppColors.surfaceCard,
                                    side: const BorderSide(
                                        color: AppColors.borderSubtle),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(16, 8, 16, bottom),
                      itemCount:
                          chat.messages.length + (chat.sending ? 1 : 0),
                      itemBuilder: (_, i) {
                        if (chat.sending && i == chat.messages.length) {
                          return const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text('…',
                                style: TextStyle(color: AppColors.accent)),
                          );
                        }
                        final m = chat.messages[i];
                        final user = m.role == 'user';
                        return Align(
                          alignment: user
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Column(
                            crossAxisAlignment: user
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: const EdgeInsets.symmetric(vertical: 5),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 12),
                                constraints: BoxConstraints(
                                  maxWidth:
                                      MediaQuery.sizeOf(context).width * 0.82,
                                ),
                                decoration: BoxDecoration(
                                  color: user
                                      ? AppColors.accent.withValues(alpha: 0.18)
                                      : AppColors.surfaceCard,
                                  borderRadius: BorderRadius.only(
                                    topLeft: const Radius.circular(18),
                                    topRight: const Radius.circular(18),
                                    bottomLeft: Radius.circular(user ? 18 : 6),
                                    bottomRight: Radius.circular(user ? 6 : 18),
                                  ),
                                  border: Border.all(
                                    color: user
                                        ? AppColors.accent.withValues(alpha: 0.35)
                                        : AppColors.borderSubtle,
                                  ),
                                ),
                                child: user
                                    ? Text(m.content,
                                        style: const TextStyle(height: 1.35))
                                    : MarkdownBody(
                                        data: m.content
                                            .replaceAll(
                                                RegExp(r'```widget:[\s\S]*?```'),
                                                '')
                                            .trim(),
                                        styleSheet: MarkdownStyleSheet(
                                          p: const TextStyle(
                                              fontSize: 15, height: 1.4),
                                        ),
                                      ),
                              ),
                              if (!user && m.meta?['intent_engine'] == 'system-one')
                                Padding(
                                  padding: const EdgeInsets.only(left: 8, bottom: 4),
                                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                                    const Icon(Icons.bolt_rounded,
                                        size: 12, color: AppColors.textTertiary),
                                    const SizedBox(width: 3),
                                    Builder(builder: (_) {
                                      final confidence =
                                          m.meta?['intent_confidence'];
                                      final pct = confidence is num
                                          ? ' · ${(confidence.toDouble() * 100).round()}%'
                                          : '';
                                      return Text('Routed by System One$pct',
                                          style: const TextStyle(
                                              fontSize: 10.5,
                                              color: AppColors.textTertiary));
                                    }),
                                  ]),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(14, 0, 14, bottom - 48),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'chat.hint'.tr(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Material(
                    color: AppColors.accent,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: chat.sending ? null : _send,
                      child: const SizedBox(
                        width: 48,
                        height: 48,
                        child: Icon(Icons.arrow_upward_rounded,
                            color: Colors.black87),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
