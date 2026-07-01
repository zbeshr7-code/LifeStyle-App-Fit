import 'package:soccer_sys/modules/calls/logging/call_flow_logger.dart';

import 'package:soccer_sys/modules/calls/models/call_log_payload.dart';



/// Holds a call invite from FCM until [CallController] can show the incoming UI.

abstract final class IncomingCallCoordinator {

  static PendingCallInvite? _pending;



  static void setPending(PendingCallInvite invite) {

    _pending = invite;

    CallFlowLogger.info(

      'coordinator setPending',

      context: {

        'callId': invite.callId,

        'roomId': invite.roomId,

        'callerId': invite.callerId,

      },

    );

  }



  static PendingCallInvite? peek() => _pending;



  static PendingCallInvite? takeForRoom(String roomId) {

    final invite = _pending;

    if (invite == null || invite.roomId != roomId) {

      CallFlowLogger.trace(

        'coordinator takeForRoom: none',

        context: {'roomId': roomId, 'hasPending': invite != null},

      );

      return null;

    }

    _pending = null;

    CallFlowLogger.info(

      'coordinator takeForRoom',

      context: {'roomId': roomId, 'callId': invite.callId},

    );

    return invite;

  }



  static void clear() {

    CallFlowLogger.trace('coordinator clear');

    _pending = null;

  }

}


