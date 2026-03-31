import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:careeriq/providers/auth_provider.dart';
import 'package:careeriq/providers/chat_provider.dart';
import 'package:careeriq/models/chat.dart';
import 'package:intl/intl.dart';
import '../chat/chat_view_screen.dart';
import '../../core/theme.dart';

class SmartInboxScreen extends StatefulWidget {
  const SmartInboxScreen({super.key});

  @override
  State<SmartInboxScreen> createState() => _SmartInboxScreenState();
}

class _SmartInboxScreenState extends State<SmartInboxScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Action Required', 'Unread'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);
    final theme = Theme.of(context);

    if (auth.userId == null) {
      return const Scaffold(body: Center(child: Text('Please login to view inbox')));
    }

    return Scaffold(
      backgroundColor: AppTheme.getScaffoldColor(context),
      body: Stack(
        children: [
          // Background Decor
          Positioned(
            top: -100,
            right: -50,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primaryBlue.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                _buildSearchBar(context),
                _buildTabs(context),
                Expanded(
                  child: StreamBuilder<List<ChatRoom>>(
                    stream: Provider.of<ChatProvider>(context, listen: false).getChatRooms(auth.userId!),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return _buildEmptyState(context);
                      }

                      final rooms = _filterRooms(snapshot.data!);
                      
                      if (rooms.isEmpty) {
                        return const Center(child: Text('No messages matching this filter.'));
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: rooms.length,
                        itemBuilder: (context, index) {
                          return _buildChatTile(context, rooms[index], auth.userId!);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primaryBlue, size: 20),
              ),
              const SizedBox(width: 12),
              const Text(
                'SMART INBOX',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: AppTheme.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Recruiter Messages',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getGlassColor(context).withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.getGlassBorderColor(context)),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() {}),
          decoration: InputDecoration(
            hintText: 'Search applicants or jobs...',
            hintStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          ),
        ),
      ),
    );
  }

  Widget _buildTabs(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: TabBar(
        controller: _tabController,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.label,
        tabAlignment: TabAlignment.start,
        isScrollable: true,
        labelPadding: const EdgeInsets.only(right: 20),
        indicator: UnderlineTabIndicator(
          borderSide: BorderSide(width: 3.5, color: theme.colorScheme.primary),
          borderRadius: BorderRadius.circular(2),
          insets: const EdgeInsets.only(right: 20, bottom: -2),
        ),
        labelStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        onTap: (_) => setState(() {}),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  List<ChatRoom> _filterRooms(List<ChatRoom> rooms) {
    final query = _searchController.text.toLowerCase();
    var filtered = rooms;

    if (query.isNotEmpty) {
      filtered = filtered.where((r) => 
        (r.companyName ?? '').toLowerCase().contains(query) || 
        r.lastMessage.toLowerCase().contains(query)
      ).toList();
    }

    final tab = _tabs[_tabController.index];
    if (tab == 'Action Required') {
      // Mock logic: messages from others that are not read
      // In a real app we'd have a 'needsAction' boolean or similar
      return filtered.take(1).toList(); // Just for demo
    } else if (tab == 'Unread') {
      return filtered.where((r) => r.lastMessage.contains('?')).toList(); // Mock
    }

    return filtered;
  }

  Widget _buildChatTile(BuildContext context, ChatRoom room, String currentUserId) {
    final theme = Theme.of(context);
    
    // Mocking some 'smart' tags
    final bool isHighlyRelevant = room.lastMessage.contains('call') || room.lastMessage.contains('interview');

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.getGlassColor(context).withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppTheme.getGlassBorderColor(context),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
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
            leading: Stack(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person_rounded, color: Colors.blue, size: 28),
                ),
                if (isHighlyRelevant)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    room.companyName ?? 'Applicant',
                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16),
                  ),
                ),
                Text(
                  DateFormat('hh:mm a').format(room.lastMessageTime),
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  room.lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
                if (isHighlyRelevant) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      '✨ Suggested Action: Schedule Interview',
                      style: TextStyle(
                        color: Colors.blue,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ]
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

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: AppTheme.primaryBlue.withValues(alpha: 0.05),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.forum_outlined,
              size: 80,
              color: AppTheme.primaryBlue.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your conversations with job applicants will appear here after you message them from the ATS.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
