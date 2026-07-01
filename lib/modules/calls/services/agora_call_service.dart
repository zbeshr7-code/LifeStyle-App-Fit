import 'package:agora_rtc_engine/agora_rtc_engine.dart';

import 'package:soccer_sys/modules/calls/logging/call_flow_logger.dart';



class AgoraCallService {

  RtcEngine? _engine;

  RtcEngineEventHandler? _handler;



  RtcEngine? get engine => _engine;



  bool get isInitialized => _engine != null;



  Future<void> initialize({

    required String appId,

    required RtcEngineEventHandler handler,

  }) async {

    CallFlowLogger.info(

      'Agora initialize',

      context: {

        'appId': appId.isEmpty ? '(empty)' : '${appId.substring(0, 8)}…',

        'hadEngine': _engine != null,

      },

    );



    if (_engine != null) {

      await disposeEngine();

    }



    try {

      _handler = handler;

      _engine = createAgoraRtcEngine();

      await _engine!.initialize(

        RtcEngineContext(

          appId: appId,

          channelProfile: ChannelProfileType.channelProfileCommunication,

        ),

      );

      _engine!.registerEventHandler(handler);

      await _engine!.enableAudio();

      CallFlowLogger.info('Agora initialize done');

    } catch (error, stack) {

      CallFlowLogger.error(

        'Agora initialize failed',

        error: error,

        stackTrace: stack,

      );

      rethrow;

    }

  }



  Future<void> startPreview() async {

    CallFlowLogger.trace('Agora startPreview');

    await _engine?.enableVideo();

    await _engine?.startPreview();

  }



  Future<void> joinChannel({

    required String token,

    required String channelName,

    required String userAccount,

    required bool video,

  }) async {

    final engine = _engine;

    if (engine == null) {

      CallFlowLogger.error('joinChannel: engine is null');

      return;

    }



    CallFlowLogger.info(

      'Agora joinChannel',

      context: {

        'channel': channelName,

        'userAccount': userAccount,

        'video': video,

        'token': CallFlowLogger.tokenPreview(token),

      },

    );



    try {

      if (video) {

        await engine.enableVideo();

        await engine.startPreview();

      } else {

        await engine.disableVideo();

      }



      await engine.joinChannelWithUserAccount(

        token: token,

        channelId: channelName,

        userAccount: userAccount,

        options: const ChannelMediaOptions(

          clientRoleType: ClientRoleType.clientRoleBroadcaster,

          channelProfile: ChannelProfileType.channelProfileCommunication,

          publishMicrophoneTrack: true,

          publishCameraTrack: true,

          autoSubscribeAudio: true,

          autoSubscribeVideo: true,

        ),

      );

      CallFlowLogger.info('Agora joinChannelWithUserAccount completed');

    } catch (error, stack) {

      CallFlowLogger.error(

        'Agora joinChannel failed',

        error: error,

        stackTrace: stack,

      );

      rethrow;

    }

  }



  Future<void> leaveChannel() async {

    CallFlowLogger.info('Agora leaveChannel');

    try {

      await _engine?.leaveChannel();

    } catch (error, stack) {

      CallFlowLogger.error(

        'Agora leaveChannel failed',

        error: error,

        stackTrace: stack,

      );

    }

  }



  Future<void> setMuted(bool muted) async {

    CallFlowLogger.trace('Agora setMuted', context: {'muted': muted});

    await _engine?.muteLocalAudioStream(muted);

  }



  Future<void> setSpeakerphone(bool enabled) async {

    CallFlowLogger.trace('Agora setSpeakerphone', context: {'enabled': enabled});

    await _engine?.setEnableSpeakerphone(enabled);

  }



  Future<void> switchCamera() async {

    CallFlowLogger.trace('Agora switchCamera');

    await _engine?.switchCamera();

  }



  Future<void> setVideoEnabled(bool enabled) async {

    CallFlowLogger.trace('Agora setVideoEnabled', context: {'enabled': enabled});

    if (enabled) {

      await _engine?.enableVideo();

      await _engine?.startPreview();

    } else {

      await _engine?.disableVideo();

    }

  }



  Future<void> disposeEngine() async {

    final engine = _engine;

    if (engine == null) return;



    CallFlowLogger.info('Agora disposeEngine');

    try {

      if (_handler != null) {

        _engine!.unregisterEventHandler(_handler!);

      }

      await engine.leaveChannel();

      await engine.release();

      CallFlowLogger.info('Agora disposeEngine done');

    } catch (error, stack) {

      CallFlowLogger.error(

        'Agora disposeEngine failed',

        error: error,

        stackTrace: stack,

      );

    } finally {

      _engine = null;

      _handler = null;

    }

  }

}


