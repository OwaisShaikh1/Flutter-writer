import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../models/literature_item.dart';
import '../services/api_service.dart';
import '../widgets/search_bar.dart';
import '../widgets/filter_section.dart';
import '../widgets/literature_list.dart';
import 'introduction_page.dart';

class AuthorProfilePage extends StatefulWidget {
  final int authorId;
  final String authorName;

  const AuthorProfilePage({
    super.key,
    required this.authorId,
    required this.authorName,
  });

  @override
  State<AuthorProfilePage> createState() => _AuthorProfilePageState();
}

class _AuthorProfilePageState extends State<AuthorProfilePage> {
  final ApiService _apiService = ApiService();
  UserProfile? _profile;
  List<LiteratureItem> _allWorks = [];
  List<LiteratureItem> _filteredWorks = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    _fetchAuthorData();
  }

  Future<void> _fetchAuthorData() async {
    setState(() => _isLoading = true);
    try {
      final profile = await _apiService.fetchUserProfile(widget.authorId);
      final works = await _apiService.fetchUserItems(widget.authorId);
      
      if (mounted) {
        setState(() {
          _profile = profile;
          _allWorks = works;
          _filteredWorks = works;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load author profile: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredWorks = _allWorks.where((work) {
        final matchesSearch = work.title.toLowerCase().contains(_searchQuery.toLowerCase());
        final matchesFilter = _selectedFilter == 'All' || work.type == _selectedFilter;
        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  Future<void> _toggleFollow() async {
    if (_profile == null) return;
    
    try {
      final result = await _apiService.toggleFollow(widget.authorId);
      if (result != null && result['success'] == true) {
        setState(() {
          _profile = _profile!.copyWith(
            isFollowedByUser: result['followed'] ?? false,
            followers: result['followers'] ?? _profile!.followers,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update follow status: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        scrolledUnderElevation: 0,
        title: Text(
          (_profile?.name ?? widget.authorName).toUpperCase(),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchAuthorData,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildProfileHeader(),
                          const SizedBox(height: 32),
                          _buildProfileDescription(),
                          const SizedBox(height: 32),
                          _buildSectionHeader(context, 'Works'),
                          const SizedBox(height: 16),
                          LiteratureSearchBar(
                            onChanged: (value) {
                              _searchQuery = value;
                              _applyFilters();
                            },
                          ),
                          const SizedBox(height: 12),
                          FilterSection(
                            selected: _selectedFilter,
                            onSelect: (filter) {
                              _selectedFilter = filter;
                              _applyFilters();
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                  _filteredWorks.isEmpty
                      ? SliverFillRemaining(
                          hasScrollBody: false,
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(40.0),
                              child: Text(
                                _allWorks.isEmpty
                                    ? 'NO MANUSCRIPTS YET.'
                                    : 'NO MATCHING RESULTS.',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2),
                                ),
                              ),
                            ),
                          ),
                        )
                      : SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final item = _filteredWorks[index];
                                return _AuthorWorkCard(item: item);
                              },
                              childCount: _filteredWorks.length,
                            ),
                          ),
                        ),
                  const SliverToBoxAdapter(child: SizedBox(height: 48)),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Divider(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileHeader() {
    final displayName = _profile?.name ?? widget.authorName;
    final initials = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : '?';

    return Row(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initials,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 24),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                displayName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '@${_profile?.username ?? widget.authorName.toLowerCase().replaceAll(' ', '')}',
                style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  _buildStatItem('Works', _profile?.posts ?? _allWorks.length),
                  const SizedBox(width: 24),
                  _buildStatItem('Followers', _profile?.followers ?? 0),
                  const SizedBox(width: 24),
                  _buildStatItem('Following', _profile?.following ?? 0),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count.toString(),
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 15,
            fontFamily: 'monospace',
          ),
        ),
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
        ),
      ],
    );
  }

  Widget _buildProfileDescription() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildSectionHeader(context, 'About'),
            const SizedBox(width: 12),
            TextButton(
              onPressed: _toggleFollow,
              style: TextButton.styleFrom(
                backgroundColor: _profile?.isFollowedByUser == true
                    ? Colors.transparent
                    : Theme.of(context).colorScheme.primary,
                foregroundColor: _profile?.isFollowedByUser == true
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: _profile?.isFollowedByUser == true
                      ? BorderSide(color: Theme.of(context).colorScheme.primary.withOpacity(0.2))
                      : BorderSide.none,
                ),
              ),
              child: Text(
                _profile?.isFollowedByUser == true ? 'FOLLOWING' : 'FOLLOW',
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          _profile?.bio ?? 'Writer based in the digital realm.',
          style: TextStyle(
            fontSize: 15,
            height: 1.6,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
      ],
    );
  }
}

class _AuthorWorkCard extends StatelessWidget {
  final LiteratureItem item;

  const _AuthorWorkCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        final map = item.toMap();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => IntroductionPage(literatureItem: map),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.type.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _buildTinyStat(context, Icons.star_rounded, '${item.rating}'),
                          const SizedBox(width: 16),
                          _buildTinyStat(context, Icons.menu_book_rounded, '${item.chapters} chapters'),
                        ],
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 1,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ],
      ),
    );
  }

  Widget _buildTinyStat(BuildContext context, IconData icon, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.2)),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
          ),
        ),
      ],
    );
  }
}
