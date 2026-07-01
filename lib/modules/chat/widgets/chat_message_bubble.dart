import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/calls/models/call_log_payload.dart';
import 'package:soccer_sys/modules/calls/utils/call_log_formatter.dart';
import 'package:soccer_sys/modules/chat/models/chat_message_model.dart';
import 'package:soccer_sys/modules/chat/models/message_type.dart';
import 'package:soccer_sys/modules/chat/services/chat_storage_service.dart';
import 'package:soccer_sys/modules/chat/utils/chat_media_utils.dart';
import 'package:soccer_sys/modules/chat/widgets/chat_audio_waveform.dart';
import 'package:soccer_sys/modules/chat/widgets/chat_media_viewer.dart';

class ChatMessageBubble extends StatefulWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.isReadByPeer = false,
  });

  final ChatMessageModel message;
  final bool isMine;
  final bool isReadByPeer;

  @override
  State<ChatMessageBubble> createState() => _ChatMessageBubbleState();
}

class _ChatMessageBubbleState extends State<ChatMessageBubble> {
  final _audioPlayer = AudioPlayer();
  bool _isPlaying = false;
  String? _resolvedUrl;
  bool _isDownloading = false;
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();
    _resolveMedia();
    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _audioPosition = Duration.zero;
        });
      }
    });
    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) setState(() => _audioPosition = position);
    });
    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) setState(() => _audioDuration = duration);
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _resolveMedia() async {
    final url = widget.message.mediaUrl;
    if (url == null || url.isEmpty) return;
    if (url.startsWith('http')) {
      setState(() => _resolvedUrl = url);
      return;
    }
    try {
      final resolved =
          await Get.find<ChatStorageService>().resolveUrl(url);
      if (mounted) setState(() => _resolvedUrl = resolved);
    } catch (_) {}
  }

  Future<void> _toggleAudio() async {
    final url = _resolvedUrl;
    if (url == null) return;

    if (_isPlaying) {
      await _audioPlayer.stop();
      setState(() {
        _isPlaying = false;
        _audioPosition = Duration.zero;
      });
      return;
    }

    await _audioPlayer.play(UrlSource(url));
    setState(() => _isPlaying = true);
  }

  void _openImagePreview() {
    final url = _resolvedUrl;
    if (url == null) return;
    ChatImageViewer.open(url);
  }

  void _openVideoPreview() {
    final url = _resolvedUrl;
    if (url == null) return;
    ChatVideoViewer.open(url);
  }

  Future<void> _downloadFile() async {
    final url = _resolvedUrl;
    if (url == null || _isDownloading) return;
    setState(() => _isDownloading = true);
    await ChatMediaActions.downloadAndOpen(
      url: url,
      fileName: widget.message.fileName ?? 'file',
    );
    if (mounted) setState(() => _isDownloading = false);
  }

  String _formatDuration(int? ms) {
    if (ms == null) return '0:00';
    final seconds = (ms / 1000).round();
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final alignment = widget.isMine
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;
    final bgColor = widget.isMine
        ? AppColors.primary.withValues(alpha: 0.25)
        : AppColors.surfaceSolid;
    final textColor = AppColors.textPrimary;

    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsetsDirectional.only(
            bottom: AppSpacing.sm,
            start: AppSpacing.md,
            end: AppSpacing.md,
          ),
          padding: const EdgeInsetsDirectional.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadiusDirectional.only(
              topStart: const Radius.circular(AppRadius.lg),
              topEnd: const Radius.circular(AppRadius.lg),
              bottomStart: Radius.circular(
                widget.isMine ? AppRadius.lg : AppRadius.sm,
              ),
              bottomEnd: Radius.circular(
                widget.isMine ? AppRadius.sm : AppRadius.lg,
              ),
            ),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildContent(textColor),
              SizedBox(height: AppSpacing.xs),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.isMine) ...[
                    Icon(
                      widget.isReadByPeer ? Icons.done_all : Icons.done,
                      size: 14,
                      color: widget.isReadByPeer
                          ? AppColors.primary
                          : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    DateFormat.Hm().format(widget.message.createdAt.toLocal()),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textSecondary,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent(Color textColor) {
    final type = widget.message.type;
    final fileName = widget.message.fileName;

    if (ChatMediaUtils.isVideoMessage(type, fileName)) {
      return _buildVideoContent(textColor);
    }

    return switch (type) {
      MessageType.text => Text(
          widget.message.content ?? '',
          style: TextStyle(color: textColor),
        ),
      MessageType.call => _buildCallLogContent(textColor),
      MessageType.image => _buildImageContent(),
      MessageType.file => _buildFileContent(textColor),
      MessageType.audio => _buildAudioContent(textColor),
      MessageType.video => _buildVideoContent(textColor),
    };
  }

  Widget _buildCallLogContent(Color textColor) {
    final payload = CallLogPayload.tryParse(widget.message.content);
    final label = payload != null
        ? CallLogFormatter.formatBubble(payload)
        : (widget.message.content ?? '');

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.phone_in_talk_outlined,
          size: 18,
          color: textColor.withValues(alpha: 0.9),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              color: textColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageContent() {
    if (_resolvedUrl == null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return GestureDetector(
      onTap: _openImagePreview,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Stack(
          alignment: Alignment.center,
          children: [
            CachedNetworkImage(
              imageUrl: _resolvedUrl!,
              fit: BoxFit.cover,
              placeholder: (_, __) => SizedBox(
                height: 160,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(AppSpacing.xs),
              decoration: BoxDecoration(
                color: Colors.black45,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: const Icon(Icons.zoom_in, color: Colors.white, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoContent(Color textColor) {
    if (_resolvedUrl == null) {
      return SizedBox(
        height: 120,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    return GestureDetector(
      onTap: _openVideoPreview,
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(AppRadius.sm),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.videocam, color: Colors.white54, size: 48),
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 36),
            ),
            if (widget.message.fileName != null)
              PositionedDirectional(
                start: AppSpacing.sm,
                bottom: AppSpacing.sm,
                end: AppSpacing.sm,
                child: Text(
                  widget.message.fileName!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: textColor, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(Color textColor) {
    final sizeLabel = ChatMediaUtils.formatFileSize(widget.message.fileSize);
    return InkWell(
      onTap: _resolvedUrl == null || _isDownloading ? null : _downloadFile,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Padding(
        padding: const EdgeInsetsDirectional.all(AppSpacing.xs),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _isDownloading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.primary,
                    ),
                  )
                : Icon(Icons.insert_drive_file, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    widget.message.fileName ?? 'chat_message_file'.tr,
                    style: TextStyle(color: textColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (sizeLabel.isNotEmpty)
                    Text(
                      sizeLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  Text(
                    'chat_tap_to_download'.tr,
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.download, color: AppColors.primary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioContent(Color textColor) {
    final totalMs = _audioDuration.inMilliseconds > 0
        ? _audioDuration.inMilliseconds
        : (widget.message.audioDurationMs ?? 0);
    final progress = totalMs <= 0
        ? 0.0
        : (_audioPosition.inMilliseconds / totalMs).clamp(0.0, 1.0);

    return InkWell(
      onTap: _toggleAudio,
      borderRadius: BorderRadius.circular(AppRadius.sm),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _isPlaying ? Icons.pause_circle : Icons.play_circle,
            color: AppColors.primary,
            size: 36,
          ),
          SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ChatAudioWaveform(
                  seed: widget.message.id,
                  progress: progress,
                  height: 28,
                  color: widget.isMine ? AppColors.primary : AppColors.primary,
                  inactiveColor: AppColors.textSecondary,
                ),
                const SizedBox(height: 4),
                Text(
                  _isPlaying
                      ? '${_formatDuration(_audioPosition.inMilliseconds)} / ${_formatDuration(totalMs > 0 ? totalMs : widget.message.audioDurationMs)}'
                      : _formatDuration(
                          totalMs > 0 ? totalMs : widget.message.audioDurationMs,
                        ),
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
