enum CallType {
  audio,
  video;

  bool get isVideo => this == CallType.video;

  String get value => name;

  static CallType fromString(String value) => switch (value) {
        'video' => CallType.video,
        _ => CallType.audio,
      };
}

enum CallPhase {
  idle,
  outgoing,
  incoming,
  connecting,
  inCall,
  ended,
}

enum CallSignalType {
  invite,
  accept,
  reject,
  busy,
  end;

  String get value => name;

  static CallSignalType? fromString(String? value) => switch (value) {
        'invite' => CallSignalType.invite,
        'accept' => CallSignalType.accept,
        'reject' => CallSignalType.reject,
        'busy' => CallSignalType.busy,
        'end' => CallSignalType.end,
        _ => null,
      };
}

class CallArgs {
  const CallArgs({
    required this.roomId,
    required this.peerId,
    required this.peerName,
    this.peerAvatarUrl,
    this.initialType,
    this.incomingCallId,
    this.incomingType,
  });

  final String roomId;
  final String peerId;
  final String peerName;
  final String? peerAvatarUrl;
  final CallType? initialType;
  final String? incomingCallId;
  final CallType? incomingType;

  bool get isIncoming => incomingCallId != null;
}

class AgoraTokenResponse {
  const AgoraTokenResponse({
    required this.token,
    required this.channelName,
    required this.userAccount,
    required this.appId,
    required this.expiresAt,
  });

  final String token;
  final String channelName;
  final String userAccount;
  final String appId;
  final DateTime expiresAt;

  factory AgoraTokenResponse.fromJson(Map<String, dynamic> json) {
    return AgoraTokenResponse(
      token: json['token'] as String,
      channelName: json['channelName'] as String,
      userAccount: json['userAccount'] as String,
      appId: json['appId'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
    );
  }
}

class CallSignalPayload {
  const CallSignalPayload({
    required this.type,
    required this.callId,
    required this.roomId,
    required this.userId,
    this.callerId,
    this.callerName,
    this.callType,
  });

  final CallSignalType type;
  final String callId;
  final String roomId;
  final String userId;
  final String? callerId;
  final String? callerName;
  final CallType? callType;

  Map<String, dynamic> toJson() => {
        'type': type.value,
        'callId': callId,
        'roomId': roomId,
        'userId': userId,
        if (callerId != null) 'callerId': callerId,
        if (callerName != null) 'callerName': callerName,
        if (callType != null) 'callType': callType!.value,
      };

  factory CallSignalPayload.fromJson(Map<String, dynamic> json) {
    return CallSignalPayload(
      type: CallSignalType.fromString(json['type'] as String?) ??
          CallSignalType.end,
      callId: json['callId'] as String? ?? '',
      roomId: json['roomId'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      callerId: json['callerId'] as String?,
      callerName: json['callerName'] as String?,
      callType: json['callType'] == null
          ? null
          : CallType.fromString(json['callType'] as String),
    );
  }
}
