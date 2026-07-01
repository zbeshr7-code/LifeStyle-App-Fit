import 'dart:async';
import 'dart:io';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:soccer_sys/core/config/env_config.dart';
import 'package:soccer_sys/core/routes/app_routes.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/calls/logging/call_flow_logger.dart';
import 'package:soccer_sys/modules/calls/models/call_log_payload.dart';
import 'package:soccer_sys/modules/calls/models/call_models.dart';
import 'package:soccer_sys/modules/calls/repositories/call_repository.dart';
import 'package:soccer_sys/modules/calls/services/agora_call_service.dart';
import 'package:soccer_sys/modules/calls/services/call_ringtone_service.dart';
import 'package:soccer_sys/modules/calls/services/incoming_call_coordinator.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/chat/repositories/chat_repository.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

class CallController extends GetxController {
  CallController(
    this._repository,
    this._agoraService,
    this._ringtoneService,
    this._authController,
    this.roomArgs,
  );

  final CallRepository _repository;
  final AgoraCallService _agoraService;
  final CallRingtoneService _ringtoneService;
  final AuthController _authController;
  final ChatRoomArgs roomArgs;

  AgoraCallService get agoraService => _agoraService;

  String? get activeChannelName => _channelName;

  final phase = CallPhase.idle.obs;
  final callType = CallType.audio.obs;
  final errorMessage = ''.obs;
  final isMuted = false.obs;
  final isSpeakerOn = false.obs;
  final isVideoEnabled = true.obs;
  final remoteUid = Rxn<int>(null);
  final callDuration = Duration.zero.obs;

  String? _callId;
  String? _channelName;
  String? _appId;
  DateTime? _connectedAt;
  bool _callLogPosted = false;
  Timer? _durationTimer;
  Timer? _ringingTimer;
  Timer? _remoteOfflineTimer;
  bool _isNavigating = false;
  bool _isJoiningChannel = false;

  String? get currentUserId => _repository.currentUserId;

  String get peerName => roomArgs.peerName;

  String? get peerAvatarUrl => roomArgs.peerAvatarUrl;

  bool get isInCallScreen =>
      phase.value == CallPhase.outgoing ||
      phase.value == CallPhase.incoming ||
      phase.value == CallPhase.connecting ||
      phase.value == CallPhase.inCall;

  @override
  void onInit() {
    super.onInit();
    CallFlowLogger.info(
      'CallController.onInit',
      context: _ctx(peer: roomArgs.peerId),
    );
    _repository.subscribeToSignals(
      roomId: roomArgs.roomId,
      onSignal: _handleSignal,
    );
  }

  @override
  void onReady() {
    super.onReady();
    CallFlowLogger.trace('CallController.onReady', context: _ctx());
    _presentPendingInviteIfAny();
  }

  @override
  void onClose() {
    CallFlowLogger.info('CallController.onClose', context: _ctx());
    _ringingTimer?.cancel();
    _remoteOfflineTimer?.cancel();
    _durationTimer?.cancel();
    unawaited(_ringtoneService.stopRinging());
    _repository.unsubscribe();
    _cleanupCall();
    super.onClose();
  }

