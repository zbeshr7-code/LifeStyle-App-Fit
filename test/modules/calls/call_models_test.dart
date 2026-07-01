import 'package:flutter_test/flutter_test.dart';
import 'package:soccer_sys/modules/calls/models/call_models.dart';

void main() {
  test('CallSignalPayload round-trip', () {
    const original = CallSignalPayload(
      type: CallSignalType.invite,
      callId: 'call-1',
      roomId: 'room-1',
      userId: 'user-1',
      callerId: 'user-1',
      callerName: 'Trainer',
      callType: CallType.video,
    );

    final json = original.toJson();
    final parsed = CallSignalPayload.fromJson(json);

    expect(parsed.type, CallSignalType.invite);
    expect(parsed.callId, 'call-1');
    expect(parsed.callType, CallType.video);
    expect(parsed.callerName, 'Trainer');
  });
}
