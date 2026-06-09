import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityVerificationScreen extends StatefulWidget {
  const ActivityVerificationScreen({super.key});

  @override
  State<ActivityVerificationScreen> createState() =>
      _ActivityVerificationScreenState();
}

class _ActivityVerificationScreenState
    extends State<ActivityVerificationScreen> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _claims = [];
  bool _isLoading = true;
  String _filterStatus = 'pending';

  @override
  void initState() {
    super.initState();
    _fetchClaims();
  }

  Future<void> _fetchClaims() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('curriculum_claims')
          .select('*, curriculum_activities(name, category, hours), profiles(name, student_id)')
          .order('claimed_at', ascending: false);

      setState(() {
        _claims = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load claims: $e')),
        );
      }
    }
  }

  Future<void> _updateStatus(String claimId, String newStatus) async {
    try {
      await supabase
          .from('curriculum_claims')
          .update({'status': newStatus})
          .eq('id', claimId);

      await _fetchClaims();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Claim $newStatus successfully'),
            backgroundColor: newStatus == 'approved'
                ? const Color(0xFF2ECC71)
                : Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update: $e')),
        );
      }
    }
  }

  void _showConfirmDialog(String claimId, String action) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          '${action == 'approved' ? 'Approve' : 'Reject'} Claim',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to ${action == 'approved' ? 'approve' : 'reject'} this claim?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _updateStatus(claimId, action);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approved'
                  ? const Color(0xFF2ECC71)
                  : Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: Text(action == 'approved' ? 'Approve' : 'Reject'),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filterStatus == 'all') return _claims;
    return _claims.where((c) => c['status'] == _filterStatus).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return const Color(0xFF2ECC71);
      case 'rejected':
        return Colors.redAccent;
      default:
        return const Color(0xFFF39C12);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A5F),
        foregroundColor: Colors.white,
        title: const Text(
          'Activity Verification',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchClaims,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterTabs(),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchClaims,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) =>
                              _buildClaimCard(_filtered[i]),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterTabs() {
    final tabs = ['pending', 'approved', 'rejected', 'all'];
    return Container(
      color: const Color(0xFF1E3A5F),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Row(
        children: tabs
            .map((t) => GestureDetector(
                  onTap: () => setState(() => _filterStatus = t),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: _filterStatus == t
                          ? Colors.white
                          : Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      t[0].toUpperCase() + t.substring(1),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _filterStatus == t
                            ? const Color(0xFF1E3A5F)
                            : Colors.white,
                      ),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _buildClaimCard(Map<String, dynamic> claim) {
    final activity = claim['curriculum_activities'] as Map<String, dynamic>?;
    final student = claim['profiles'] as Map<String, dynamic>?;
    final status = claim['status'] as String? ?? 'pending';
    final claimedAt = DateTime.tryParse(claim['claimed_at'] ?? '');
    final isPending = status == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    activity?['name'] ?? 'Unknown Activity',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.12),
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
              ],
            ),
            const SizedBox(height: 8),

            // Activity info
            Row(
              children: [
                Icon(Icons.access_time, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text('${activity?['hours'] ?? 0} hrs',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
                const SizedBox(width: 12),
                Icon(Icons.category, size: 13, color: Colors.grey[400]),
                const SizedBox(width: 4),
                Text(activity?['category'] ?? '-',
                    style:
                        TextStyle(fontSize: 12, color: Colors.grey[500])),
              ],
            ),
            const Divider(height: 20),

            // Student info
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 15, color: Color(0xFF1E3A5F)),
                const SizedBox(width: 6),
                Text(
                  student?['name'] ?? 'Unknown Student',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500),
                ),
                if (student?['student_id'] != null) ...[
                  const SizedBox(width: 8),
                  Text(
                    '(${student!['student_id']})',
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ],
            ),

            if (claimedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Submitted: ${claimedAt.day}/${claimedAt.month}/${claimedAt.year}',
                style: TextStyle(fontSize: 11, color: Colors.grey[400]),
              ),
            ],

            if (claim['remark'] != null &&
                (claim['remark'] as String).isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F6FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${claim['remark']}"',
                  style:
                      TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ),
            ],

            // Action buttons (only for pending)
            if (isPending) ...[
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _showConfirmDialog(claim['id'], 'rejected'),
                      icon: const Icon(Icons.close, size: 16),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showConfirmDialog(claim['id'], 'approved'),
                      icon: const Icon(Icons.check, size: 16),
                      label: const Text('Approve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2ECC71),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.verified_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No $_filterStatus claims',
            style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}