  Future<void> startOutgoingCall(CallType type) async {
    CallFlowLogger.info(
      'startOutgoingCall',
      context: _ctx(type: type.name),
    );

    if (!_isMobilePlatform) {
      CallFlowLogger.warn('startOutgoingCall blocked: not mobile');
      _showError('call_mobile_only');
      return;
    }

    if (phase.value != CallPhase.idle && phase.value != CallPhase.ended) {
      CallFlowLogger.warn(
        'startOutgoingCall blocked: already in call',
        context: _ctx(),
      );
      _showError('call_busy');
      return;
    }

    if (!await _ensurePermissions(type)) return;

    final appId = EnvConfig.agoraAppId.trim();
    if (appId.isEmpty) {
      CallFlowLogger.error('startOutgoingCall: AGORA_APP_ID missing');
      _showError('call_agora_not_configured');
      return;
    }

    _callId = _newCallId();
    _channelName = '${roomArgs.roomId}_$_callId';
    _callLogPosted = false;
    callType.value = type;
    _setPhase(CallPhase.outgoing, reason: 'outgoing_started');
    errorMessage.value = '';

    CallFlowLogger.info(
      'outgoing call created',
      context: _ctx(appIdConfigured: appId.isNotEmpty),
    );

    await _repository.sendSignal(
      CallSignalPayload(
        type: CallSignalType.invite,
        callId: _callId!,
        roomId: roomArgs.roomId,
        userId: currentUserId!,
        callerId: currentUserId,
        callerName: _callerDisplayName,
        callType: type,
      ),
    );

    unawaited(
      _repository.sendCallInvitePush(
        recipientId: roomArgs.peerId,
        roomId: roomArgs.roomId,
        callerId: currentUserId!,
        callerName: _callerDisplayName,
        callId: _callId!,
        callType: type.name,
      ),
    );

    _openCallScreen();
    _startCallRingtone();
    _startRingingTimeout();
  }

  Future<void> acceptIncomingCall() async {
    CallFlowLogger.info('acceptIncomingCall', context: _ctx());
    if (_callId == null || phase.value != CallPhase.incoming) {
      CallFlowLogger.warn(
        'acceptIncomingCall ignored',
        context: _ctx(),
      );
      return;
    }
    if (!await _ensurePermissions(callType.value)) return;

    _ringingTimer?.cancel();
    unawaited(_ringtoneService.stopRinging());
    _setPhase(CallPhase.connecting, reason: 'callee_accepted');

    await _repository.sendSignal(
      CallSignalPayload(
        type: CallSignalType.accept,
        callId: _callId!,
        roomId: roomArgs.roomId,
        userId: currentUserId!,
      ),
    );

    await _joinAgoraChannel();
  }

  Future<void> rejectIncomingCall({CallLogEvent logEvent = CallLogEvent.declined}) async {
    CallFlowLogger.info(
      'rejectIncomingCall',
      context: _ctx(logEvent: logEvent.name),
    );
    if (_callId == null) {
      _resetToIdle(reason: 'reject_without_call_id');
      return;
    }

    await _repository.sendSignal(
      CallSignalPayload(
        type: CallSignalType.reject,
        callId: _callId!,
        roomId: roomArgs.roomId,
        userId: currentUserId!,
      ),
    );

    try {
      await _postCallLog(logEvent);
    } finally {
      _resetToIdle(closeScreen: true, reason: 'reject');
    }
  }

  Future<void> cancelOutgoingCall() async {
    CallFlowLogger.info('cancelOutgoingCall', context: _ctx());
    await endCall(sendSignal: true);
  }

  Future<void> endCall({bool sendSignal = true, CallLogEvent? logEvent}) async {
    final durationSeconds = _snapshotDurationSeconds();
    final signalType = _hangupSignalType();
    CallFlowLogger.info(
      'endCall',
      context: _ctx(
        sendSignal: sendSignal,
        logEvent: logEvent?.name,
        durationSec: durationSeconds,
        hangupSignal: signalType.value,
      ),
    );

    if (_callId != null && sendSignal) {
      await _sendHangupSignal(signalType);
    }

    final event = logEvent ??
        (durationSeconds > 0
            ? CallLogEvent.ended
            : signalType == CallSignalType.reject
                ? CallLogEvent.declined
                : CallLogEvent.cancelled);

    try {
      await _postCallLog(
        event,
        durationSeconds: event == CallLogEvent.ended ? durationSeconds : 0,
      );
    } finally {
      _resetToIdle(closeScreen: true, reason: 'endCall');
    }
  }

  Future<void> toggleMute() async {
    isMuted.value = !isMuted.value;
    await _agoraService.setMuted(isMuted.value);
  }

  Future<void> toggleSpeaker() async {
    isSpeakerOn.value = !isSpeakerOn.value;
    await _agoraService.setSpeakerphone(isSpeakerOn.value);
  }

