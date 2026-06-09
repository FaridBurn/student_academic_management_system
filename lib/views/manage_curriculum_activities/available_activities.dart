import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../models/curriculum.dart';
import '../student_dashboard.dart';
import 'claim_activity.dart';
import 'claim_status.dart';
import 'claim_history.dart';

// ─── Main Container with Bottom Nav ──────────────────────────────────────────

class CurriculumHomeScreen extends StatefulWidget {
  final String name;
  const CurriculumHomeScreen({super.key, required this.name});

  @override
  State<CurriculumHomeScreen> createState() => _CurriculumHomeScreenState();
}

class _CurriculumHomeScreenState extends State<CurriculumHomeScreen> {
  int _currentIndex = 1;

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      const SizedBox(),
      AvailableActivitiesScreen(name: widget.name),
      const ClaimHoursScreen(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) {
          if (i == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => StudentHome(name: widget.name),
              ),
            );
          } else {
            setState(() => _currentIndex = i);
          }
        },
        selectedItemColor: const Color(0xFF00838F),
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_outlined),
            activeIcon: Icon(Icons.emoji_events),
            label: 'Activities',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            activeIcon: Icon(Icons.assignment),
            label: 'Claim Hours',
          ),
        ],
      ),
    );
  }
}

// ─── Tab 1: Available Activities ─────────────────────────────────────────────

class AvailableActivitiesScreen extends StatefulWidget {
  final String name;
  const AvailableActivitiesScreen({super.key, required this.name});

  @override
  State<AvailableActivitiesScreen> createState() =>
      _AvailableActivitiesScreenState();
}

class _AvailableActivitiesScreenState
    extends State<AvailableActivitiesScreen> {
  final supabase = Supabase.instance.client;

  List<CurriculumActivityModel> _activities = [];
  List<CurriculumActivityModel> _filtered = [];
  Map<String, String> _activityStatuses = {}; // activityId → status
  bool _isLoading = true;
  String _searchQuery = '';
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _fetchAll();
  }

  Future<void> _fetchAll() async {
    await Future.wait([
      _fetchActivities(),
      _fetchMyStatuses(),
    ]);
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final response =
          await supabase.from('curriculum_activities').select();
      final list = (response as List)
          .map((e) => CurriculumActivityModel.fromMap(e))
          .toList();
      setState(() {
        _activities = list;
        _filtered = list;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load activities: $e')),
        );
      }
    }
  }

  // Fetch current student's claim statuses for all activities
  Future<void> _fetchMyStatuses() async {
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('curriculum_claims')
          .select('activity_id, status')
          .eq('profile_id', userId);

      final Map<String, String> statuses = {};
      for (final item in response as List) {
        statuses[item['activity_id']] = item['status'];
      }

      setState(() => _activityStatuses = statuses);
    } catch (e) {
      // silently fail
    }
  }

  void _applyFilter() {
    setState(() {
      _filtered = _activities.where((a) {
        final matchSearch = a.name
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
        final matchCategory =
            _selectedCategory == null || a.category == _selectedCategory;
        return matchSearch && matchCategory;
      }).toList();
    });
  }

  List<String> get _categories {
    return _activities
        .map((a) => a.category)
        .whereType<String>()
        .toSet()
        .toList();
  }

  void _showActivityDetail(CurriculumActivityModel activity) {
    final status = _activityStatuses[activity.id];
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityDetailSheet(
        activity: activity,
        status: status,
        onActionDone: _fetchAll, // refresh after join/claim
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchAll,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _ActivityCard(
                            activity: _filtered[i],
                            status: _activityStatuses[_filtered[i].id],
                            onTap: () =>
                                _showActivityDetail(_filtered[i]),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: const Color(0xFF00838F),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Co-Curriculum',
            style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold),
          ),
          const Text(
            'Semester 1 2025/2026',
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 14),
          // Search bar
          TextField(
            onChanged: (val) {
              _searchQuery = val;
              _applyFilter();
            },
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search activities...',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon:
                  const Icon(Icons.search, color: Colors.white70),
              filled: true,
              fillColor: Colors.white.withOpacity(0.15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 0),
            ),
          ),
          const SizedBox(height: 10),
          // Category filter chips
          if (_categories.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _FilterChip(
                    label: 'All',
                    selected: _selectedCategory == null,
                    onTap: () {
                      _selectedCategory = null;
                      _applyFilter();
                    },
                  ),
                  ..._categories.map((cat) => _FilterChip(
                        label: cat,
                        selected: _selectedCategory == cat,
                        onTap: () {
                          _selectedCategory = cat;
                          _applyFilter();
                        },
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No activities found',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text('Try adjusting your search or filter',
              style:
                  TextStyle(fontSize: 13, color: Colors.grey[400])),
        ],
      ),
    );
  }
}

// ─── Tab 2: Claim Hours ───────────────────────────────────────────────────────

class ClaimHoursScreen extends StatelessWidget {
  const ClaimHoursScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6FA),
        appBar: AppBar(
          backgroundColor: const Color(0xFF00838F),
          foregroundColor: Colors.white,
          automaticallyImplyLeading: false,
          title: const Text(
            'Claim Hours',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
          ),
          bottom: const TabBar(
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white60,
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'Status'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ClaimStatusScreen(),
            ClaimHistoryScreen(),
          ],
        ),
      ),
    );
  }
}

