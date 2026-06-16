import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StudentCreditsScreen extends StatefulWidget {
  const StudentCreditsScreen({super.key});

  @override
  State<StudentCreditsScreen> createState() => _StudentCreditsScreenState();
}

class _StudentCreditsScreenState extends State<StudentCreditsScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _students = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _fetchStudentCredits();
  }

  Future<void> _fetchStudentCredits() async {
    setState(() => _isLoading = true);
    try {
      // Fetch all students with their approved claims
      final response = await supabase
          .from('profiles')
          .select('''
            id,
            name,
            email,
            programme,
            batch,
            curriculum_claims!profile_id (
              status,
              curriculum_activities!activity_id (
                hours
              )
            )
          ''')
          .eq('role', 'student');

      final List<Map<String, dynamic>> studentsWithCredits = [];
      
      for (var student in response as List) {
        int totalCredits = 0;
        final claims = student['curriculum_claims'] as List? ?? [];
        
        for (var claim in claims) {
          if (claim['status'] == 'approved') {
            final activity = claim['curriculum_activities'] as Map<String, dynamic>?;
            if (activity != null) {
              totalCredits += activity['hours'] as int? ?? 0;
            }
          }
        }
        
        studentsWithCredits.add({
          'id': student['id'],
          'name': student['name'] ?? 'Unknown',
          'email': student['email'] ?? '',
          'programme': student['programme'] ?? 'Not specified',
          'batch': student['batch'] ?? 'Not specified',
          'totalCredits': totalCredits,
          'claimsCount': claims.length,
          'approvedCount': claims.where((c) => c['status'] == 'approved').length,
        });
      }
      
      setState(() {
        _students = studentsWithCredits;
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching student credits: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load student credits: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filteredStudents {
    var filtered = _students;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((student) {
        return student['name'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student['email'].toLowerCase().contains(_searchQuery.toLowerCase()) ||
               student['programme'].toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }
    
    // Sort
    filtered.sort((a, b) {
      if (_sortBy == 'name') {
        return a['name'].compareTo(b['name']);
      } else if (_sortBy == 'credits') {
        return b['totalCredits'].compareTo(a['totalCredits']);
      } else if (_sortBy == 'programme') {
        return a['programme'].compareTo(b['programme']);
      }
      return 0;
    });
    
    return filtered;
  }

  int get _totalCreditsAllStudents {
    return _students.fold(0, (sum, student) => sum + (student['totalCredits'] as int));
  }

  double get _averageCredits {
    if (_students.isEmpty) return 0;
    return _totalCreditsAllStudents / _students.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FA),
      appBar: AppBar(
        title: const Text('Student Credits'),
        backgroundColor: const Color(0xFF00838F),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchStudentCredits,
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
                          title: 'Total Students',
                          value: _students.length.toString(),
                          icon: Icons.people,
                          color: const Color(0xFF00838F),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Total Credits',
                          value: _totalCreditsAllStudents.toString(),
                          icon: Icons.stars,
                          color: const Color(0xFF2ECC71),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'Average',
                          value: _averageCredits.toStringAsFixed(1),
                          icon: Icons.trending_up,
                          color: const Color(0xFFF39C12),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Search and Filter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          onChanged: (value) {
                            setState(() => _searchQuery = value);
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name, email, or programme',
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: _sortBy,
                        items: const [
                          DropdownMenuItem(value: 'name', child: Text('Sort by Name')),
                          DropdownMenuItem(value: 'credits', child: Text('Sort by Credits')),
                          DropdownMenuItem(value: 'programme', child: Text('Sort by Programme')),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _sortBy = value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Student List
                Expanded(
                  child: _filteredStudents.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No students found',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredStudents.length,
                          itemBuilder: (context, index) {
                            final student = _filteredStudents[index];
                            return _buildStudentCard(student);
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

  Widget _buildStudentCard(Map<String, dynamic> student) {
    final progress = (student['totalCredits'] / 20).clamp(0.0, 1.0);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF00838F).withValues(alpha: 0.1),
          child: Text(
            student['name'][0].toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF00838F),
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          student['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(student['email'], style: TextStyle(fontSize: 12, color: Colors.grey[600])),
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00838F).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    student['programme'],
                    style: const TextStyle(fontSize: 10, color: Color(0xFF00838F)),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Batch ${student['batch']}',
                    style: TextStyle(fontSize: 10, color: Colors.orange[800]),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${student['totalCredits']}',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00838F),
              ),
            ),
            const Text(
              'credits',
              style: TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress bar
                const Text('Progress to 20 credits:'),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Colors.grey[200],
                  color: progress >= 1 ? Colors.green : const Color(0xFF00838F),
                ),
                const SizedBox(height: 8),
                Text(
                  '${(progress * 100).toInt()}% completed',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const Divider(height: 24),
                
                // Statistics
                Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        'Claims Submitted',
                        student['claimsCount'].toString(),
                        Icons.assignment_turned_in,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Approved Claims',
                        student['approvedCount'].toString(),
                        Icons.check_circle,
                      ),
                    ),
                    Expanded(
                      child: _buildStatItem(
                        'Completion',
                        '${(progress * 100).toInt()}%',
                        Icons.percent,
                      ),
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

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
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
    );
  }
}