  Future<void> toggleVideo() async {
    isVideoEnabled.value = !isVideoEnabled.value;
    await _agoraService.setVideoEnabled(isVideoEnabled.value);
  }

  Future<void> switchCamera() async {
    await _agoraService.switchCamera();
  }

  void handleCallScreenClosed() {
    CallFlowLogger.info(
      'handleCallScreenClosed',
      context: _ctx(route: Get.currentRoute),
    );
    switch (phase.value) {
      case CallPhase.incoming:
        rejectIncomingCall();
      case CallPhase.outgoing:
        cancelOutgoingCall();
      case CallPhase.connecting:
        if (_connectedAt == null) {
          unawaited(
            endCall(
              sendSignal: true,
              logEvent: CallLogEvent.cancelled,
            ),
          );
        } else {
          endCall();
        }
      case CallPhase.inCall:
        endCall();
      case CallPhase.idle:
      case CallPhase.ended:
        leaveCallScreen();
    }
  }

  /// Closes the call UI and returns to chat (safe when already idle).
  void leaveCallScreen() {
    if (Get.currentRoute != AppRoutes.callActive) return;

    if (Get.isOverlaysOpen) {
      Get.back();
    }

    final navigator = Get.key.currentState;
    if (navigator != null && navigator.canPop()) {
      navigator.pop();
      return;
    }

    if (Get.currentRoute == AppRoutes.callActive) {
      Get.until((route) => route.settings.name != AppRoutes.callActive);
    }
  }

  Future<void> _handleSignal(CallSignalPayload signal) async {
    if (signal.roomId != roomArgs.roomId) {
      CallFlowLogger.trace(
        'signal ignored: wrong room',
        context: {
          'signalRoom': signal.roomId,
          'expectedRoom': roomArgs.roomId,
          'type': signal.type.value,
        },
      );
      return;
    }
    if (signal.userId == currentUserId) return;

    CallFlowLogger.info(
      'signal received',
      context: {
        'type': signal.type.value,
        'callId': signal.callId,
        'from': signal.userId,
        ..._ctx(),
      },
    );

    switch (signal.type) {
      case CallSignalType.invite:
        _onIncomingInvite(signal);
      case CallSignalType.accept:
        if (signal.callId == _callId &&
            (phase.value == CallPhase.outgoing ||
                phase.value == CallPhase.connecting)) {
          CallFlowLogger.info('signal accept → join Agora', context: _ctx());
          _ringingTimer?.cancel();
          _setPhase(CallPhase.connecting, reason: 'remote_accepted');
          await _joinAgoraChannel();
        } else {
          CallFlowLogger.warn(
            'signal accept ignored',
            context: _ctx(signalCallId: signal.callId),
          );
        }
      case CallSignalType.reject:
        if (signal.callId == _callId) {
          CallFlowLogger.warn('signal reject → idle', context: _ctx());
          _ringingTimer?.cancel();
          _resetToIdle(closeScreen: true, reason: 'signal_reject');
        }
      case CallSignalType.busy:
        if (signal.callId == _callId) {
          CallFlowLogger.warn('signal busy → idle', context: _ctx());
          _ringingTimer?.cancel();
          _resetToIdle(closeScreen: true, reason: 'signal_busy');
        }
      case CallSignalType.end:
        if (signal.callId == _callId) {
          _ringingTimer?.cancel();
          final endedBeforeConnect = _endedBeforeConnect();
          if (endedBeforeConnect) {
            CallFlowLogger.warn(
              'signal end before connect → treat as reject',
              context: _ctx(),
            );
            errorMessage.value = 'call_rejected'.tr;
            unawaited(_postCallLog(CallLogEvent.declined));
            _resetToIdle(closeScreen: true, reason: 'signal_end_early');
            break;
          }
          CallFlowLogger.info('signal end → idle', context: _ctx());
          final durationSeconds = _snapshotDurationSeconds();
          unawaited(
            _postCallLog(
              CallLogEvent.ended,
              durationSeconds: durationSeconds,
            ),
          );
          _resetToIdle(closeScreen: true, reason: 'signal_end');
        }
    }
  }

