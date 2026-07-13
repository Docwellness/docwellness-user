import 'dart:typed_data';

import 'package:docwellness/app/models/message_model.dart';
import 'package:docwellness/app/modules/chat/widgets/typing_indicator.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:docwellness/main.dart';

import '../controllers/chat_controller.dart';
import 'widgets/custom_food_message.dart';
import 'widgets/diet_plan_message.dart';
import 'widgets/doctor_note_message.dart';
import 'widgets/meal_log_message.dart';
import 'widgets/message_bubble.dart';
import 'widgets/water_intake_message.dart';

class ChatView extends GetView<ChatController> {
  const ChatView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildTypingIndicator(),
          _buildInputBar(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xffFDF2FA),
      titleSpacing: 0,
      leading: IconButton(
        onPressed: () => Get.back(),
        icon: const Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
      ),
      title: Obx(
        () => Row(
          children: [
            // Profile avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xffFCE7F6),
              backgroundImage: controller.otherUser.value?.profileImage != null
                  ? NetworkImage(controller.otherUser.value!.profileImage!)
                  : null,
              child: controller.otherUser.value?.profileImage == null
                  ? Text(
                      controller.otherUser.value?.name.isNotEmpty == true
                          ? controller.otherUser.value!.name[0].toUpperCase()
                          : 'D',
                      style: GoogleFonts.roboto(
                        fontWeight: FontWeight.w600,
                        color: const Color(0xff851653),
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  controller.otherUser.value?.name ?? 'Chat with Dietician',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                    color: const Color(0xff1F2A37),
                  ),
                ),
                if (controller.otherUser.value?.isOnline == true)
                  Text(
                    'Online',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          onPressed: () => _showAttachmentOptions(),
          icon: const Icon(Icons.attach_file, color: Color(0xff4D5761)),
        ),
        IconButton(
          onPressed: () => _showOptions(),
          icon: const Icon(Icons.more_vert_rounded, color: Color(0xff4D5761)),
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return Obx(() {
      if (controller.isLoading.value && controller.messages.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xff851653)),
        );
      }

      if (controller.messages.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.chat_bubble_outline,
                size: 80,
                color: Colors.grey[300],
              ),
              const SizedBox(height: 16),
              Text(
                'No messages yet',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.grey[500],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Start a conversation with your dietician',
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        controller: controller.scrollController,
        reverse: true,
        // Large cacheExtent keeps most messages built (not just the ones
        // currently on screen) so Scrollable.ensureVisible can find a
        // tapped reply's target even if it has scrolled out of view.
        cacheExtent: 5000,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: controller.messages.length,
        itemBuilder: (context, index) {
          final message = controller.messages[index];
          final showDateSeparator = controller.shouldShowDateSeparator(index);

          return Column(
            key: controller.keyFor(message.id),
            children: [
              if (showDateSeparator) _buildDateSeparator(message.createdAt),
              Dismissible(
                key: ValueKey(message.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  controller.setReply(message);
                  return false;
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.reply, color: Color(0xff851653)),
                ),
                child: _buildMessageItem(message),
              ),
            ],
          );
        },
      );
    });
  }

  Widget _buildDateSeparator(DateTime date) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xffF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            controller.getDateSeparatorText(date),
            style: GoogleFonts.roboto(
              fontSize: 12,
              color: const Color(0xff6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageItem(MessageModel message) {
    // Handle different message types
    switch (message.messageType) {
      case MessageType.mealLog:
      case MessageType.dietUpdate:
        return MealLogMessage(message: message);
      case MessageType.waterIntake:
        return WaterIntakeMessage(message: message);
      case MessageType.dietPlan:
        return DietPlanMessage(message: message);
      case MessageType.customFood:
        return CustomFoodMessage(message: message);
      case MessageType.doctorNote:
        return DoctorNoteMessage(message: message);
      case MessageType.image:
        return Obx(
          () => MessageBubble(
            message: message,
            isImage: true,
            onReply: () => controller.setReply(message),
            onReplyPreviewTap: () =>
                controller.scrollToMessage(message.replyTo?.id),
            isHighlighted: controller.highlightedMessageId.value == message.id,
          ),
        );
      default:
        return Obx(
          () => MessageBubble(
            message: message,
            onReply: () => controller.setReply(message),
            onReplyPreviewTap: () =>
                controller.scrollToMessage(message.replyTo?.id),
            isHighlighted: controller.highlightedMessageId.value == message.id,
          ),
        );
    }
  }

  Widget _buildTypingIndicator() {
    return Obx(() {
      if (!controller.isTyping.value) return const SizedBox.shrink();

      final avatarInitial = controller.otherUser.value?.name.isNotEmpty == true
          ? controller.otherUser.value!.name[0].toUpperCase()
          : 'D';

      return TypingIndicator(
        avatarInitial: avatarInitial,
        dotColor: const Color(0xff851653),
      );
    });
  }

  Widget _buildInputBar() {
    return Container(
      color: const Color(0xffFDF2FA),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 14),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Reply preview
            Obx(() {
              final reply = controller.replyingTo;
              if (reply == null) return const SizedBox.shrink();
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xffFCE7F6),
                  borderRadius: BorderRadius.circular(12),
                  border: const Border(
                    left: BorderSide(color: Color(0xff851653), width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            reply.senderId == userId ? 'You' : 'Dietician',
                            style: GoogleFonts.roboto(
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                              color: const Color(0xff851653),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            reply.messageType == MessageType.image
                                ? '📷 Photo'
                                : reply.content,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.roboto(
                              fontSize: 13,
                              color: const Color(0xff6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: controller.clearReply,
                      child: const Icon(Icons.close, size: 18, color: Color(0xff6B7280)),
                    ),
                  ],
                ),
              );
            }),
            Row(
          children: [
            // Plus Icon for attachments
            GestureDetector(
              onTap: () => _showAttachmentOptions(),
              child: const Icon(
                Icons.add_circle_outline,
                color: Color(0xff4D5761),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Emoji Icon
            GestureDetector(
              onTap: () {
                // TODO: Implement emoji picker
              },
              child: const Icon(
                Icons.emoji_emotions_outlined,
                color: Color(0xff4D5761),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Input field container
            Expanded(
              child: Container(
                constraints: const BoxConstraints(
                  minHeight: 44,
                  maxHeight: 120,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xffFCE7F6),
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: controller.messageController,
                  focusNode: controller.focusNode,
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onChanged: controller.onTextChanged,
                  onSubmitted: (_) => controller.sendMessage(),
                  style: GoogleFonts.roboto(fontSize: 16),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: "Type a message",
                    hintStyle: GoogleFonts.roboto(
                      fontSize: 16,
                      color: const Color(0xff6B7280),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Mic / Send button - OUTSIDE the text input container
            Obx(() {
              final hasTextValue = controller.hasText.value;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  debugPrint('🔘 Send button tapped! hasText: $hasTextValue');
                  if (hasTextValue) {
                    controller.sendMessage();
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: hasTextValue
                        ? const Color(0xff851653)
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    hasTextValue ? Icons.send : Icons.mic,
                    color: hasTextValue
                        ? Colors.white
                        : const Color(0xff4D5761),
                    size: 24,
                  ),
                ),
              );
            }),
          ],
        ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Share',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildAttachmentOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  color: Colors.pink,
                  onTap: () => _pickImage(ImageSource.camera),
                ),
                _buildAttachmentOption(
                  icon: Icons.photo,
                  label: 'Gallery',
                  color: Colors.purple,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
                _buildAttachmentOption(
                  icon: Icons.restaurant_menu,
                  label: 'Meal Note',
                  color: const Color(0xff851653),
                  onTap: () {
                    Get.back();
                    _showMealNoteDialog();
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: GoogleFonts.roboto(fontSize: 12)),
        ],
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    Get.back();
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);

    if (pickedFile != null) {
      
      final captionController = TextEditingController();
      
      await Get.bottomSheet(
        isScrollControlled: true,
        Container(
          height: Get.height * 0.8,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Get.back()),
                    Text('Send Photo', style: GoogleFonts.roboto(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 48), // balance
                  ],
                ),
              ),
              Expanded(
                // Use MemoryImage if dart:io is unavailable to avoid import issues
                child: FutureBuilder<Uint8List>(
                  future: pickedFile.readAsBytes(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return Image.memory(snapshot.data!, fit: BoxFit.contain);
                    }
                    return const Center(child: CircularProgressIndicator());
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(Get.context!).viewInsets.bottom + 16,
                  left: 16,
                  right: 16,
                  top: 16,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: captionController,
                        decoration: InputDecoration(
                          hintText: 'Add a caption...',
                          filled: true,
                          fillColor: const Color(0xffF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    CircleAvatar(
                      backgroundColor: const Color(0xff851653),
                      radius: 24,
                      child: IconButton(
                        icon: const Icon(Icons.send, color: Colors.white, size: 20),
                        onPressed: () {
                          Get.back(result: true);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).then((send) {
        if (send == true) {
          controller.sendImageMessage(pickedFile);
          if (captionController.text.trim().isNotEmpty) {
            // Send the caption as a text message right after
            controller.messageController.text = captionController.text.trim();
            controller.sendMessage();
          }
        }
      });
    }
  }

  void _showMealNoteDialog() {
    final TextEditingController descriptionController = TextEditingController();
    XFile? selectedImageFile;
    Uint8List? selectedImageBytes;

    Get.dialog(
      StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Share Meal Note'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final source = await Get.bottomSheet<ImageSource>(
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(
                                  Icons.camera_alt,
                                  color: Color(0xff851653),
                                ),
                                title: Text(
                                  'Camera',
                                  style: GoogleFonts.roboto(),
                                ),
                                onTap: () =>
                                    Get.back(result: ImageSource.camera),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.photo_library,
                                  color: Color(0xff851653),
                                ),
                                title: Text(
                                  'Gallery',
                                  style: GoogleFonts.roboto(),
                                ),
                                onTap: () =>
                                    Get.back(result: ImageSource.gallery),
                              ),
                            ],
                          ),
                        ),
                      );
                      if (source != null) {
                        final pickedFile = await picker.pickImage(
                          source: source,
                        );
                        if (pickedFile != null) {
                          final bytes = await pickedFile.readAsBytes();
                          setState(() {
                            selectedImageFile = pickedFile;
                            selectedImageBytes = bytes;
                          });
                        }
                      }
                    },
                    child: Container(
                      height: 160,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xffFCE7F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xff851653).withOpacity(0.3),
                        ),
                      ),
                      child: selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(
                                selectedImageBytes!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image,
                                        size: 40,
                                        color: Color(0xff851653),
                                      ),
                                      SizedBox(height: 8),
                                      Text('Image selected'),
                                    ],
                                  );
                                },
                              ),
                            )
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.add_a_photo,
                                  size: 40,
                                  color: Color(0xff851653),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add Photo of Your Meal',
                                  style: GoogleFonts.roboto(
                                    color: const Color(0xff851653),
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'Describe your meal (what you ate, portion size, etc.)',
                      hintStyle: GoogleFonts.roboto(color: Colors.grey),
                      filled: true,
                      fillColor: const Color(0xffFCE7F6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                          color: Color(0xff851653),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Get.back(),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed:
                    (selectedImageFile != null &&
                        descriptionController.text.trim().isNotEmpty)
                    ? () {
                        Get.back();
                        controller.sendMealNote(
                          imageFile: selectedImageFile,
                          description: descriptionController.text.trim(),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff530630),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text('Share'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showOptions() {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.search),
              title: Text('Search in chat', style: GoogleFonts.roboto()),
              onTap: () {
                Get.back();
                // TODO: Implement search
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper),
              title: Text('Wallpaper', style: GoogleFonts.roboto()),
              onTap: () {
                Get.back();
                // TODO: Implement wallpaper
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: Text('Mute notifications', style: GoogleFonts.roboto()),
              onTap: () {
                Get.back();
                // TODO: Implement mute
              },
            ),
          ],
        ),
      ),
    );
  }
}
