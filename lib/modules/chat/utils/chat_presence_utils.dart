import 'package:get/get.dart';
import 'package:intl/intl.dart';

abstract final class ChatPresenceUtils {
  static const onlineThreshold = Duration(minutes: 3);

  static bool isOnline(DateTime? lastSeen) {
    if (lastSeen == null) return false;
    return DateTime.now().toUtc().difference(lastSeen.toUtc()) <= onlineThreshold;
  }

  static String formatStatus(DateTime? lastSeen) {
    if (lastSeen == null) return 'chat_status_offline'.tr;
    if (isOnline(lastSeen)) return 'chat_status_online'.tr;
    return 'chat_status_last_seen'.trParams({
      'time': DateFormat.yMMMd().add_jm().format(lastSeen.toLocal()),
    });
  }
}
