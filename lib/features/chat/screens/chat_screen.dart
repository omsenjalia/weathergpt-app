import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../conversation/widgets/conversation_chrome.dart';
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
    Future.delayed(const Duration(milliseconds: 120), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 120,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);

    ref.listen(chatProvider, (_, __) {
      Future.delayed(const Duration(milliseconds: 80), () {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent + 80,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: Stack(
        children: [
          const ConversationBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      const AiAvatar(size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'chat.title'.tr(),
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              chat.sending ? 'Typing…' : 'Online',
                              style: TextStyle(
                                fontSize: 11,
                                color: chat.sending
                                    ? AppColors.statusAmber
                                    : AppColors.statusGreenText,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Clear',
                        onPressed: () =>
                            ref.read(chatProvider.notifier).clear(),
                        icon: const Icon(Icons.delete_outline_rounded),
                      ),
                      IconButton(
                        onPressed: () => context.push('/voice/listening',
                            extra: {'accent': AppColors.statusAmber}),
                        icon: const Icon(Icons.mic_none_rounded),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: chat.messages.isEmpty
                      ? _EmptyState(
                          onPrompt: (p) {
                            ref.read(chatProvider.notifier).send(p);
                          },
                        )
                      : ListView.builder(
                          controller: _scroll,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          itemCount:
                              chat.messages.length + (chat.sending ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (chat.sending &&
                                index == chat.messages.length) {
                              return AiMessageShell(
                                child: Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.statusAmber
                                            .withValues(alpha: 0.9),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Text(
                                      'Thinking…',
                                      style: TextStyle(
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }
                            final msg = chat.messages[index];
                            if (msg.role == 'user') {
                              return UserBubble(text: msg.content);
                            }
                            final clean = msg.content
                                .replaceAll(
                                    RegExp(r'```widget:[\s\S]*?```'), '')
                                .replaceAll(
                                    RegExp(r'```json[\s\S]*?```'), '')
                                .trim();
                            return AiMessageShell(
                              child: MarkdownBody(
                                data: clean.isEmpty ? msg.content : clean,
                                styleSheet: MarkdownStyleSheet(
                                  p: const TextStyle(
                                    fontSize: 15,
                                    height: 1.45,
                                    color: AppColors.textPrimary,
                                  ),
                                  strong: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                ),
                _Composer(
                  controller: _controller,
                  sending: chat.sending,
                  onSend: _send,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onPrompt});
  final ValueChanged<String> onPrompt;

  static const _prompts = [
    'Will it rain tomorrow?',
    'Temperature in Ahmedabad',
    'Should I irrigate today?',
  ];

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const AiAvatar(size: 56),
            const SizedBox(height: 18),
            const Text(
              'Ask WeatherGPT',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'chat.empty'.tr(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: _prompts
                  .map(
                    (p) => ActionChip(
                      label: Text(p),
                      onPressed: () => onPrompt(p),
                      backgroundColor: AppColors.surfaceCard,
                      side: const BorderSide(color: AppColors.borderSubtle),
                      labelStyle: const TextStyle(fontSize: 12),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceCard,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.statusAmber.withValues(alpha: 0.25),
                ),
              ),
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => onSend(),
                decoration: InputDecoration(
                  hintText: 'chat.hint'.tr(),
                  hintStyle: const TextStyle(color: AppColors.textTertiary),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Material(
            color: AppColors.statusAmber,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: sending ? null : onSend,
              child: const SizedBox(
                width: 48,
                height: 48,
                child: Icon(Icons.arrow_upward_rounded, color: Colors.black87),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
