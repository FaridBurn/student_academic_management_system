import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ClaimHistoryScreen extends StatefulWidget {
  const ClaimHistoryScreen({super.key});

  @override
  State<ClaimHistoryScreen> createState() => _ClaimHistoryScreenState();
}

class _ClaimHistoryScreenState extends State<ClaimHistoryScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _history = [];
  bool _isLoading = true;
  String _filterStatus = 'all';

  int get _totalHours {
    return _history
        .where((c) => c['status'] == 'approved')
        .fold(0, (sum, c) {
      final activity = c['curriculum_activities'] as Map<String, dynamic>?;
      return sum + ((activity?['hours'] as int?) ?? 0);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final response = await supabase
          .from('curriculum_claims')
          .select('*, curriculum_activities(name, category, hours)')
          .eq('profile_id', userId) // 👈 fixed here
          .order('claimed_at', ascending: false);

      setState(() {
        _history = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load history: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterStatus == 'all') return _history;
    return _history.where((c) => c['status'] == _filterStatus).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved': return const Color(0xFF2ECC71);
      case 'rejected': return Colors.redAccent;
      default:         return const Color(0xFFF39C12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSummaryCard(),
                _buildFilterTabs(),
                Expanded(
                  child: _filtered.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: _fetchHistory,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) =>
                                _buildHistoryCard(_filtered[i]),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard() {
    final approved = _history.where((c) => c['status'] == 'approved').length;
    final pending  = _history.where((c) => c['status'] == 'pending').length;
    final rejected = _history.where((c) => c['status'] == 'rejected').length;

    return Container(
      color: const Color(0xFF00838F),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      child: Row(
        children: [
          _SummaryTile(label: 'Total Hours', value: '$_totalHours', icon: Icons.stars),
          _SummaryTile(label: 'Approved',    value: '$approved',    icon: Icons.check_circle),
          _SummaryTile(label: 'Pending',     value: '$pending',     icon: Icons.hourglass_empty),
          _SummaryTile(label: 'Rejected',    value: '$rejected',    icon: Icons.cancel),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['all', 'approved', 'pending', 'rejected'];
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: tabs.map((t) => GestureDetector(
          onTap: () => setState(() => _filterStatus = t),
          child: Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _filterStatus == t
                  ? const Color(0xFF00838F)
                  : const Color(0xFFF4F6FA),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              t[0].toUpperCase() + t.substring(1),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _filterStatus == t ? Colors.white : Colors.grey[600],
              ),
            ),
          ),
        )).toList(),
      ),
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> claim) {
    final activity  = claim['curriculum_activities'] as Map<String, dynamic>?;
    final status    = claim['status'] as String? ?? 'pending';
    final claimedAt = DateTime.tryParse(claim['claimed_at'] ?? '');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: _statusColor(status).withValues(alpha: 0.12),
          child: Icon(
            status == 'approved'
                ? Icons.check
                : status == 'rejected'
                    ? Icons.close
                    : Icons.hourglass_empty,
            color: _statusColor(status),
          ),
        ),
        title: Text(
          activity?['name'] ?? 'Unknown Activity',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              '${activity?['hours'] ?? 0} hrs • ${activity?['category'] ?? '-'}',
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
            if (claimedAt != null)
              Text(
                '${claimedAt.day}/${claimedAt.month}/${claimedAt.year}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            status.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: _statusColor(status)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('No history found',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// ─── Summary Tile ─────────────────────────────────────────────────────────────

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _SummaryTile(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(color: Colors.white60, fontSize: 10),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}