// ─── Activity Card ────────────────────────────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final CurriculumActivityModel activity;
  final String? status;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.activity,
    required this.onTap,
    this.status,
  });

  Color get _categoryColor {
    switch (activity.category?.toLowerCase()) {
      case 'sports':      return const Color(0xFF2ECC71);
      case 'community':   return const Color(0xFF3498DB);
      case 'arts':        return const Color(0xFFE67E22);
      case 'leadership':  return const Color(0xFF9B59B6);
      case 'academic':    return const Color(0xFF1565C0);
      case 'soft skills': return const Color(0xFF00838F);
      default:            return const Color(0xFF95A5A6);
    }
  }

  // Status badge config
  Color get _statusColor {
    switch (status) {
      case 'registered': return const Color(0xFF1565C0);
      case 'pending':    return const Color(0xFFF39C12);
      case 'approved':   return const Color(0xFF2ECC71);
      case 'rejected':   return Colors.redAccent;
      default:           return Colors.transparent;
    }
  }

  String get _statusLabel {
    switch (status) {
      case 'registered': return 'Joined';
      case 'pending':    return 'Pending';
      case 'approved':   return 'Approved';
      case 'rejected':   return 'Rejected';
      default:           return '';
    }
  }

  IconData get _statusIcon {
    switch (status) {
      case 'registered': return Icons.how_to_reg;
      case 'pending':    return Icons.hourglass_empty;
      case 'approved':   return Icons.check_circle;
      case 'rejected':   return Icons.cancel;
      default:           return Icons.circle;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          leading: CircleAvatar(
            backgroundColor: _categoryColor.withOpacity(0.15),
            child: Icon(Icons.school, color: _categoryColor),
          ),
          title: Text(activity.name,
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 15)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                if (activity.category != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _categoryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(activity.category!,
                        style: TextStyle(
                            fontSize: 11,
                            color: _categoryColor,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 8),
                ],
                Icon(Icons.access_time,
                    size: 13, color: Colors.grey[500]),
                const SizedBox(width: 3),
                Text('${activity.hours} hrs',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey[600])),
              ],
            ),
          ),
          // 👇 Show status badge or chevron
          trailing: status != null
              ? Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon,
                          size: 12, color: _statusColor),
                      const SizedBox(width: 4),
                      Text(_statusLabel,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _statusColor)),
                    ],
                  ),
                )
              : const Icon(Icons.chevron_right, color: Colors.grey),
        ),
      ),
    );
  }
}

// ─── Filter Chip ──────────────────────────────────────────────────────────────

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected
              ? Colors.white
              : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected
                ? const Color(0xFF00838F)
                : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ─── Activity Detail Bottom Sheet ─────────────────────────────────────────────

class _ActivityDetailSheet extends StatelessWidget {
  final CurriculumActivityModel activity;
  final String? status;
  final VoidCallback onActionDone;

  const _ActivityDetailSheet({
    required this.activity,
    required this.onActionDone,
    this.status,
  });

  Color get _categoryColor {
    switch (activity.category?.toLowerCase()) {
      case 'sports':      return const Color(0xFF2ECC71);
      case 'community':   return const Color(0xFF3498DB);
      case 'arts':        return const Color(0xFFE67E22);
      case 'leadership':  return const Color(0xFF9B59B6);
      case 'academic':    return const Color(0xFF1565C0);
      case 'soft skills': return const Color(0xFF00838F);
      default:            return const Color(0xFF95A5A6);
    }
  }

  // Button config based on status
  String get _buttonLabel {
    switch (status) {
      case 'registered': return 'Claim Hours';
      case 'pending':    return 'Pending Approval';
      case 'approved':   return 'Approved ✓';
      case 'rejected':   return 'Rejected';
      default:           return 'Join Activity';
    }
  }

  Color get _buttonColor {
    switch (status) {
      case 'registered': return const Color(0xFF1E3A5F);
      case 'pending':    return const Color(0xFFF39C12);
      case 'approved':   return const Color(0xFF2ECC71);
      case 'rejected':   return Colors.redAccent;
      default:           return const Color(0xFF00838F);
    }
  }

  bool get _buttonEnabled {
    // Only allow tap if not joined yet or already registered
    return status == null || status == 'registered';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          if (activity.category != null)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _categoryColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(activity.category!,
                  style: TextStyle(
                      color: _categoryColor,
                      fontWeight: FontWeight.w700,
                      fontSize: 12)),
            ),
          const SizedBox(height: 12),
          Text(activity.name,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          _DetailRow(
            icon: Icons.access_time,
            label: 'Credit Hours',
            value: '${activity.hours} hours',
          ),
          const SizedBox(height: 12),
          _DetailRow(
            icon: Icons.tag,
            label: 'Activity ID',
            value: activity.id,
          ),
          const SizedBox(height: 32),

          // Action button based on status
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _buttonEnabled
                  ? () {
                      Navigator.pop(context);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ClaimActivityScreen(
                            activity: activity,
                          ),
                        ),
                      ).then((_) => onActionDone());
                    }
                  : null,
              icon: Icon(
                status == null
                    ? Icons.how_to_reg
                    : status == 'registered'
                        ? Icons.send
                        : status == 'approved'
                            ? Icons.check_circle
                            : status == 'rejected'
                                ? Icons.cancel
                                : Icons.hourglass_empty,
              ),
              label: Text(_buttonLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: _buttonColor,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    _buttonColor.withOpacity(0.5),
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                textStyle: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Detail Row ───────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF00838F).withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
          ),
          child:
              Icon(icon, size: 18, color: const Color(0xFF00838F)),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[500])),
            Text(value,
                style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}