import 'package:soccer_sys/core/services/supabase_service.dart';

import 'package:soccer_sys/modules/calls/logging/call_flow_logger.dart';

import 'package:supabase_flutter/supabase_flutter.dart';



class CallSignalingService {

  CallSignalingService(this._supabaseService);



  final SupabaseService _supabaseService;



  RealtimeChannel? _channel;

  String? _roomId;



  SupabaseClient get _client => _supabaseService.client;



  Future<void> subscribe({

    required String roomId,

    required void Function(Map<String, dynamic> payload) onSignal,

  }) async {

    if (_roomId == roomId && _channel != null) {

      CallFlowLogger.trace(

        'signaling already subscribed',

        context: {'roomId': roomId},

      );

      return;

    }



    await unsubscribe();



    _roomId = roomId;

    final channelName = 'call:$roomId';

    CallFlowLogger.info(

      'signaling subscribe',

      context: {'channel': channelName},

    );



    _channel = _client

        .channel(channelName)

        .onBroadcast(

          event: 'call_signal',

          callback: (payload) {

            final data = payload;

            if (data.isEmpty) {

              CallFlowLogger.trace('signaling empty payload');

              return;

            }

            CallFlowLogger.trace(

              'signaling broadcast received',

              context: {'keys': data.keys.join(',')},

            );

            onSignal(Map<String, dynamic>.from(data));

          },

        )

        .subscribe((status, [error]) {

          if (error != null) {

            CallFlowLogger.error(

              'signaling subscribe error',

              error: error,

              context: {'status': status.name, 'roomId': roomId},

            );

          } else {

            CallFlowLogger.info(

              'signaling channel status',

              context: {'status': status.name, 'roomId': roomId},

            );

          }

        });

  }



  Future<void> sendSignal(Map<String, dynamic> payload) async {

    final channel = _channel;

    if (channel == null) {

      CallFlowLogger.warn(

        'sendSignal skipped: no channel',

        context: {'type': payload['type'], 'callId': payload['callId']},

      );

      return;

    }



    try {

      await channel.sendBroadcastMessage(

        event: 'call_signal',

        payload: payload,

      );

      CallFlowLogger.trace(

        'sendSignal ok',

        context: {'type': payload['type'], 'callId': payload['callId']},

      );

    } catch (error, stack) {

      CallFlowLogger.error(

        'sendSignal failed',

        error: error,

        stackTrace: stack,

        context: payload.map((k, v) => MapEntry(k, v?.toString() ?? '')),

      );

    }

  }



  Future<void> unsubscribe() async {

    final channel = _channel;

    final roomId = _roomId;

    _channel = null;

    _roomId = null;

    if (channel != null) {

      CallFlowLogger.info('signaling unsubscribe', context: {'roomId': roomId});

      await _client.removeChannel(channel);

    }

  }

}


