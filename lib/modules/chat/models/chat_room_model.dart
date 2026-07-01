import 'package:soccer_sys/modules/auth/models/user_model.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/calls/models/call_log_payload.dart';
import 'package:soccer_sys/modules/chat/models/message_type.dart';

class ChatRoomModel {
  const ChatRoomModel({
    required this.roomId,
    required this.peerId,
    required this.peerFirstName,
    required this.peerLastName,
    this.peerAvatarUrl,
    required this.peerRole,
    this.lastMessageType,
    this.lastMessageContent,
    this.lastMessageAt,
    required this.unreadCount,
  });

  final String roomId;
  final String peerId;
  final String peerFirstName;
  final String peerLastName;
  final String? peerAvatarUrl;
  final UserRole peerRole;
  final MessageType? lastMessageType;
  final String? lastMessageContent;
  final DateTime? lastMessageAt;
  final int unreadCount;

  String get peerFullName => '$peerFirstName $peerLastName'.trim();

  bool get hasUnread => unreadCount > 0;

  ChatRoomModel copyWith({
    String? roomId,
    String? peerId,
    String? peerFirstName,
    String? peerLastName,
    String? peerAvatarUrl,
    UserRole? peerRole,
    MessageType? lastMessageType,
    String? lastMessageContent,
    DateTime? lastMessageAt,
    int? unreadCount,
  }) {
    return ChatRoomModel(
      roomId: roomId ?? this.roomId,
      peerId: peerId ?? this.peerId,
      peerFirstName: peerFirstName ?? this.peerFirstName,
      peerLastName: peerLastName ?? this.peerLastName,
      peerAvatarUrl: peerAvatarUrl ?? this.peerAvatarUrl,
      peerRole: peerRole ?? this.peerRole,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageContent: lastMessageContent ?? this.lastMessageContent,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
    );
  }

  factory ChatRoomModel.fromJson(Map<String, dynamic> json) {
    return ChatRoomModel(
      roomId: json['room_id'] as String,
      peerId: json['peer_id'] as String,
      peerFirstName: json['peer_first_name'] as String? ?? '',
      peerLastName: json['peer_last_name'] as String? ?? '',
      peerAvatarUrl: json['peer_avatar_url'] as String?,
      peerRole: UserRole.fromString(json['peer_role'] as String),
      lastMessageType: json['last_message_type'] == null
          ? null
          : MessageType.fromString(json['last_message_type'] as String),
      lastMessageContent: json['last_message_content'] as String?,
      lastMessageAt: json['last_message_at'] == null
          ? null
          : DateTime.parse(json['last_message_at'] as String),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ChatPeerModel {
  const ChatPeerModel({
    required this.id,
    required this.firstName,
    required this.lastName,
    this.avatarUrl,
    required this.role,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String? avatarUrl;
  final UserRole role;

  String get fullName => '$firstName $lastName'.trim();

  factory ChatPeerModel.fromJson(Map<String, dynamic> json) {
    return ChatPeerModel(
      id: json['id'] as String,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      role: UserRole.fromString(json['role'] as String),
    );
  }

  factory ChatPeerModel.fromUser(UserModel user) {
    return ChatPeerModel(
      id: user.id,
      firstName: user.firstName,
      lastName: user.lastName,
      avatarUrl: user.avatarUrl,
      role: user.role,
    );
  }
}

class ChatRoomArgs {
  const ChatRoomArgs({
    required this.roomId,
    required this.peerId,
    required this.peerName,
    this.peerAvatarUrl,
    this.pendingCallInvite,
  });

  final String roomId;
  final String peerId;
  final String peerName;
  final String? peerAvatarUrl;
  final PendingCallInvite? pendingCallInvite;
}
