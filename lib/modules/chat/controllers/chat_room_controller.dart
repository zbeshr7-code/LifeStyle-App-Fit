import 'dart:async';

import 'dart:io';



import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:image_picker/image_picker.dart';

import 'package:soccer_sys/modules/chat/widgets/chat_attach_sheet.dart';

import 'package:file_picker/file_picker.dart';

import 'package:record/record.dart';

import 'package:path_provider/path_provider.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:soccer_sys/core/services/supabase_service.dart';

import 'package:soccer_sys/modules/chat/controllers/chat_controller.dart';

import 'package:soccer_sys/modules/chat/models/chat_message_model.dart';

import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';

import 'package:soccer_sys/modules/chat/models/message_type.dart';

import 'package:soccer_sys/modules/chat/repositories/chat_repository.dart';

import 'package:soccer_sys/modules/chat/utils/chat_media_utils.dart';



class ChatRoomController extends GetxController {

  ChatRoomController(

    this._chatRepository,

    this._supabaseService,

    this.args,

  );



  final ChatRepository _chatRepository;

  final SupabaseService _supabaseService;

  final ChatRoomArgs args;



  final messages = <ChatMessageModel>[].obs;

  final status = Rx<RxStatus>(RxStatus.empty());

  final isSending = false.obs;

  final isRecording = false.obs;

  final recordingAmplitudes = <double>[].obs;

  final recordingElapsed = Duration.zero.obs;

  final errorMessage = ''.obs;

  final peerLastSeen = Rxn<DateTime>();

  final peerLastReadAt = Rxn<DateTime>();

  final textController = TextEditingController();

  final scrollController = ScrollController();



  final _audioRecorder = AudioRecorder();

  String? _recordingPath;

  DateTime? _recordingStartedAt;

  Timer? _presenceTimer;

  StreamSubscription<Amplitude>? _amplitudeSub;

  Timer? _recordingTimer;

  static const _waveBarCount = 32;



  String? get currentUserId => _supabaseService.client.auth.currentUser?.id;



  @override

  void onInit() {

    super.onInit();

    loadMessages();

    markAsRead();

    _startPresenceTracking();

    _chatRepository.subscribeToPeerPresence(args.peerId, (lastSeen) {

      peerLastSeen.value = lastSeen;

    });

    _chatRepository.subscribeToRoom(args.roomId, _onRealtimeMessage);

  }



  @override

  void onClose() {

    _presenceTimer?.cancel();

    _amplitudeSub?.cancel();

    _recordingTimer?.cancel();

    _chatRepository.unsubscribeFromPeerPresence();

    _chatRepository.unsubscribeFromRoom();

    textController.dispose();

    scrollController.dispose();

    _audioRecorder.dispose();

    super.onClose();

  }



  void _startPresenceTracking() {

    _refreshPresence();

    _presenceTimer = Timer.periodic(const Duration(seconds: 15), (_) {

      _refreshPresence();

    });

  }



  Future<void> _refreshPresence() async {

    await _chatRepository.updateLastSeen();

    peerLastSeen.value = await _chatRepository.fetchPeerLastSeen(args.peerId);

    peerLastReadAt.value = await _chatRepository.fetchPeerLastReadAt(

      roomId: args.roomId,

      peerId: args.peerId,

    );

  }



  bool isMessageReadByPeer(ChatMessageModel message) {

    if (message.senderId != currentUserId) return false;

    final readAt = peerLastReadAt.value;

    if (readAt == null) return false;

    return !readAt.isBefore(message.createdAt);

  }



  Future<void> loadMessages() async {

    status.value = RxStatus.loading();

    final result = await _chatRepository.fetchMessages(args.roomId);

    if (result.failure != null) {

      errorMessage.value = result.failure!.message.tr;

      status.value = RxStatus.error(result.failure!.message.tr);

      return;

    }

    messages.assignAll(result.messages);

    status.value = RxStatus.success();

    _scrollToBottom();

  }



  Future<void> markAsRead() async {

    await _chatRepository.markRoomAsRead(args.roomId);

    if (Get.isRegistered<ChatController>()) {

      Get.find<ChatController>().clearRoomUnread(args.roomId);

    }

  }



  void _onRealtimeMessage(ChatMessageModel message) {

    if (messages.any((m) => m.id == message.id)) return;

    messages.add(message);

    markAsRead();

    _scrollToBottom();

  }



  Future<void> sendText() async {

    final text = textController.text.trim();

    if (text.isEmpty || isSending.value) return;



    isSending.value = true;

    textController.clear();



    final result = await _chatRepository.sendTextMessage(

      roomId: args.roomId,

      content: text,

    );



    isSending.value = false;

    if (result.failure != null) {

      errorMessage.value = result.failure!.message.tr;

      return;

    }

    if (result.message != null &&

        !messages.any((m) => m.id == result.message!.id)) {

      messages.add(result.message!);

      _scrollToBottom();

    }

  }



  Future<void> showAttachSheet() {

    return ChatAttachSheet.show(

      onImage: () => pickImage(ImageSource.gallery),

      onCamera: () => pickImage(ImageSource.camera),

      onVideo: pickVideo,

      onFile: pickFile,

    );

  }



  Future<void> pickImage(ImageSource source) async {

    final picker = ImagePicker();

    final file = await picker.pickImage(source: source, imageQuality: 85);

    if (file == null) return;



    isSending.value = true;

    final bytes = await file.readAsBytes();

    final result = await _chatRepository.sendMediaMessage(

      roomId: args.roomId,

      type: MessageType.image,

      bytes: bytes,

      fileName: file.name,

    );

    isSending.value = false;

    _handleSendResult(result.message, result.failure);

  }



