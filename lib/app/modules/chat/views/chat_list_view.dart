import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:get/get.dart';
import '../controllers/chat_list_controller.dart';
import 'widgets/conversation_tile.dart';

class ChatListView extends GetView<ChatListController> {
  const ChatListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildConversationList()),
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
      title: Text(
        'Chat list',
        style: GoogleFonts.roboto(
          fontWeight: FontWeight.w500,
          fontSize: 18,
          color: const Color(0xff1F2A37),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: controller.searchController,
        onChanged: controller.onSearchChanged,
        decoration: InputDecoration(
          hintText: 'Search',
          hintStyle: GoogleFonts.roboto(
            color: const Color(0xff851653),
            fontSize: 16,
          ),
          prefixIcon: const Icon(
            Icons.search,
            color: Color(0xff851653),
          ),
          filled: true,
          fillColor: const Color(0xffFDF2FA),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildConversationList() {
    return Obx(() {
      if (controller.isLoading.value && controller.conversations.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(color: Color(0xff851653)),
        );
      }

      if (controller.filteredConversations.isEmpty) {
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
                'No conversations yet',
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        );
      }

      return RefreshIndicator(
        onRefresh: controller.fetchConversations,
        color: const Color(0xff851653),
        child: ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: controller.filteredConversations.length,
          itemBuilder: (context, index) {
            final conversation = controller.filteredConversations[index];
            return ConversationTile(
              conversation: conversation,
              onTap: () => controller.openChat(conversation),
            );
          },
        ),
      );
    });
  }
}
