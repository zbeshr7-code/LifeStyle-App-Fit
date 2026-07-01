import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/chat/widgets/chat_audio_waveform.dart';

void main() {
  test('ChatAudioWaveform generates stable bars from seed', () {
    final a = ChatAudioWaveform.levelsFromSeed('msg-1', 12);
    final b = ChatAudioWaveform.levelsFromSeed('msg-1', 12);
    final c = ChatAudioWaveform.levelsFromSeed('msg-2', 12);

    expect(a, b);
    expect(a, isNot(c));
    expect(a.length, 12);
    expect(a.every((v) => v >= 0.12 && v <= 1.0), isTrue);
  });
}
