import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActivityReportScreen extends StatefulWidget {
  const ActivityReportScreen({super.key});

  @override
  State<ActivityReportScreen> createState() => _ActivityReportScreenState();
}

class _ActivityReportScreenState extends State<ActivityReportScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _activities = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _fetchActivityReport();
  }

  Future<void> _fetchActivityReport() async {
    setState(() => _isLoading = true);
    try {
      final response = await supabase
          .from('curriculum_activities')
          .select('''
            id,
            name,
            category,
            hours,
            curriculum_claims!activity_id (
              status,
              profile_id,
              created_at
            )
          ''')
          .eq('is_active', true);

      final List<Map<String, dynamic>> activitiesWithStats = [];
      
      for (var activity in response as List) {
        final claims = activity['curriculum_claims'] as List? ?? [];
        
        final totalClaims = claims.length;
        final approvedClaims = claims.where((c) => c['status'] == 'approved').length;
        final pendingClaims = claims.where((c) => c['status'] == 'pending').length;
        final rejectedClaims = claims.where((c) => c['status'] == 'rejected').length;
        
        // Get unique participants
        final uniqueParticipants = claims.map((c) => c['profile_id']).toSet().length;
        
        activitiesWithStats.add({
          'id': activity['id'],
          'name': activity['name'] ?? 'Unknown',
          'category': activity['category'] ?? 'General',
          'hours': activity['hours'] ?? 0,
          'totalClaims': totalClaims,
          'approvedClaims': approvedClaims,
          'pendingClaims': pendingClaims,
          'rejectedClaims': rejectedClaims,
          'participants': uniqueParticipants,
          'approvalRate': totalClaims > 0 ? (approvedClaims / totalClaims * 100).toStringAsFixed(1) : '0',
        });
      }
      
      setState(() {
        _activities = activitiesWithStats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching activity report: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load report: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredActivities {
    var filtered = _activities;
    
    if (_selectedCategory != 'all') {
      filtered = filtered.where((a) => a['category'] == _selectedCategory).toList();
    }
    
    return filtered;
  }

  List<String> get _categories {
    final categories = _activities.map((a) => a['category'] as String).toSet().toList();
    return ['all', ...categories];
  }

  int get _totalParticipants {
    return _activities.fold(0, (sum, a) => sum + (a['participants'] as int));
  }

  int get _totalClaims {
    return _activities.fold(0, (sum, a) => sum + (a['totalClaims'] as int));
  }

  int get _totalApproved {
    return _activities.fold(0, (sum, a) => sum + (a['approvedClaims'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Activity Report'),
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchActivityReport,
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () {
              // TODO: Export report as PDF/Excel
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Export feature coming soon'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Summary Cards
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Activities',
                          value: _activities.length.toString(),
                          icon: Icons.emoji_events,
                          color: const Color(0xFF00838F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Participants',
                          value: _totalParticipants.toString(),
                          icon: Icons.people,
                          color: const Color(0xFF2ECC71),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Claims',
                          value: _totalClaims.toString(),
                          icon: Icons.assignment,
                          color: const Color(0xFFF39C12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category == 'all' ? 'All Categories' : category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory = category;
                              });
                            },
                            selectedColor: const Color(0xFF00838F),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Activities List
                Expanded(
                  child: _filteredActivities.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.emoji_events_outlined, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No activities found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredActivities.length,
                          itemBuilder: (context, index) {
                            final activity = _filteredActivities[index];
                            return _buildActivityCard(activity);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    final approvalRate = double.tryParse(activity['approvalRate']) ?? 0;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00838F).withValues(alpha: 0.1),
          child: Text(
            activity['hours'].toString(),
            style: const TextStyle(
              color: Color(0xFF00838F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          activity['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00838F).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                activity['category'],
                style: const TextStyle(fontSize: 10, color: Color(0xFF00838F)),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${activity['hours']} hours • ${activity['participants']} participants',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${activity['approvalRate']}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: approvalRate >= 70 ? Colors.green : Colors.orange,
              ),
            ),
            const Text(
              'approval rate',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Approval rate progress
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Approval Rate:'),
                          const SizedBox(height: 4),
                          LinearProgressIndicator(
                            value: approvalRate / 100,
                            backgroundColor: Colors.grey[200],
                            color: approvalRate >= 70 ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${activity['approvalRate']}% approved',
                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                
                // Claims Statistics
                Row(
                  children: [
                    _buildStatItem(
                      'Total Claims',
                      activity['totalClaims'].toString(),
                      Icons.assignment,
                      Colors.blue,
                    ),
                    _buildStatItem(
                      'Approved',
                      activity['approvedClaims'].toString(),
                      Icons.check_circle,
                      Colors.green,
                    ),
                    _buildStatItem(
                      'Pending',
                      activity['pendingClaims'].toString(),
                      Icons.hourglass_empty,
                      Colors.orange,
                    ),
                    _buildStatItem(
                      'Rejected',
                      activity['rejectedClaims'].toString(),
                      Icons.cancel,
                      Colors.red,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}