import 'package:get/get.dart';

import 'package:soccer_sys/core/routes/app_routes.dart';

import 'package:soccer_sys/modules/calls/logging/call_flow_logger.dart';

import 'package:soccer_sys/modules/calls/models/call_log_payload.dart';

import 'package:soccer_sys/modules/calls/services/incoming_call_coordinator.dart';

import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';



abstract final class PushNavigationHandler {

  static void handle(Map<String, dynamic> data) {

    final type = data['type'] as String? ?? '';

    CallFlowLogger.trace(

      'push handle',

      context: {'type': type, 'keys': data.keys.join(',')},

    );



    switch (type) {

      case 'chat_message':

        _openChatRoom(data);

      case 'call_invite':

        _handleCallInvite(data);

      default:

        CallFlowLogger.trace('push ignored type', context: {'type': type});

    }

  }



  static void _handleCallInvite(Map<String, dynamic> data) {

    final invite = PendingCallInvite.fromPushData(data);

    if (invite.callId.isEmpty || invite.roomId.isEmpty) {

      CallFlowLogger.warn(

        'call_invite push invalid',

        context: data.map((k, v) => MapEntry(k, v?.toString() ?? '')),

      );

      return;

    }



    CallFlowLogger.info(

      'call_invite push',

      context: {

        'callId': invite.callId,

        'roomId': invite.roomId,

        'callerId': invite.callerId,

        'route': Get.currentRoute,

      },

    );



    IncomingCallCoordinator.setPending(invite);



    if (Get.currentRoute == AppRoutes.callActive) {

      CallFlowLogger.trace('call_invite skipped: already on call screen');

      return;

    }



    _openChatRoom(

      data,

      pendingCallInvite: invite,

      forceNavigate: true,

    );

  }



  static void _openChatRoom(

    Map<String, dynamic> data, {

    PendingCallInvite? pendingCallInvite,

    bool forceNavigate = false,

  }) {

    final roomId = data['room_id'] as String?;

    final peerId = data['peer_id'] as String?;

    final peerName = data['peer_name'] as String?;



    if (roomId == null || peerId == null || peerName == null) {

      CallFlowLogger.warn(

        'openChatRoom missing fields',

        context: {

          'roomId': roomId,

          'peerId': peerId,

          'peerName': peerName,

        },

      );

      return;

    }



    final args = ChatRoomArgs(

      roomId: roomId,

      peerId: peerId,

      peerName: peerName,

      peerAvatarUrl: data['peer_avatar_url'] as String?,

      pendingCallInvite: pendingCallInvite,

    );



    if (!forceNavigate && Get.currentRoute == AppRoutes.chatRoom) {

      final current = Get.arguments;

      if (current is ChatRoomArgs && current.roomId == roomId) {

        CallFlowLogger.trace('openChatRoom: same room, coordinator only');

        return;

      }

    }



    final action =

        Get.currentRoute == AppRoutes.chatRoom ? 'offNamed' : 'toNamed';

    CallFlowLogger.info(

      'openChatRoom navigate',

      context: {

        'action': action,

        'roomId': roomId,

        'hasPendingInvite': pendingCallInvite != null,

        'fromRoute': Get.currentRoute,

      },

    );



    if (Get.currentRoute == AppRoutes.chatRoom) {

      Get.offNamed(AppRoutes.chatRoom, arguments: args);

    } else {

      Get.toNamed(AppRoutes.chatRoom, arguments: args);

    }

  }

}


