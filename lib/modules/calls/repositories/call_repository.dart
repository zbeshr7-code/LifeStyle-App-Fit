import 'package:soccer_sys/core/errors/failure.dart';

import 'package:soccer_sys/core/errors/failure_mapper.dart';

import 'package:soccer_sys/core/services/supabase_service.dart';

import 'package:soccer_sys/modules/calls/logging/call_flow_logger.dart';

import 'package:soccer_sys/modules/calls/models/call_models.dart';

import 'package:soccer_sys/modules/calls/services/call_signaling_service.dart';



class CallRepository {

  CallRepository(this._supabaseService, this._signalingService);



  final SupabaseService _supabaseService;

  final CallSignalingService _signalingService;



  String? get currentUserId => _supabaseService.client.auth.currentUser?.id;



  Future<({Failure? failure, AgoraTokenResponse? token})> fetchToken({

    required String roomId,

    required String channelName,

  }) async {

    CallFlowLogger.info(

      'fetchToken request',

      context: {'roomId': roomId, 'channelName': channelName},

    );

    try {

      final response = await _supabaseService.client.functions.invoke(

        'generate-agora-token',

        body: {

          'roomId': roomId,

          'channelName': channelName,

        },

      );



      final data = response.data;

      if (response.status != 200 || data is! Map<String, dynamic>) {

        final message = data is Map

            ? (data['error'] as String? ?? 'call_token_failed')

            : 'call_token_failed';

        CallFlowLogger.error(

          'fetchToken failed',

          context: {

            'status': response.status,

            'error': message,

            'dataType': data.runtimeType.toString(),

          },

        );

        return (failure: ServerFailure(message), token: null);

      }



      final token = AgoraTokenResponse.fromJson(data);

      CallFlowLogger.info(

        'fetchToken success',

        context: {

          'status': response.status,

          'channel': token.channelName,

          'userAccount': token.userAccount,

          'token': CallFlowLogger.tokenPreview(token.token),

        },

      );

      return (failure: null, token: token);

    } catch (error, stack) {

      CallFlowLogger.error(

        'fetchToken exception',

        error: error,

        stackTrace: stack,

        context: {'roomId': roomId, 'channelName': channelName},

      );

      return (failure: FailureMapper.fromException(error), token: null);

    }

  }



  Future<void> subscribeToSignals({

    required String roomId,

    required void Function(CallSignalPayload signal) onSignal,

  }) {

    CallFlowLogger.info('subscribeToSignals', context: {'roomId': roomId});

    return _signalingService.subscribe(

      roomId: roomId,

      onSignal: (payload) {

        onSignal(CallSignalPayload.fromJson(payload));

      },

    );

  }



  Future<void> sendSignal(CallSignalPayload signal) {

    CallFlowLogger.trace(

      'sendSignal',

      context: {

        'type': signal.type.value,

        'callId': signal.callId,

        'roomId': signal.roomId,

      },

    );

    return _signalingService.sendSignal(signal.toJson());

  }



  Future<void> unsubscribe() {

    CallFlowLogger.info('unsubscribe signals');

    return _signalingService.unsubscribe();

  }



  Future<void> sendCallInvitePush({

    required String recipientId,

    required String roomId,

    required String callerId,

    required String callerName,

    required String callId,

    required String callType,

  }) async {

    CallFlowLogger.info(

      'sendCallInvitePush',

      context: {

        'recipientId': recipientId,

        'roomId': roomId,

        'callId': callId,

        'callType': callType,

      },

    );

    try {

      final response = await _supabaseService.client.functions.invoke(

        'send-push-notification',

        body: {

          'type': 'call_invite',

          'recipientId': recipientId,

          'roomId': roomId,

          'callerId': callerId,

          'callerName': callerName,

          'callId': callId,

          'callType': callType,

        },

      );



      if (response.status != 200) {

        CallFlowLogger.warn(

          'sendCallInvitePush non-200',

          context: {

            'status': response.status,

            'data': response.data?.toString(),

          },

        );

        return;

      }



      final data = response.data;

      if (data is Map && data['delivered'] == false) {

        CallFlowLogger.warn(

          'sendCallInvitePush not delivered',

          context: {'reason': data['reason']},

        );

      } else {

        CallFlowLogger.info(

          'sendCallInvitePush ok',

          context: {'status': response.status, 'data': data?.toString()},

        );

      }

    } catch (error, stack) {

      CallFlowLogger.error(

        'sendCallInvitePush exception',

        error: error,

        stackTrace: stack,

      );

    }

  }

}


