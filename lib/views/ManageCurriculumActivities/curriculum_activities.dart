import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CurriculumActivitiesScreen extends StatefulWidget {
  const CurriculumActivitiesScreen({super.key});

  @override
  State<CurriculumActivitiesScreen> createState() =>
      _CurriculumActivitiesScreenState();
}

class _CurriculumActivitiesScreenState
    extends State<CurriculumActivitiesScreen> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> activities = [];
  bool isLoading = true;

  static const color = Color(0xFF00838F);

  @override
  void initState() {
    super.initState();
    fetchActivities();
  }

  Future<void> fetchActivities() async {
    setState(() => isLoading = true);
    try {
      final data = await supabase
          .from('curriculum_activities')
          .select()
          .order('created_at', ascending: false);
      setState(() {
        activities = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching activities: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error fetching activities: $e')),
        );
      }
    }
  }

  Future<void> _deleteActivity(int activityId, String activityName) async {
    // Show confirmation dialog first
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Delete Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Are you sure you want to delete "$activityName"?\n\nThis will also remove all associated claims. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    // Show loading
    setState(() => isLoading = true);

    try {
      // First, delete all claims associated with this activity
      await supabase
          .from('curriculum_claims')
          .delete()
          .eq('activity_id', activityId);

      // Then delete the activity
      await supabase
          .from('curriculum_activities')
          .delete()
          .eq('id', activityId);

      // Refresh the list
      await fetchActivities();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Activity deleted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error deleting activity: $e');
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete activity: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddActivityDialog() {
    final nameController = TextEditingController();
    final hoursController = TextEditingController();
    String selectedCategory = 'Sports';

    final categories = [
      'Sports',
      'Community',
      'Leadership',
      'Academic',
      'Soft Skills',
      'Arts',
      'Others'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Add New Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty || hoursController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              try {
                await supabase.from('curriculum_activities').insert({
                  'name': nameController.text.trim(),
                  'category': selectedCategory,
                  'hours': int.parse(hoursController.text.trim()),
                  'is_active': true,
                  'created_at': DateTime.now().toIso8601String(),
                });
                Navigator.pop(context);
                await fetchActivities();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity added successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error adding activity: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showEditActivityDialog(Map<String, dynamic> activity) {
    final nameController = TextEditingController(text: activity['name']);
    final hoursController =
        TextEditingController(text: activity['hours'].toString());
    String selectedCategory = activity['category'] ?? 'Sports';

    final categories = [
      'Sports',
      'Community',
      'Leadership',
      'Academic',
      'Soft Skills',
      'Arts',
      'Others'
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Edit Activity',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Activity Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (value) => selectedCategory = value!,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: hoursController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Hours',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (nameController.text.isEmpty || hoursController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please fill all fields'),
                    backgroundColor: Colors.orange,
                  ),
                );
                return;
              }
              try {
                await supabase
                    .from('curriculum_activities')
                    .update({
                      'name': nameController.text.trim(),
                      'category': selectedCategory,
                      'hours': int.parse(hoursController.text.trim()),
                      'updated_at': DateTime.now().toIso8601String(),
                    })
                    .eq('id', activity['id']);
                Navigator.pop(context);
                await fetchActivities();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Activity updated successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                print('Error editing activity: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Sports':
        return Colors.orange;
      case 'Community':
        return Colors.green;
      case 'Leadership':
        return Colors.purple;
      case 'Academic':
        return Colors.blue;
      case 'Soft Skills':
        return Colors.teal;
      case 'Arts':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE0F7FA),
      appBar: AppBar(
        title: const Text('Curriculum Activities'),
        backgroundColor: color,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchActivities,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color,
        onPressed: _showAddActivityDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activities.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No activities yet. Add one!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: fetchActivities,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: activities.length,
                    itemBuilder: (context, index) {
                      final activity = activities[index];
                      final catColor = _categoryColor(activity['category']);
                      return Card(
                        elevation: 3,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: catColor.withValues(alpha: 0.2),
                            child: Icon(
                              Icons.emoji_events,
                              color: catColor,
                            ),
                          ),
                          title: Text(
                            activity['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: catColor.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      activity['category'] ?? '-',
                                      style: TextStyle(
                                        color: catColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${activity['hours']} hours',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  color: Colors.blue,
                                ),
                                onPressed: () =>
                                    _showEditActivityDialog(activity),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.red,
                                ),
                                onPressed: () =>
                                    _deleteActivity(activity['id'], activity['name']),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}