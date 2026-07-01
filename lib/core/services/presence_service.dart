import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/modules/chat/services/chat_service.dart';

/// Keeps the signed-in user's `last_seen_at` fresh while the app is active.
class PresenceService extends GetxService with WidgetsBindingObserver {
  PresenceService(this._chatService);

  final ChatService _chatService;
  Timer? _heartbeat;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
    touch();
    _heartbeat = Timer.periodic(const Duration(seconds: 30), (_) => touch());
  }

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    _heartbeat?.cancel();
    super.onClose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      touch();
    }
  }

  Future<void> touch() async {
    if (_chatService.currentUserId == null) return;
    try {
      await _chatService.touchLastSeen();
    } catch (_) {}
  }
}