  Future<void> pickVideo() async {

    final picker = ImagePicker();

    final file = await picker.pickVideo(source: ImageSource.gallery);

    if (file == null) return;



    isSending.value = true;

    final bytes = await file.readAsBytes();

    final result = await _chatRepository.sendMediaMessage(

      roomId: args.roomId,

      type: MessageType.video,

      bytes: bytes,

      fileName: file.name,

    );

    isSending.value = false;

    _handleSendResult(result.message, result.failure);

  }



  Future<void> pickFile() async {

    final result = await FilePicker.platform.pickFiles(withData: true);

    if (result == null || result.files.isEmpty) return;



    final file = result.files.first;

    if (file.bytes == null) return;



    final isVideo = ChatMediaUtils.isVideoFileName(file.name);

    isSending.value = true;

    final sendResult = await _chatRepository.sendMediaMessage(

      roomId: args.roomId,

      type: isVideo ? MessageType.video : MessageType.file,

      bytes: file.bytes!,

      fileName: file.name,

    );

    isSending.value = false;

    _handleSendResult(sendResult.message, sendResult.failure);

  }



  Future<bool> _ensureMicPermission() async {

    final status = await Permission.microphone.request();

    if (status.isGranted) return true;



    if (status.isPermanentlyDenied) {

      Get.snackbar('', 'chat_mic_permission_denied'.tr,

          snackPosition: SnackPosition.BOTTOM);

      await openAppSettings();

    } else {

      Get.snackbar('', 'chat_mic_permission_required'.tr,

          snackPosition: SnackPosition.BOTTOM);

    }

    return false;

  }



  Future<void> toggleRecording() async {

    if (isRecording.value) {

      await stopRecordingAndSend();

      return;

    }

    await startRecording();

  }



  Future<void> startRecording() async {

    if (isRecording.value) return;

    if (!await _ensureMicPermission()) return;

    if (!await _audioRecorder.hasPermission()) {

      Get.snackbar('', 'chat_mic_permission_required'.tr,

          snackPosition: SnackPosition.BOTTOM);

      return;

    }



    final dir = await getTemporaryDirectory();

    _recordingPath =

        '${dir.path}/chat_${DateTime.now().millisecondsSinceEpoch}.m4a';



    await _audioRecorder.start(

      const RecordConfig(encoder: AudioEncoder.aacLc),

      path: _recordingPath!,

    );

    _recordingStartedAt = DateTime.now();

    isRecording.value = true;

    recordingAmplitudes.assignAll(List<double>.filled(_waveBarCount, 0.15));

    recordingElapsed.value = Duration.zero;

    _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {

      if (_recordingStartedAt != null) {

        recordingElapsed.value =

            DateTime.now().difference(_recordingStartedAt!);

      }

    });

    _amplitudeSub = _audioRecorder

        .onAmplitudeChanged(const Duration(milliseconds: 100))

        .listen((amp) {

      final level = _normalizeAmplitude(amp.current);

      final next = List<double>.from(recordingAmplitudes);

      if (next.isEmpty) {

        recordingAmplitudes.assignAll(List<double>.filled(_waveBarCount, level));

        return;

      }

      next.removeAt(0);

      next.add(level);

      recordingAmplitudes.assignAll(next);

    });

  }



  double _normalizeAmplitude(double db) {

    return ((db + 45) / 35).clamp(0.12, 1.0);

  }



  Future<void> _clearRecordingUi() async {

    _amplitudeSub?.cancel();

    _amplitudeSub = null;

    _recordingTimer?.cancel();

    _recordingTimer = null;

    recordingAmplitudes.clear();

    recordingElapsed.value = Duration.zero;

    _recordingStartedAt = null;

  }



  Future<void> stopRecordingAndSend() async {

    if (!isRecording.value) return;



    final path = await _audioRecorder.stop();

    isRecording.value = false;

    final durationMs = _recordingStartedAt == null

        ? null

        : DateTime.now().difference(_recordingStartedAt!).inMilliseconds;

    await _clearRecordingUi();



    if (path == null) return;



    final file = File(path);

    if (!await file.exists()) return;



    if (durationMs != null && durationMs < 500) {

      Get.snackbar('', 'chat_recording_too_short'.tr,

          snackPosition: SnackPosition.BOTTOM);

      return;

    }



    isSending.value = true;

    final result = await _chatRepository.sendMediaMessage(

      roomId: args.roomId,

      type: MessageType.audio,

      bytes: await file.readAsBytes(),

      fileName: 'audio.m4a',

      audioDurationMs: durationMs,

    );

    isSending.value = false;

    _handleSendResult(result.message, result.failure);

  }



  Future<void> cancelRecording() async {

    if (!isRecording.value) return;

    await _audioRecorder.stop();

    isRecording.value = false;

    _recordingPath = null;

    await _clearRecordingUi();

  }



  void _handleSendResult(ChatMessageModel? message, failure) {

    if (failure != null) {

      errorMessage.value = failure.message.tr;

      return;

    }

    if (message != null && !messages.any((m) => m.id == message.id)) {

      messages.add(message);

      _scrollToBottom();

    }

  }



  void _scrollToBottom() {

    WidgetsBinding.instance.addPostFrameCallback((_) {

      if (!scrollController.hasClients) return;

      scrollController.animateTo(

        scrollController.position.maxScrollExtent,

        duration: const Duration(milliseconds: 250),

        curve: Curves.easeOut,

      );

    });

  }

}


