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
      setState(() => isLoading = false);
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
        title: const Text('Add New Activity'),
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
                value: selectedCategory,
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
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () async {
              if (nameController.text.isEmpty || hoursController.text.isEmpty) return;
              try {
                await supabase.from('curriculum_activities').insert({
                  'name': nameController.text.trim(),
                  'category': selectedCategory,
                  'hours': int.parse(hoursController.text.trim()),
                });
                Navigator.pop(context);
                fetchActivities();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity added successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Add', style: TextStyle(color: Colors.white)),
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
        title: const Text('Edit Activity'),
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
                value: selectedCategory,
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
            style: ElevatedButton.styleFrom(backgroundColor: color),
            onPressed: () async {
              try {
                await supabase
                    .from('curriculum_activities')
                    .update({
                      'name': nameController.text.trim(),
                      'category': selectedCategory,
                      'hours': int.parse(hoursController.text.trim()),
                    })
                    .eq('id', activity['id']);
                Navigator.pop(context);
                fetchActivities();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Activity updated!'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteActivity(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Activity'),
        content: const Text('Are you sure you want to delete this activity?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await supabase.from('curriculum_activities').delete().eq('id', id);
      fetchActivities();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Activity deleted!'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Color _categoryColor(String? category) {
    switch (category) {
      case 'Sports':      return Colors.orange;
      case 'Community':   return Colors.green;
      case 'Leadership':  return Colors.purple;
      case 'Academic':    return Colors.blue;
      case 'Soft Skills': return Colors.teal;
      case 'Arts':        return Colors.pink;
      default:            return Colors.grey;
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
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: color,
        onPressed: _showAddActivityDialog,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activities.isEmpty
              ? const Center(child: Text('No activities yet. Add one!'))
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
                            borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: CircleAvatar(
                            backgroundColor: catColor.withOpacity(0.2),
                            child: Icon(Icons.emoji_events, color: catColor),
                          ),
                          title: Text(activity['name'],
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Row(children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: catColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(activity['category'] ?? '-',
                                      style: TextStyle(
                                          color: catColor, fontSize: 12)),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.access_time,
                                    size: 14, color: Colors.grey),
                                const SizedBox(width: 4),
                                Text('${activity['hours']} hours',
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.grey)),
                              ]),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.blue),
                                onPressed: () =>
                                    _showEditActivityDialog(activity),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () =>
                                    _deleteActivity(activity['id']),
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