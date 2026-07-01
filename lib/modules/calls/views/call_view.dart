import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/calls/controllers/call_controller.dart';
import 'package:soccer_sys/modules/calls/models/call_models.dart';

class CallView extends GetView<CallController> {
  const CallView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => PopScope(
        canPop: controller.phase.value == CallPhase.idle ||
            controller.phase.value == CallPhase.ended,
        onPopInvokedWithResult: (didPop, result) {
          if (didPop) return;
          controller.handleCallScreenClosed();
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: SafeArea(
            child: Obx(() {
              switch (controller.phase.value) {
                case CallPhase.incoming:
                  return _IncomingCallBody(controller: controller);
                case CallPhase.outgoing:
                  return _OutgoingCallBody(controller: controller);
                case CallPhase.connecting:
                  return _ConnectingCallBody(controller: controller);
                case CallPhase.inCall:
                  return _InCallBody(controller: controller);
                case CallPhase.ended:
                case CallPhase.idle:
                  return _EndedCallBody(controller: controller);
              }
            }),
          ),
        ),
      ),
    );
  }
}

/// Centered call layout: avatar, name, status — used across ringing/connecting.
class _CallCenterContent extends StatelessWidget {
  const _CallCenterContent({
    required this.controller,
    required this.statusText,
    this.showPulse = false,
  });

  final CallController controller;
  final String statusText;
  final bool showPulse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CallAvatarWithPulse(
          controller: controller,
          animate: showPulse,
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          controller.peerName,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: AppSpacing.sm),
        Text(
          statusText,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: AppColors.textSecondary,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _CallAvatarWithPulse extends StatefulWidget {
  const _CallAvatarWithPulse({
    required this.controller,
    this.animate = true,
  });

  final CallController controller;
  final bool animate;

  @override
  State<_CallAvatarWithPulse> createState() => _CallAvatarWithPulseState();
}

class _CallAvatarWithPulseState extends State<_CallAvatarWithPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    if (widget.animate) {
      _pulse.repeat();
    }
  }

  @override
  void didUpdateWidget(covariant _CallAvatarWithPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_pulse.isAnimating) {
      _pulse.repeat();
    } else if (!widget.animate && _pulse.isAnimating) {
      _pulse.stop();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final avatar = CircleAvatar(
      radius: 56,
      backgroundColor: AppColors.primary.withValues(alpha: 0.15),
      backgroundImage: widget.controller.peerAvatarUrl != null
          ? NetworkImage(widget.controller.peerAvatarUrl!)
          : null,
      child: widget.controller.peerAvatarUrl == null
          ? Text(
              widget.controller.peerName.isNotEmpty
                  ? widget.controller.peerName[0].toUpperCase()
                  : '?',
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
            )
          : null,
    );

    if (!widget.animate) return avatar;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final scale = 1 + (_pulse.value * 0.12);
        return Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 140 * scale,
              height: 140 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                  width: 2,
                ),
              ),
            ),
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withValues(alpha: 0.08),
              ),
            ),
            child!,
          ],
        );
      },
      child: avatar,
    );
  }
}

