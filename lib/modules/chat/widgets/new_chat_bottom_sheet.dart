import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:soccer_sys/core/theme/tokens.dart';
import 'package:soccer_sys/modules/auth/controllers/auth_controller.dart';
import 'package:soccer_sys/modules/auth/models/user_role.dart';
import 'package:soccer_sys/modules/chat/models/chat_room_model.dart';
import 'package:soccer_sys/modules/chat/repositories/chat_repository.dart';

class NewChatBottomSheet extends StatefulWidget {
  const NewChatBottomSheet({
    super.key,
    required this.targetRole,
    required this.onPeerSelected,
  });

  final UserRole targetRole;
  final ValueChanged<ChatPeerModel> onPeerSelected;

  @override
  State<NewChatBottomSheet> createState() => _NewChatBottomSheetState();
}

class _NewChatBottomSheetState extends State<NewChatBottomSheet> {
  final _searchController = TextEditingController();
  final _peers = <ChatPeerModel>[].obs;
  final _isLoading = true.obs;
  final _error = ''.obs;

  static String _initials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed[0].toUpperCase();
  }

  @override
  void initState() {
    super.initState();
    _loadPeers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPeers() async {
    _isLoading.value = true;
    final auth = Get.find<AuthController>();
    final role = auth.currentUser.value?.role ?? widget.targetRole;
    final result = await Get.find<ChatRepository>().fetchAssignedPeers(
      myRole: role,
    );
    if (result.failure != null) {
      _error.value = result.failure!.message.tr;
    } else {
      _peers.assignAll(result.peers);
    }
    _isLoading.value = false;
  }

  List<ChatPeerModel> get _filteredPeers {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _peers;
    return _peers
        .where((p) => p.fullName.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.targetRole == UserRole.trainee
        ? 'chat_pick_trainee'.tr
        : 'chat_pick_trainer'.tr;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: ClipRRect(
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
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.65,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: AppSpacing.sm),
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.iconMuted,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.all(AppSpacing.md),
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsetsDirectional.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          hintText: 'chat_search'.tr,
                          prefixIcon: const Icon(Icons.search),
                          filled: true,
                          fillColor: AppColors.inputFill,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(AppRadius.lg),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Expanded(
                      child: Obx(() {
                        if (_isLoading.value) {
                          return Center(
                            child: CircularProgressIndicator(
                              color: AppColors.primary,
                            ),
                          );
                        }
                        if (_error.value.isNotEmpty) {
                          return Center(
                            child: Text(
                              _error.value,
                              style: TextStyle(color: AppColors.error),
                            ),
                          );
                        }
                        final peers = _filteredPeers;
                        if (peers.isEmpty) {
                          return Center(
                            child: Text(
                              'chat_no_peers'.tr,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: peers.length,
                          separatorBuilder: (_, __) => Divider(
                            height: 1,
                            color: AppColors.surfaceBorder,
                          ),
                          itemBuilder: (context, index) {
                            final peer = peers[index];
                            final initials = _initials(peer.fullName);
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    AppColors.primary.withValues(alpha: 0.2),
                                backgroundImage: peer.avatarUrl != null
                                    ? NetworkImage(peer.avatarUrl!)
                                    : null,
                                child: peer.avatarUrl == null
                                    ? Text(
                                        initials,
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                              title: Text(peer.fullName),
                              onTap: () => widget.onPeerSelected(peer),
                            );
                          },
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
