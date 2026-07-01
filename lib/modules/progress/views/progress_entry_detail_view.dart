import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/progress/controllers/progress_gallery_controller.dart';
import 'package:soccer_sys/modules/progress/models/progress_entry_model.dart';

class ProgressEntryDetailView extends StatefulWidget {
  const ProgressEntryDetailView({super.key});

  @override
  State<ProgressEntryDetailView> createState() =>
      _ProgressEntryDetailViewState();
}

class _ProgressEntryDetailViewState extends State<ProgressEntryDetailView> {
  late final ProgressEntryArgs args;
  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    args = Get.arguments as ProgressEntryArgs;
    _currentIndex = args.initialPhotoIndex;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text('progress_delete_title'.tr),
        content: Text('progress_delete_message'.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text('chat_cancel'.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(
              'progress_delete_confirm'.tr,
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await Get.find<ProgressGalleryController>().deleteEntry(args.entry);
  }

  @override
  Widget build(BuildContext context) {
    final entry = args.entry;
    final photos = entry.photos;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(DateFormat.yMMMd().format(entry.recordedAt)),
        actions: [
          IconButton(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: photos.isEmpty
                ? const Center(
                    child: Icon(Icons.image_not_supported,
                        color: Colors.white54, size: 64),
                  )
                : PageView.builder(
                    controller: _pageController,
                    itemCount: photos.length,
                    onPageChanged: (i) => setState(() => _currentIndex = i),
                    itemBuilder: (context, index) {
                      final url = photos[index].resolvedUrl;
                      if (url == null) {
                        return Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        );
                      }
                      return InteractiveViewer(
                        child: Center(
                          child: CachedNetworkImage(
                            imageUrl: url,
                            fit: BoxFit.contain,
                          ),
                        ),
                      );
                    },
                  ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsetsDirectional.all(AppSpacing.lg),
            color: AppColors.surfaceSolid,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (photos.length > 1)
                  Text(
                    '${_currentIndex + 1} / ${photos.length}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                if (entry.weightKg != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${'trainee_current_weight'.tr}: ${entry.weightKg} kg',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                if (entry.note != null && entry.note!.isNotEmpty) ...[
                  SizedBox(height: AppSpacing.sm),
                  Text(
                    entry.note!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