  void _onIncomingInvite(CallSignalPayload signal) {
    // Push + Realtime can deliver the same invite twice — must not reply "busy".
    if (signal.callId == _callId &&
        (phase.value == CallPhase.incoming ||
            phase.value == CallPhase.connecting ||
            phase.value == CallPhase.inCall ||
            phase.value == CallPhase.outgoing)) {
      CallFlowLogger.trace(
        'duplicate invite ignored',
        context: _ctx(signalCallId: signal.callId),
      );
      return;
    }

    if (phase.value != CallPhase.idle && phase.value != CallPhase.ended) {
      CallFlowLogger.warn(
        'incoming invite while busy → sending busy',
        context: _ctx(signalCallId: signal.callId),
      );
      _repository.sendSignal(
        CallSignalPayload(
          type: CallSignalType.busy,
          callId: signal.callId,
          roomId: roomArgs.roomId,
          userId: currentUserId!,
        ),
      );
      return;
    }

    _callId = signal.callId;
    _channelName = '${roomArgs.roomId}_${_callId!}';
    _callLogPosted = false;
    callType.value = signal.callType ?? CallType.audio;
    CallFlowLogger.info(
      'incoming invite',
      context: _ctx(
        callerId: signal.callerId,
        callerName: signal.callerName,
      ),
    );
    _setPhase(CallPhase.incoming, reason: 'invite_received');
    _openCallScreen();
    _startCallRingtone();
    _startRingingTimeout(incoming: true);
  }

  Future<void> _joinAgoraChannel() async {
    final channelName = _channelName;
    if (channelName == null) {
      CallFlowLogger.warn('_joinAgoraChannel: no channelName', context: _ctx());
      return;
    }
    if (_isJoiningChannel) {
      CallFlowLogger.trace('_joinAgoraChannel: already joining', context: _ctx());
      return;
    }
    if (phase.value == CallPhase.inCall && _connectedAt != null) {
      CallFlowLogger.trace('_joinAgoraChannel: already in call', context: _ctx());
      return;
    }

    CallFlowLogger.info('_joinAgoraChannel start', context: _ctx());
    unawaited(_ringtoneService.stopRinging());
    _isJoiningChannel = true;
    _setPhase(CallPhase.connecting, reason: 'agora_join_start');
    errorMessage.value = '';

    final tokenResult = await _repository.fetchToken(
      roomId: roomArgs.roomId,
      channelName: channelName,
    );

    if (tokenResult.failure != null || tokenResult.token == null) {
      _isJoiningChannel = false;
      CallFlowLogger.error(
        'token fetch failed',
        context: _ctx(error: tokenResult.failure?.message),
      );
      _showError(tokenResult.failure?.message ?? 'call_token_failed');
      await _sendHangupSignal(CallSignalType.reject);
      _resetToIdle(closeScreen: true, reason: 'token_failed');
      return;
    }

    final token = tokenResult.token!;
    _appId = token.appId.isNotEmpty ? token.appId : EnvConfig.agoraAppId;
    CallFlowLogger.info(
      'token ok',
      context: {
        'channel': token.channelName,
        'userAccount': token.userAccount,
        'appId': _appId,
        'token': CallFlowLogger.tokenPreview(token.token),
        'expiresAt': token.expiresAt.toIso8601String(),
      },
    );

    try {
      await _agoraService.initialize(
        appId: _appId!,
        handler: RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) {
            CallFlowLogger.info(
              'Agora onJoinChannelSuccess (waiting for remote user)',
              context: {
                'channel': connection.channelId,
                'localUid': connection.localUid,
                'elapsedMs': elapsed,
                ..._ctx(),
              },
            );
          },
          onUserJoined: (connection, remoteUidValue, elapsed) {
            CallFlowLogger.info(
              'Agora onUserJoined',
              context: {
                'remoteUid': remoteUidValue,
                'elapsedMs': elapsed,
                'channel': connection.channelId,
              },
            );
            _remoteOfflineTimer?.cancel();
            remoteUid.value = remoteUidValue;
            _markCallConnected();
          },
          onUserOffline: (connection, remoteUidValue, reason) {
            if (remoteUid.value != remoteUidValue) {
              CallFlowLogger.trace(
                'Agora onUserOffline ignored (uid mismatch)',
                context: {
                  'eventUid': remoteUidValue,
                  'trackedUid': remoteUid.value,
                  'reason': reason.name,
                },
              );
              return;
            }
            CallFlowLogger.warn(
              'Agora onUserOffline',
              context: {
                'remoteUid': remoteUidValue,
                'reason': reason.name,
                ..._ctx(),
              },
            );
            remoteUid.value = null;
            _scheduleRemoteOfflineHangup();
          },
          onError: (err, msg) {
            CallFlowLogger.error(
              'Agora onError',
              context: {'code': err.toString(), 'message': msg},
            );
          },
          onConnectionStateChanged: (connection, state, reason) {
            CallFlowLogger.trace(
              'Agora connectionState',
              context: {
                'state': state.name,
                'reason': reason.name,
                'channel': connection.channelId,
              },
            );
          },
        ),
      );

