import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/app_providers.dart';
import '../models/app_user.dart';
import '../theme/antigravity_theme.dart';

class SearchMentorsScreen extends ConsumerStatefulWidget {
  const SearchMentorsScreen({super.key});

  @override
  ConsumerState<SearchMentorsScreen> createState() => _SearchMentorsScreenState();
}

class _SearchMentorsScreenState extends ConsumerState<SearchMentorsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode();
  String _searchQuery = '';
  
  final List<String> _trendingTopics = [
    'Interview Tips',
    'UI/UX',
    'Flutter',
    'System Design',
    'Career Switch'
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
                icon: const Icon(Icons.search, color: AntigravityTheme.electricPurple),
                hintText: 'Search mentors, skills or branches',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54, size: 20),
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
        child: _searchQuery.isEmpty ? _buildTrendingState() : _buildSearchResults(mentorsAsync),
      ),
    );
  }

  Widget _buildTrendingState() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const Text(
          'Trending Topics',
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
          children: _trendingTopics.map((topic) {
            return GestureDetector(
              onTap: () => _onTopicTap(topic),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1527),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.trending_up, color: AntigravityTheme.electricPurple, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      topic,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                  ],
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
          final text = '${m.name} ${m.subtitle} ${m.bio} ${m.tags?.join(' ')}'.toLowerCase();
          return text.contains(_searchQuery);
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
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final mentor = results[index];
            return _buildSearchResultCard(mentor);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator(color: AntigravityTheme.electricPurple)),
      error: (e, st) => Center(child: Text('Error loading mentors: $e', style: const TextStyle(color: Colors.red))),
    );
  }

  Widget _buildSearchResultCard(AppUser mentor) {
    return GestureDetector(
      onTap: () => context.push('/mentor-detail', extra: mentor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1527),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xFF2A2537),
              backgroundImage: mentor.profileImageUrl != null && mentor.profileImageUrl!.isNotEmpty
                  ? NetworkImage(mentor.profileImageUrl!)
                  : null,
              child: mentor.profileImageUrl == null || mentor.profileImageUrl!.isEmpty
                  ? Text(
                      mentor.name.isNotEmpty ? mentor.name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mentor.name,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mentor.subtitle ?? 'Mentor',
                    style: const TextStyle(color: AntigravityTheme.electricPurple, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    mentor.bio ?? 'This mentor is ready to help you achieve your goals.',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