class _IncomingCallBody extends StatelessWidget {
  const _IncomingCallBody({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          Obx(
            () => _CallCenterContent(
              controller: controller,
              showPulse: true,
              statusText: controller.callType.value.isVideo
                  ? 'call_incoming_video'.tr
                  : 'call_incoming_audio'.tr,
            ),
          ),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _RoundActionButton(
                icon: Icons.call_end,
                label: 'call_reject'.tr,
                color: AppColors.error,
                onTap: controller.rejectIncomingCall,
              ),
              _RoundActionButton(
                icon: controller.callType.value.isVideo
                    ? Icons.videocam
                    : Icons.call,
                label: 'call_accept'.tr,
                color: Colors.green,
                onTap: controller.acceptIncomingCall,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _OutgoingCallBody extends StatelessWidget {
  const _OutgoingCallBody({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          _CallCenterContent(
            controller: controller,
            showPulse: true,
            statusText: 'call_outgoing'.tr,
          ),
          const Spacer(),
          _RoundActionButton(
            icon: Icons.call_end,
            label: 'call_cancel'.tr,
            color: AppColors.error,
            onTap: controller.cancelOutgoingCall,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _ConnectingCallBody extends StatelessWidget {
  const _ConnectingCallBody({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        children: [
          const Spacer(),
          _CallCenterContent(
            controller: controller,
            showPulse: true,
            statusText: 'call_connecting'.tr,
          ),
          const Spacer(),
          _RoundActionButton(
            icon: Icons.call_end,
            label: 'call_end'.tr,
            color: AppColors.error,
            onTap: controller.endCall,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _InCallBody extends StatelessWidget {
  const _InCallBody({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) {
    final engine = controller.agoraService.engine;
    final isVideo = controller.callType.value.isVideo && engine != null;

    return Stack(
      fit: StackFit.expand,
      children: [
        if (isVideo)
          Obx(() {
            final remote = controller.remoteUid.value;
            if (remote != null) {
              return AgoraVideoView(
                controller: VideoViewController.remote(
                  rtcEngine: engine,
                  canvas: VideoCanvas(uid: remote),
                  connection: RtcConnection(
                    channelId: controller.activeChannelName ?? '',
                  ),
                ),
              );
            }
            return ColoredBox(
              color: AppColors.surfaceSolid,
              child: Center(
                child: _CallCenterContent(
                  controller: controller,
                  statusText: 'call_waiting_peer'.tr,
                ),
              ),
            );
          })
        else
          Center(
            child: Padding(
              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
              child: Obx(
                () => _CallCenterContent(
                  controller: controller,
                  statusText: controller.formatDuration(
                    controller.callDuration.value,
                  ),
                ),
              ),
            ),
          ),
        if (isVideo)
          Obx(() {
            if (controller.remoteUid.value == null) {
              return const SizedBox.shrink();
            }
            return PositionedDirectional(
              top: AppSpacing.md,
              end: AppSpacing.md,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                child: SizedBox(
                  width: 112,
                  height: 148,
                  child: AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  ),
                ),
              ),
            );
          }),
        Positioned(
          left: 0,
          right: 0,
          bottom: AppSpacing.lg,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isVideo)
                Obx(
                  () => Text(
                    controller.formatDuration(controller.callDuration.value),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppColors.textPrimary,
                          shadows: const [
                            Shadow(
                              blurRadius: 8,
                              color: Colors.black54,
                            ),
                          ],
                        ),
                  ),
                ),
              if (isVideo) SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Obx(
                    () => _RoundActionButton(
                      icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
                      label: 'call_mute'.tr,
                      color: AppColors.surfaceSolid,
                      iconColor: AppColors.textPrimary,
                      onTap: controller.toggleMute,
                    ),
                  ),
                  Obx(
                    () => _RoundActionButton(
                      icon: controller.isSpeakerOn.value
                          ? Icons.volume_up
                          : Icons.volume_off,
                      label: 'call_speaker'.tr,
                      color: AppColors.surfaceSolid,
                      iconColor: AppColors.textPrimary,
                      onTap: controller.toggleSpeaker,
                    ),
                  ),
                  if (controller.callType.value.isVideo)
                    Obx(
                      () => _RoundActionButton(
                        icon: controller.isVideoEnabled.value
                            ? Icons.videocam
                            : Icons.videocam_off,
                        label: 'call_video'.tr,
                        color: AppColors.surfaceSolid,
                        iconColor: AppColors.textPrimary,
                        onTap: controller.toggleVideo,
                      ),
                    ),
                  if (controller.callType.value.isVideo)
                    _RoundActionButton(
                      icon: Icons.cameraswitch,
                      label: 'call_flip'.tr,
                      color: AppColors.surfaceSolid,
                      iconColor: AppColors.textPrimary,
                      onTap: controller.switchCamera,
                    ),
                  _RoundActionButton(
                    icon: Icons.call_end,
                    label: 'call_end'.tr,
                    color: AppColors.error,
                    onTap: controller.endCall,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EndedCallBody extends StatelessWidget {
  const _EndedCallBody({required this.controller});

  final CallController controller;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Obx(
            () => Text(
              controller.errorMessage.value.isNotEmpty
                  ? controller.errorMessage.value
                  : 'call_ended'.tr,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          FilledButton(
            onPressed: controller.leaveCallScreen,
            child: Text('call_close'.tr),
          ),
        ],
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconColor = Colors.white,
  });

  final IconData icon;
  final String label;
  final Color color;
  final Color iconColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Material(
          color: color,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(icon, color: iconColor),
            ),
          ),
        ),
        SizedBox(height: AppSpacing.xs),
        SizedBox(
          width: 72,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ),
      ],
    );
  }
}
