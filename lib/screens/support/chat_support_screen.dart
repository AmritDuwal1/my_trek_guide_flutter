import 'dart:async';

import 'package:flutter/material.dart';
import 'package:tour_mobile/services/support_chat_service.dart';
import 'package:tour_mobile/theme/travel_theme.dart';

class ChatSupportScreen extends StatefulWidget {
  const ChatSupportScreen({super.key});

  @override
  State<ChatSupportScreen> createState() => _ChatSupportScreenState();
}

class _ChatSupportScreenState extends State<ChatSupportScreen> {
  final _svc = SupportChatService();
  final _composer = TextEditingController();
  final _scroll = ScrollController();

  Timer? _poll;
  bool _busy = true;
  bool _sending = false;
  String? _error;
  final List<SupportChatMessage> _messages = [];

  int? get _lastMs => _messages.isEmpty ? null : _messages.last.createdAtMs;

  @override
  void initState() {
    super.initState();
    _load(initial: true);
    _poll = Timer.periodic(const Duration(seconds: 4), (_) => _load());
  }

  @override
  void dispose() {
    _poll?.cancel();
    _composer.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _load({bool initial = false}) async {
    if (initial) setState(() => _busy = true);
    try {
      final newMsgs = await _svc.listMessages(sinceMs: initial ? null : _lastMs);
      if (!mounted) return;
      if (newMsgs.isNotEmpty) {
        setState(() {
          _error = null;
          _messages.addAll(newMsgs);
        });
        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (mounted && _scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent + 200,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
          );
        }
      } else if (initial) {
        setState(() => _error = null);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted && initial) setState(() => _busy = false);
    }
  }

  Future<void> _send() async {
    final text = _composer.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final msg = await _svc.sendMessage(text);
      if (!mounted) return;
      setState(() {
        _messages.add(msg);
        _composer.clear();
        _error = null;
      });
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (mounted && _scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 200,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TravelColors.canvas,
      appBar: AppBar(title: const Text('Chat support')),
      body: Column(
        children: [
          if (_error != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Text(_error!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.red.shade700)),
            ),
          Expanded(
            child: _busy
                ? const Center(child: CircularProgressIndicator(color: TravelColors.navActive))
                : ListView.builder(
                    controller: _scroll,
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, i) {
                      if (i == 0) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Text(
                            'Send a message — support replies will appear here (polling).',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: TravelColors.muted),
                          ),
                        );
                      }
                      final m = _messages[i - 1];
                      final isUser = m.sender == 'user';
                      return Align(
                        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          constraints: const BoxConstraints(maxWidth: 320),
                          decoration: BoxDecoration(
                            color: isUser ? TravelColors.navActive : TravelColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: isUser ? null : Border.all(color: TravelColors.line),
                          ),
                          child: Text(
                            m.text,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: isUser ? Colors.white : TravelColors.ink,
                                  height: 1.3,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _composer,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: InputDecoration(
                        hintText: 'Type a message…',
                        filled: true,
                        fillColor: TravelColors.surface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: TravelColors.line),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: TravelColors.line),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: _sending ? null : _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: TravelColors.navActive,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    child: _sending
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
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

