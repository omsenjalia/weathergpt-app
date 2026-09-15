import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/markdown_utils.dart';
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
    final text = _controller.text;
    _controller.clear();
    ref.read(chatProvider.notifier).send(text);
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 80,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chat = ref.watch(chatProvider);
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: Text('chat.title'.tr()),
        actions: [
          IconButton(
            tooltip: 'Clear',
            onPressed: () => ref.read(chatProvider.notifier).clear(),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            onPressed: () => context.push('/voice/listening', extra: {
              'accent': AppColors.statusAmber,
            }),
            icon: const Icon(Icons.mic_none_rounded),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.chat_bubble_outline,
                              size: 40, color: AppColors.textTertiary),
                          SizedBox(height: 12),
                          Text(
                            'Ask about weather, forecasts, AQI, or farming tips.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: chat.messages.length + (chat.sending ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (chat.sending && i == chat.messages.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: _Bubble(
                              isUser: false,
                              child: Text('Thinking…',
                                  style: TextStyle(
                                      color: AppColors.textSecondary)),
                            ),
                          ),
                        );
                      }
                      final m = chat.messages[i];
                      final isUser = m.role == 'user';
                      return Align(
                        alignment: isUser
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: _Bubble(
                          isUser: isUser,
                          child: isUser
                              ? Text(m.content)
                              : MarkdownBody(
                                  data: MarkdownUtils.forSpeech(m.content)
                                          .isEmpty
                                      ? m.content
                                      : m.content
                                          .replaceAll(
                                              RegExp(r'```widget:[\s\S]*?```'),
                                              '')
                                          .replaceAll(
                                              RegExp(r'widget:\w+\s*\{[\s\S]*?\}'),
                                              ''),
                                  styleSheet: MarkdownStyleSheet(
                                    p: const TextStyle(
                                        fontSize: 14, height: 1.4),
                                    strong: const TextStyle(
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
          ),
          if (chat.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(chat.error!,
                  style: const TextStyle(color: AppColors.statusAmber)),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      minLines: 1,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'chat.hint'.tr(),
                        filled: true,
                        fillColor: AppColors.surfaceCardAlt,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: AppColors.borderSubtle),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide:
                              const BorderSide(color: AppColors.borderSubtle),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: chat.sending ? null : _send,
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.ctaWhite,
                      foregroundColor: AppColors.ctaTextDark,
                    ),
                    icon: const Icon(Icons.send_rounded),
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

class _Bubble extends StatelessWidget {
  const _Bubble({required this.isUser, required this.child});
  final bool isUser;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width * 0.82,
      ),
      decoration: BoxDecoration(
        color: isUser ? AppColors.surfaceCardAlt : AppColors.surfaceCard,
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(16),
          topRight: const Radius.circular(16),
          bottomLeft: Radius.circular(isUser ? 16 : 4),
          bottomRight: Radius.circular(isUser ? 4 : 16),
        ),
        border: Border.all(color: AppColors.borderSubtle),
      ),
      child: child,
    );
  }
}
