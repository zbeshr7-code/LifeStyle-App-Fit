import 'dart:convert';

import 'package:soccer_sys/modules/calls/models/call_models.dart';

enum CallLogEvent {
  ended,
  missed,
  declined,
  noAnswer,
  cancelled;

  String get value => name;

  static CallLogEvent fromString(String value) {
    return CallLogEvent.values.firstWhere(
      (e) => e.name == value,
      orElse: () => CallLogEvent.ended,
    );
  }
}

class CallLogPayload {
  const CallLogPayload({
    required this.event,
    required this.callType,
    this.durationSeconds = 0,
  });

  final CallLogEvent event;
  final CallType callType;
  final int durationSeconds;

  String toJsonString() => jsonEncode({
        'event': event.value,
        'callType': callType.name,
        'durationSeconds': durationSeconds,
      });

  static CallLogPayload? tryParse(String? content) {
    if (content == null || content.trim().isEmpty) return null;
    try {
      final map = jsonDecode(content) as Map<String, dynamic>;
      return CallLogPayload(
        event: CallLogEvent.fromString(map['event'] as String? ?? 'ended'),
        callType: CallType.values.firstWhere(
          (t) => t.name == (map['callType'] as String? ?? 'audio'),
          orElse: () => CallType.audio,
        ),
        durationSeconds: (map['durationSeconds'] as num?)?.toInt() ?? 0,
      );
    } catch (_) {
      return null;
    }
  }
}

class PendingCallInvite {
  const PendingCallInvite({
    required this.callId,
    required this.roomId,
    required this.callerId,
    required this.callerName,
    required this.callType,
    this.callerAvatarUrl,
  });

  final String callId;
  final String roomId;
  final String callerId;
  final String callerName;
  final CallType callType;
  final String? callerAvatarUrl;

  factory PendingCallInvite.fromPushData(Map<String, dynamic> data) {
    final callTypeRaw = data['call_type'] as String? ?? 'audio';
    return PendingCallInvite(
      callId: data['call_id'] as String? ?? '',
      roomId: data['room_id'] as String? ?? '',
      callerId: data['peer_id'] as String? ?? '',
      callerName: data['peer_name'] as String? ?? 'Incoming call',
      callType: callTypeRaw == 'video' ? CallType.video : CallType.audio,
      callerAvatarUrl: data['peer_avatar_url'] as String?,
    );
  }
}
