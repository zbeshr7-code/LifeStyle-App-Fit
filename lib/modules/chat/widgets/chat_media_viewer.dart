import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:video_player/video_player.dart';

class ChatImageViewer extends StatelessWidget {
  const ChatImageViewer({super.key, required this.imageUrl});

  final String imageUrl;

  static void open(String imageUrl) {
    Get.to(
      () => ChatImageViewer(imageUrl: imageUrl),
      fullscreenDialog: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Get.back,
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return CircularProgressIndicator(color: AppColors.primary);
            },
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}

class ChatVideoViewer extends StatefulWidget {
  const ChatVideoViewer({super.key, required this.videoUrl});

  final String videoUrl;

  static void open(String videoUrl) {
    Get.to(
      () => ChatVideoViewer(videoUrl: videoUrl),
      fullscreenDialog: true,
    );
  }

  @override
  State<ChatVideoViewer> createState() => _ChatVideoViewerState();
}

class _ChatVideoViewerState extends State<ChatVideoViewer> {
  late VideoPlayerController _controller;
  var _initialized = false;
  var _hasError = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl))
      ..initialize().then((_) {
        if (mounted) {
          setState(() => _initialized = true);
          _controller.play();
        }
      }).catchError((_) {
        if (mounted) setState(() => _hasError = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: Get.back,
        ),
      ),
      body: Center(
        child: _hasError
            ? Icon(Icons.videocam_off, color: Colors.white54, size: 64)
            : !_initialized
                ? CircularProgressIndicator(color: AppColors.primary)
                : AspectRatio(
                    aspectRatio: _controller.value.aspectRatio,
                    child: VideoPlayer(_controller),
                  ),
      ),
      floatingActionButton: _initialized && !_hasError
          ? FloatingActionButton(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.primaryForeground,
              onPressed: () {
                setState(() {
                  _controller.value.isPlaying
                      ? _controller.pause()
                      : _controller.play();
                });
              },
              child: Icon(
                _controller.value.isPlaying ? Icons.pause : Icons.play_arrow,
              ),
            )
          : null,
    );
  }
}

class ChatMediaActions {
  static Future<void> downloadAndOpen({
    required String url,
    required String fileName,
  }) async {
    Get.dialog(
      Center(child: CircularProgressIndicator(color: AppColors.primary)),
      barrierDismissible: false,
    );

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        throw Exception('download_failed');
      }

      final dir = await getApplicationDocumentsDirectory();
      final safeName = fileName.replaceAll(RegExp(r'[^\w.\-]'), '_');
      final file = File('${dir.path}/$safeName');
      await file.writeAsBytes(response.bodyBytes);

      Get.back();
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done) {
        Get.snackbar('', 'chat_file_open_failed'.tr,
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (_) {
      if (Get.isDialogOpen ?? false) Get.back();
      Get.snackbar('', 'chat_download_failed'.tr,
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
