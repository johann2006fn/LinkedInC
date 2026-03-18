import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/app_user.dart';
import '../theme/antigravity_theme.dart';
import '../widgets/user_avatar.dart';

class SearchMentorsScreen extends ConsumerStatefulWidget {
  const SearchMentorsScreen({super.key});

  @override
  ConsumerState<SearchMentorsScreen> createState() =>
      _SearchMentorsScreenState();
}

class _SearchMentorsScreenState extends ConsumerState<SearchMentorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';

  final List<String> _popularTopics = [
    'Flutter',
    'Python',
    'Data Structures',
    'Career Advice',
    'Resume',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _onTopicTap(String topic) {
    _searchController.text = topic;
    setState(() {
      _searchQuery = topic.toLowerCase();
    });
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final mentorsAsync = ref.watch(topMentorsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0D0B14),
      appBar: AppBar(
        titleSpacing: 0,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1527),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
            child: TextField(
              controller: _searchController,
              focusNode: _searchFocus,
              decoration: InputDecoration(
                icon: const Icon(
                  Icons.search,
                  color: AntigravityTheme.electricPurple,
                ),
                hintText: 'Search mentors, skills or branches',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(
                          Icons.close,
                          color: Colors.white54,
                          size: 20,
                        ),
                        onPressed: () {
                          _searchController.clear();
                          _searchFocus.requestFocus();
                        },
                      )
                    : null,
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: _searchQuery.isEmpty
            ? _buildDiscoveryState()
            : _buildSearchResults(mentorsAsync),
      ),
    );
  }

  Widget _buildDiscoveryState() {
    return ListView(
      padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
      children: [
        const Text(
          'Popular Topics',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: _popularTopics.map((topic) {
            return ActionChip(
              onPressed: () => _onTopicTap(topic),
              backgroundColor: const Color(0xFF1A1527),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              label: Text(
                topic,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSearchResults(AsyncValue<List<AppUser>> mentorsAsync) {
    return mentorsAsync.when(
      data: (mentors) {
        final results = mentors.where((m) {
          final query = _searchQuery.toLowerCase();
          final nameMatch = m.name.toLowerCase().contains(query);
          final roleMatch =
              (m.subtitle ?? '').toLowerCase().contains(query) ||
              m.role.toLowerCase().contains(query);
          final departmentMatch = (m.department ?? '').toLowerCase().contains(
            query,
          );
          final tagsMatch = m.tags.any(
            (tag) => tag.toLowerCase().contains(query),
          );
          return nameMatch || roleMatch || departmentMatch || tagsMatch;
        }).toList();

        if (results.isEmpty) {
          return const Center(
            child: Text(
              'No mentors found matching your query.',
              style: TextStyle(color: Colors.white54),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 120,
          ),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final mentor = results[index];
            return _buildSearchResultCard(mentor);
          },
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(
          color: AntigravityTheme.electricPurple,
        ),
      ),
      error: (e, st) => Center(
        child: Text(
          'Error loading mentors: $e',
          style: const TextStyle(color: Colors.red),
        ),
      ),
    );
  }

  Widget _buildSearchResultCard(AppUser mentor) {
    final topTags = mentor.tags.take(2).join(' • ');
    final subtitleText = [
      if (mentor.subtitle?.isNotEmpty == true) mentor.subtitle!,
      if (topTags.isNotEmpty) topTags,
    ].join(' | ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1527),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => context.push('/mentor-detail', extra: mentor),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: UserAvatar(user: mentor, radius: 24),
              title: Text(
                mentor.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  subtitleText.isNotEmpty ? subtitleText : 'Mentor',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              trailing: const Icon(Icons.chevron_right, color: Colors.white54),
            ),
          ),
        ),
      ),
    );
  }
}
