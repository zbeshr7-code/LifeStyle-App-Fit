import 'package:soccer_sys/core/services/supabase_service.dart';
import 'package:soccer_sys/modules/chat/models/message_type.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatService {
  ChatService(this._supabaseService);

  final SupabaseService _supabaseService;

  SupabaseClient get _client => _supabaseService.client;

  String? get currentUserId => _client.auth.currentUser?.id;

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final result = await _client.rpc('get_chat_rooms_for_user');
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<void> updateLastSeen() async {
    await touchLastSeen();
  }

  Future<void> touchLastSeen() async {
    final userId = currentUserId;
    if (userId == null) return;
    try {
      await _client.rpc('touch_last_seen');
    } catch (_) {
      await _client.from('profiles').update({
        'last_seen_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', userId);
    }
  }

  Future<DateTime?> fetchPeerLastSeen(String peerId) async {
    final result = await _client
        .from('profiles')
        .select('last_seen_at')
        .eq('id', peerId)
        .maybeSingle();
    if (result == null || result['last_seen_at'] == null) return null;
    return DateTime.parse(result['last_seen_at'] as String);
  }

  Future<DateTime?> fetchPeerLastReadAt({
    required String roomId,
    required String peerId,
  }) async {
    final result = await _client
        .from('chat_room_members')
        .select('last_read_at')
        .eq('room_id', roomId)
        .eq('user_id', peerId)
        .maybeSingle();
    if (result == null || result['last_read_at'] == null) return null;
    return DateTime.parse(result['last_read_at'] as String);
  }

  Future<String> getOrCreateDirectRoom(String peerId) async {
    final result = await _client.rpc(
      'get_or_create_direct_room',
      params: {'p_peer_id': peerId},
    );
    return result as String;
  }

  Future<void> markRoomAsRead(String roomId) async {
    await _client.rpc('mark_chat_room_read', params: {'p_room_id': roomId});
  }

  Future<List<Map<String, dynamic>>> fetchMessages(String roomId) async {
    final result = await _client
        .from('chat_messages')
        .select()
        .eq('room_id', roomId)
        .order('created_at', ascending: true);
    return List<Map<String, dynamic>>.from(result as List);
  }

  Future<Map<String, dynamic>> sendMessage({
    required String roomId,
    required String senderId,
    required MessageType type,
    String? content,
    String? mediaUrl,
    String? fileName,
    int? fileSize,
    int? audioDurationMs,
  }) async {
    final result = await _client
        .from('chat_messages')
        .insert({
          'room_id': roomId,
          'sender_id': senderId,
          'type': type.value,
          'content': content,
          'media_url': mediaUrl,
          'file_name': fileName,
          'file_size': fileSize,
          'audio_duration_ms': audioDurationMs,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(result);
  }

  Future<List<Map<String, dynamic>>> fetchPeersByRole(String role) async {
    final result = await _client
        .from('profiles')
        .select('id, first_name, last_name, avatar_url, role')
        .eq('role', role)
        .eq('is_active', true)
        .order('first_name');
    return List<Map<String, dynamic>>.from(result as List);
  }

  RealtimeChannel subscribeToRoomMessages(
    String roomId,
    void Function(Map<String, dynamic> payload) onInsert,
  ) {
    return _client
        .channel('room:$roomId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'room_id',
            value: roomId,
          ),
          callback: (payload) {
            if (payload.newRecord.isNotEmpty) {
              onInsert(Map<String, dynamic>.from(payload.newRecord));
            }
          },
        )
        .subscribe();
  }

  RealtimeChannel subscribeToAllMessages(
    void Function() onChange,
  ) {
    return _client
        .channel('chat_rooms_list')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (_) => onChange(),
        )
        .subscribe();
  }

  RealtimeChannel subscribeToPeerPresence(
    String peerId,
    void Function(DateTime? lastSeen) onUpdate,
  ) {
    return _client
        .channel('presence:$peerId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'profiles',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: peerId,
          ),
          callback: (payload) {
            final raw = payload.newRecord['last_seen_at'];
            if (raw == null) {
              onUpdate(null);
              return;
            }
            onUpdate(DateTime.parse(raw as String));
          },
        )
        .subscribe();
  }

  Future<void> removeChannel(RealtimeChannel channel) async {
    await _client.removeChannel(channel);
  }
}