      await WakelockPlus.enable();
      isSpeakerOn.value = callType.value.isVideo;
      await _agoraService.setSpeakerphone(isSpeakerOn.value);

      await _agoraService.joinChannel(
        token: token.token,
        channelName: token.channelName,
        userAccount: token.userAccount,
        video: callType.value.isVideo,
      );

      CallFlowLogger.info(
        'joinChannel invoked',
        context: _ctx(video: callType.value.isVideo),
      );
      isVideoEnabled.value = callType.value.isVideo;
    } catch (error, stack) {
      CallFlowLogger.error(
        '_joinAgoraChannel failed',
        error: error,
        stackTrace: stack,
        context: _ctx(),
      );
      _showError('call_join_failed');
      await _sendHangupSignal(CallSignalType.reject);
      _resetToIdle(closeScreen: true, reason: 'join_exception');
    } finally {
      _isJoiningChannel = false;
    }
  }

  void _scheduleRemoteOfflineHangup() {
    if (_connectedAt == null) return;
    if (phase.value != CallPhase.inCall) return;

    CallFlowLogger.info('schedule remote offline hangup in 3s', context: _ctx());
    _remoteOfflineTimer?.cancel();
    _remoteOfflineTimer = Timer(const Duration(seconds: 3), () {
      if (remoteUid.value != null) return;
      if (_connectedAt == null) return;
      if (phase.value != CallPhase.inCall) return;
      CallFlowLogger.warn('remote offline timeout → endCall', context: _ctx());
      unawaited(endCall());
    });
  }

  bool _endedBeforeConnect() =>
      phase.value == CallPhase.outgoing ||
      (phase.value == CallPhase.connecting && _connectedAt == null);

  /// Before both peers are in the channel, use `reject` so the caller still
  /// ringing gets the right signal (not `end` while phase is outgoing).
  CallSignalType _hangupSignalType() {
    if (_connectedAt != null && phase.value == CallPhase.inCall) {
      return CallSignalType.end;
    }
    if (phase.value == CallPhase.outgoing) {
      return CallSignalType.end;
    }
    return CallSignalType.reject;
  }

  Future<void> _sendHangupSignal(CallSignalType type) async {
    if (_callId == null) return;
    CallFlowLogger.trace(
      'sendHangupSignal',
      context: _ctx(hangupSignal: type.value),
    );
    await _repository.sendSignal(
      CallSignalPayload(
        type: type,
        callId: _callId!,
        roomId: roomArgs.roomId,
        userId: currentUserId!,
      ),
    );
  }

  void _markCallConnected() {
    if (_connectedAt != null) {
      CallFlowLogger.trace('_markCallConnected: already connected', context: _ctx());
      return;
    }

    unawaited(_ringtoneService.stopRinging());
    _connectedAt = DateTime.now();
    _ringingTimer?.cancel();
    _setPhase(CallPhase.inCall, reason: 'agora_connected');
    _startDurationTimer();
    CallFlowLogger.info('call connected', context: _ctx());
  }

  int _snapshotDurationSeconds() {
    if (_connectedAt != null) {
      final elapsed = DateTime.now().difference(_connectedAt!).inSeconds;
      if (elapsed > 0) return elapsed;
    }
    final tracked = callDuration.value.inSeconds;
    return tracked > 0 ? tracked : 0;
  }

  Future<void> _cleanupCall() async {
    CallFlowLogger.trace('_cleanupCall', context: _ctx());
    _ringingTimer?.cancel();
    _remoteOfflineTimer?.cancel();
    _durationTimer?.cancel();
    try {
      await _agoraService.leaveChannel();
      await _agoraService.disposeEngine();
      await WakelockPlus.disable();
    } catch (error, stack) {
      CallFlowLogger.error(
        '_cleanupCall failed',
        error: error,
        stackTrace: stack,
        context: _ctx(),
      );
    }
    remoteUid.value = null;
  }

  void _resetToIdle({bool closeScreen = false, String? reason}) {
    CallFlowLogger.info(
      '_resetToIdle',
      context: _ctx(closeScreen: closeScreen, reason: reason),
    );
    _ringingTimer?.cancel();
    unawaited(_ringtoneService.stopRinging());
    unawaited(_cleanupCall());
    _callId = null;
    _channelName = null;
    _appId = null;
    _connectedAt = null;
    isMuted.value = false;
    isSpeakerOn.value = false;
    isVideoEnabled.value = true;
    errorMessage.value = '';
    _setPhase(CallPhase.idle, reason: reason ?? 'reset');

    if (closeScreen) {
      leaveCallScreen();
    }
  }

  void _setPhase(CallPhase next, {required String reason}) {
    final prev = phase.value;
    if (prev == next) return;
    phase.value = next;
    if (next == CallPhase.idle) {
      callDuration.value = Duration.zero;
    }
    CallFlowLogger.info(
      'phase $prev → $next',
      context: _ctx(reason: reason),
    );
  }

  void _openCallScreen() {
    if (_isNavigating || Get.currentRoute == AppRoutes.callActive) {
      CallFlowLogger.trace(
        '_openCallScreen skipped',
        context: {
          ..._ctx(route: Get.currentRoute),
          'navigating': _isNavigating,
        },
      );
      return;
    }
    CallFlowLogger.info('_openCallScreen', context: _ctx());
    _isNavigating = true;
    Get.toNamed(AppRoutes.callActive)?.whenComplete(() {
      _isNavigating = false;
      CallFlowLogger.trace('call screen closed (route pop)', context: _ctx());
    });
  }

  void _startCallRingtone() {
    unawaited(_ringtoneService.startRinging());
  }

  void _startRingingTimeout({bool incoming = false}) {
    _ringingTimer?.cancel();
    _ringingTimer = Timer(const Duration(seconds: 45), () {
      CallFlowLogger.warn('ringing timeout', context: _ctx(incoming: incoming));
      if (incoming && phase.value == CallPhase.incoming) {
        unawaited(rejectIncomingCall(logEvent: CallLogEvent.missed));
      } else if (phase.value == CallPhase.outgoing) {
        _showError('call_no_answer');
        unawaited(endCall(logEvent: CallLogEvent.noAnswer));
      }
    });
  }

  void _presentPendingInviteIfAny() {
    final pending =
        IncomingCallCoordinator.takeForRoom(roomArgs.roomId) ??
        roomArgs.pendingCallInvite;
    if (pending == null || pending.callId.isEmpty) {
      CallFlowLogger.trace('no pending invite', context: _ctx());
      return;
    }

    CallFlowLogger.info(
      'present pending invite',
      context: {
        'callId': pending.callId,
        'callerId': pending.callerId,
        'type': pending.callType.name,
      },
    );
    _onIncomingInvite(
      CallSignalPayload(
        type: CallSignalType.invite,
        callId: pending.callId,
        roomId: pending.roomId,
        userId: pending.callerId,
        callerId: pending.callerId,
        callerName: pending.callerName,
        callType: pending.callType,
      ),
    );
  }

  Future<void> _postCallLog(
    CallLogEvent event, {
    int durationSeconds = 0,
  }) async {
    if (_callLogPosted) return;
    _callLogPosted = true;

    if (!Get.isRegistered<ChatRepository>()) return;

    final payload = CallLogPayload(
      event: event,
      callType: callType.value,
      durationSeconds: durationSeconds,
    );

    try {
      await Get.find<ChatRepository>().sendCallLogMessage(
        roomId: roomArgs.roomId,
        content: payload.toJsonString(),
      );
    } catch (error, stack) {
      CallFlowLogger.error(
        '_postCallLog failed',
        error: error,
        stackTrace: stack,
        context: _ctx(logEvent: event.name),
      );
    }
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    callDuration.value = Duration.zero;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      callDuration.value += const Duration(seconds: 1);
    });
  }

  Future<bool> _ensurePermissions(CallType type) async {
    final mic = await Permission.microphone.request();
    CallFlowLogger.trace('mic permission', context: {'status': mic.name});
    if (!mic.isGranted) {
      CallFlowLogger.warn('microphone denied', context: _ctx());
      _showError('call_permission_denied');
      return false;
    }

    if (type.isVideo) {
      final camera = await Permission.camera.request();
      CallFlowLogger.trace('camera permission', context: {'status': camera.name});
      if (!camera.isGranted) {
        CallFlowLogger.warn('camera denied', context: _ctx());
        _showError('call_permission_denied');
        return false;
      }
    }

    return true;
  }

  void _showError(String key) {
    CallFlowLogger.warn('UI error', context: _ctx(errorKey: key));
    errorMessage.value = key.tr;
    Get.snackbar('', key.tr, snackPosition: SnackPosition.BOTTOM);
  }

  Map<String, Object?> _ctx({
    String? peer,
    String? type,
    String? reason,
    String? signalCallId,
    String? callerId,
    String? callerName,
    String? logEvent,
    String? route,
    String? error,
    String? errorKey,
    bool? sendSignal,
    int? durationSec,
    bool? closeScreen,
    bool? incoming,
    bool? video,
    bool? appIdConfigured,
    String? hangupSignal,
  }) {
    return {
      'roomId': roomArgs.roomId,
      if (peer != null) 'peerId': peer,
      'callId': _callId ?? '—',
      'channel': _channelName ?? '—',
      'phase': phase.value.name,
      'callType': type ?? callType.value.name,
      'remoteUid': remoteUid.value ?? '—',
      'connected': _connectedAt != null,
      'joining': _isJoiningChannel,
      if (reason != null) 'reason': reason,
      if (signalCallId != null) 'signalCallId': signalCallId,
      if (callerId != null) 'callerId': callerId,
      if (callerName != null) 'callerName': callerName,
      if (logEvent != null) 'logEvent': logEvent,
      if (route != null) 'route': route,
      if (error != null) 'error': error,
      if (errorKey != null) 'errorKey': errorKey,
      if (sendSignal != null) 'sendSignal': sendSignal,
      if (durationSec != null) 'durationSec': durationSec,
      if (closeScreen != null) 'closeScreen': closeScreen,
      if (incoming != null) 'incoming': incoming,
      if (video != null) 'video': video,
      if (appIdConfigured != null) 'appIdConfigured': appIdConfigured,
      if (hangupSignal != null) 'hangupSignal': hangupSignal,
      'userId': currentUserId ?? '—',
    };
  }

  String get _callerDisplayName {
    final user = _authController.currentUser.value;
    if (user == null) return 'User';
    return user.fullName.trim().isEmpty ? 'User' : user.fullName;
  }

  bool get _isMobilePlatform =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _newCallId() =>
      '${DateTime.now().millisecondsSinceEpoch}-${currentUserId ?? 'user'}';
}
