import 'package:audioplayers/audioplayers.dart';

import 'package:soccer_sys/modules/calls/logging/call_flow_logger.dart';



/// Loops a local ringtone for incoming/outgoing call UI.

class CallRingtoneService {

  final AudioPlayer _player = AudioPlayer();

  bool _playing = false;



  Future<void> startRinging() async {

    if (_playing) {

      CallFlowLogger.trace('ringtone already playing');

      return;

    }



    CallFlowLogger.info('ringtone start');

    try {

      await _player.setAudioContext(

        AudioContext(

          android: AudioContextAndroid(

            isSpeakerphoneOn: true,

            usageType: AndroidUsageType.notificationRingtone,

            contentType: AndroidContentType.sonification,

          ),

          iOS: AudioContextIOS(

            category: AVAudioSessionCategory.playback,

            options: {AVAudioSessionOptions.mixWithOthers},

          ),

        ),

      );

      await _player.setReleaseMode(ReleaseMode.loop);

      await _player.setVolume(1);

      await _player.play(AssetSource('sounds/ringtone.wav'));

      _playing = true;

      CallFlowLogger.info('ringtone playing');

    } catch (error, stack) {

      CallFlowLogger.error(

        'ringtone start failed',

        error: error,

        stackTrace: stack,

      );

    }

  }



  Future<void> stopRinging() async {

    if (!_playing) return;



    CallFlowLogger.info('ringtone stop');

    try {

      await _player.stop();

    } catch (error, stack) {

      CallFlowLogger.error(

        'ringtone stop failed',

        error: error,

        stackTrace: stack,

      );

    } finally {

      _playing = false;

    }

  }



  Future<void> dispose() async {

    CallFlowLogger.trace('ringtone dispose');

    await stopRinging();

    await _player.dispose();

  }

}


