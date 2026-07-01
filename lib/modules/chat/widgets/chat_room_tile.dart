import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:intl/intl.dart';

import 'package:soccer_sys/core/theme/tokens.dart';

import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';

import 'package:soccer_sys/modules/chat/models/message_type.dart';

import 'package:soccer_sys/modules/calls/models/call_log_payload.dart';

import 'package:soccer_sys/modules/calls/utils/call_log_formatter.dart';

import 'package:soccer_sys/modules/chat/widgets/chat_unread_badge.dart';



class ChatRoomTile extends StatelessWidget {

  const ChatRoomTile({

    super.key,

    required this.room,

    required this.onTap,

  });



  final ChatRoomModel room;

  final VoidCallback onTap;



  static String _initials(String name) {

    final trimmed = name.trim();

    if (trimmed.isEmpty) return '?';

    return trimmed[0].toUpperCase();

  }



  String _previewText() {

    if (room.lastMessageType == null) return '';



    return switch (room.lastMessageType!) {

      MessageType.text => room.lastMessageContent ?? '',

      MessageType.image => 'chat_message_image'.tr,

      MessageType.file => 'chat_message_file'.tr,

      MessageType.audio => 'chat_message_audio'.tr,

      MessageType.video => 'chat_message_video'.tr,

      MessageType.call => _callPreview(),

    };

  }

  String _callPreview() {
    final payload = CallLogPayload.tryParse(room.lastMessageContent);
    if (payload != null) return CallLogFormatter.formatPreview(payload);
    return 'call_log_generic'.tr;
  }



  String _formatTime(DateTime? time) {

    if (time == null) return '';

    final now = DateTime.now();

    final local = time.toLocal();

    if (local.year == now.year &&

        local.month == now.month &&

        local.day == now.day) {

      return DateFormat.Hm().format(local);

    }

    return DateFormat.MMMd().format(local);

  }



  @override

  Widget build(BuildContext context) {

    final initials = _initials(room.peerFullName);

    final hasUnread = room.hasUnread;

    final titleStyle = Theme.of(context).textTheme.titleSmall?.copyWith(

          fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,

          color: hasUnread ? AppColors.textPrimary : null,

        );

    final previewStyle = Theme.of(context).textTheme.bodySmall?.copyWith(

          color: hasUnread ? AppColors.textPrimary : AppColors.textSecondary,

          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,

        );

    final timeStyle = Theme.of(context).textTheme.labelSmall?.copyWith(

          color: hasUnread ? AppColors.primary : AppColors.textSecondary,

          fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,

        );



    return Material(

      color: hasUnread

          ? AppColors.primary.withValues(alpha: 0.06)

          : Colors.transparent,

      child: InkWell(

        onTap: onTap,

        child: Padding(

          padding: const EdgeInsetsDirectional.symmetric(

            horizontal: AppSpacing.md,

            vertical: AppSpacing.sm,

          ),

          child: Row(

            children: [

              Stack(

                clipBehavior: Clip.none,

                children: [

                  CircleAvatar(

                    radius: 26,

                    backgroundColor: AppColors.primary.withValues(alpha: 0.2),

                    backgroundImage: room.peerAvatarUrl != null

                        ? NetworkImage(room.peerAvatarUrl!)

                        : null,

                    child: room.peerAvatarUrl == null

                        ? Text(

                            initials,

                            style: TextStyle(

                              color: AppColors.primary,

                              fontWeight: FontWeight.bold,

                              fontSize: 18,

                            ),

                          )

                        : null,

                  ),

                  if (hasUnread)

                    PositionedDirectional(

                      top: -2,

                      end: -2,

                      child: Container(

                        width: 12,

                        height: 12,

                        decoration: BoxDecoration(

                          color: AppColors.primary,

                          shape: BoxShape.circle,

                          border: Border.all(

                            color: AppColors.background,

                            width: 2,

                          ),

                        ),

                      ),

                    ),

                ],

              ),

              const SizedBox(width: AppSpacing.md),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.stretch,

                  children: [

                    Row(

                      children: [

                        Expanded(

                          child: Text(

                            room.peerFullName,

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: titleStyle,

                          ),

                        ),

                        Text(

                          _formatTime(room.lastMessageAt),

                          style: timeStyle,

                        ),

                      ],

                    ),

                    const SizedBox(height: AppSpacing.xs),

                    Row(

                      children: [

                        Expanded(

                          child: Text(

                            _previewText(),

                            maxLines: 1,

                            overflow: TextOverflow.ellipsis,

                            style: previewStyle,

                          ),

                        ),

                        if (hasUnread) ...[

                          const SizedBox(width: AppSpacing.sm),

                          ChatUnreadBadge(count: room.unreadCount),

                        ],

                      ],

                    ),

                  ],

                ),

              ),

            ],

          ),

        ),

      ),

    );

  }

}

