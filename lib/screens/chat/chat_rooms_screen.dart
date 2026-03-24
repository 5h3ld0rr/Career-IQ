import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/providers/chat_provider.dart';
import 'package:careeriq/models/chat.dart';
import 'package:intl/intl.dart';
import 'chat_view_screen.dart';

class ChatRoomsScreen extends StatelessWidget {
  const ChatRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    if (auth.userId == null) {
      return const Scaffold(body: Center(child: Text('Please login to chat')));
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text(
          'Messages',
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Stack(
        children: [
          _buildBackgroundDecor(),
          StreamBuilder<List<ChatRoom>>(
            stream: Provider.of<ChatProvider>(context, listen: false)
                .getChatRooms(auth.userId!),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return _buildEmptyState(context);
              }

              final rooms = snapshot.data!;
              return ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                itemCount: rooms.length,
                itemBuilder: (context, index) {
                  return _buildChatTile(context, rooms[index], auth.userId!);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline_rounded,
            size: 100,
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Start a conversation with recruiters\nfrom the job details page.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.black38,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 32),
          _buildSeedButton(context),
        ],
      ),
    );
  }

  Widget _buildSeedButton(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    return OutlinedButton.icon(
      onPressed: () {
        Provider.of<ChatProvider>(context, listen: false).seedChatRooms(auth.userId!);
      },
      icon: const Icon(Icons.auto_awesome),
      label: const Text('GENERATE TEST CHAT'),
    );
  }

  Widget _buildChatTile(BuildContext context, ChatRoom room, String currentUserId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              backgroundImage: room.companyLogo != null
                  ? NetworkImage(room.companyLogo!)
                  : null,
              child: room.companyLogo == null
                  ? const Icon(Icons.business_rounded, color: Colors.blue)
                  : null,
            ),
            title: Text(
              room.companyName ?? 'Recruiter',
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                room.lastMessage,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.black54,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormat('hh:mm a').format(room.lastMessageTime),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.black38,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                // Unread indicator could be here
              ],
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatViewScreen(chatRoomId: room.id, room: room),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBackgroundDecor() {
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              const Color(0xFF81D4FA).withValues(alpha: 0.2),
              Colors.transparent,
            ],
          ),
        ),
      ),
    );
  }
}
