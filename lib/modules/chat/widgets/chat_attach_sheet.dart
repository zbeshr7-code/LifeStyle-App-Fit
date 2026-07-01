import 'dart:ui';



import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:soccer_sys/core/theme/tokens.dart';



class ChatAttachSheet extends StatelessWidget {

  const ChatAttachSheet({

    super.key,

    required this.onImage,

    required this.onCamera,

    required this.onVideo,

    required this.onFile,

  });



  final VoidCallback onImage;

  final VoidCallback onCamera;

  final VoidCallback onVideo;

  final VoidCallback onFile;



  static Future<void> show({

    required VoidCallback onImage,

    required VoidCallback onCamera,

    required VoidCallback onVideo,

    required VoidCallback onFile,

  }) {

    return Get.bottomSheet(

      ChatAttachSheet(

        onImage: onImage,

        onCamera: onCamera,

        onVideo: onVideo,

        onFile: onFile,

      ),

      backgroundColor: Colors.transparent,

    );

  }



  @override

  Widget build(BuildContext context) {

    return ClipRRect(

      borderRadius: const BorderRadius.vertical(

        top: Radius.circular(AppRadius.xl),

      ),

      child: BackdropFilter(

        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),

        child: DecoratedBox(

          decoration: BoxDecoration(

            color: AppColors.surfaceSolid.withValues(alpha: 0.95),

            borderRadius: const BorderRadius.vertical(

              top: Radius.circular(AppRadius.xl),

            ),

            border: Border.all(color: AppColors.surfaceBorder),

          ),

          child: SafeArea(

            top: false,

            child: Padding(

              padding: const EdgeInsetsDirectional.all(AppSpacing.lg),

              child: Wrap(

                alignment: WrapAlignment.spaceEvenly,

                spacing: AppSpacing.md,

                runSpacing: AppSpacing.md,

                children: [

                  _AttachOption(

                    icon: Icons.photo_library_outlined,

                    label: 'chat_attach_gallery'.tr,

                    onTap: () {

                      Get.back();

                      onImage();

                    },

                  ),

                  _AttachOption(

                    icon: Icons.camera_alt_outlined,

                    label: 'chat_attach_camera'.tr,

                    onTap: () {

                      Get.back();

                      onCamera();

                    },

                  ),

                  _AttachOption(

                    icon: Icons.videocam_outlined,

                    label: 'chat_attach_video'.tr,

                    onTap: () {

                      Get.back();

                      onVideo();

                    },

                  ),

                  _AttachOption(

                    icon: Icons.attach_file,

                    label: 'chat_attach_file'.tr,

                    onTap: () {

                      Get.back();

                      onFile();

                    },

                  ),

                ],

              ),

            ),

          ),

        ),

      ),

    );

  }

}



class _AttachOption extends StatelessWidget {

  const _AttachOption({

    required this.icon,

    required this.label,

    required this.onTap,

  });



  final IconData icon;

  final String label;

  final VoidCallback onTap;



  @override

  Widget build(BuildContext context) {

    return InkWell(

      onTap: onTap,

      borderRadius: BorderRadius.circular(AppRadius.lg),

      child: Padding(

        padding: const EdgeInsetsDirectional.all(AppSpacing.md),

        child: Column(

          mainAxisSize: MainAxisSize.min,

          children: [

            Container(

              padding: const EdgeInsets.all(AppSpacing.md),

              decoration: BoxDecoration(

                color: AppColors.primary.withValues(alpha: 0.15),

                shape: BoxShape.circle,

              ),

              child: Icon(icon, color: AppColors.primary, size: 28),

            ),

            const SizedBox(height: AppSpacing.sm),

            Text(

              label,

              style: Theme.of(context).textTheme.labelMedium,

            ),

          ],

        ),

      ),

    );

  }

}


