import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_fee_service.dart';
import '../manage_tuition_fees/add_fee_record_page.dart';

class TreasuryFeeOverviewPage extends StatefulWidget {
  const TreasuryFeeOverviewPage({super.key});

  @override
  State<TreasuryFeeOverviewPage> createState() => _TreasuryFeeOverviewPageState();
}

class _TreasuryFeeOverviewPageState extends State<TreasuryFeeOverviewPage> {
  List<Map<String, dynamic>> _records = [];
  bool _loading = true;
  String _filter = 'All';

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    setState(() => _loading = true);
    try {
      final data = await SupabaseFeeService.getAllFeesWithProfiles();
      setState(() {
        _records = data;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading records: $e')),
        );
      }
    }
  }

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'All') return _records;
    if (_filter == 'Overdue') {
      return _records.where((r) {
        final dueDate = DateTime.parse(r['due_date'] as String);
        return r['status'] == 'Unpaid' && DateTime.now().isAfter(dueDate);
      }).toList();
    }
    return _records.where((r) => r['status'] == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(symbol: 'RM ', decimalDigits: 2);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        title: const Text('Fee Records', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFFE65100),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Fee Record'),
        onPressed: () async {
          final added = await Navigator.push<bool>(
            context,
            MaterialPageRoute(builder: (_) => const AddFeeRecordPage()),
          );
          if (added == true) _loadRecords();
        },
      ),
      body: Column(
        children: [
          if (!_loading) _buildSummary(currency),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['All', 'Unpaid', 'Paid', 'Overdue'].map((f) {
                  final selected = _filter == f;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(f),
                      selected: selected,
                      onSelected: (_) => setState(() => _filter = f),
                      selectedColor: const Color(0xFFE65100),
                      labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.w600,
                      ),
                      checkmarkColor: Colors.white,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFFE65100)))
                : _filtered.isEmpty
                    ? const Center(child: Text('No records found.'))
                    : RefreshIndicator(
                        onRefresh: _loadRecords,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (context, i) => _buildCard(_filtered[i], currency),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(NumberFormat currency) {
    final total = _records.length;
    final paid = _records.where((r) => r['status'] == 'Paid').length;
    final unpaid = _records.where((r) => r['status'] == 'Unpaid').length;
    final totalAmount = _records.fold<double>(0, (s, r) => s + (r['total_fee'] as num).toDouble());
    final collectedAmount = _records
        .where((r) => r['status'] == 'Paid')
        .fold<double>(0, (s, r) => s + (r['total_fee'] as num).toDouble());

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE65100),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _summaryItem('Total', '$total', Icons.people),
              _summaryItem('Paid', '$paid', Icons.check_circle),
              _summaryItem('Unpaid', '$unpaid', Icons.pending),
            ],
          ),
          const Divider(color: Colors.white30, height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Collected: ${currency.format(collectedAmount)}',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              Text('Total: ${currency.format(totalAmount)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> record, NumberFormat currency) {
    final status = record['status'] as String;
    final dueDate = DateTime.parse(record['due_date'] as String);
    final isOverdue = status == 'Unpaid' && DateTime.now().isAfter(dueDate);

    Color statusColor;
    IconData statusIcon;
    if (status == 'Paid') {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
    } else if (isOverdue) {
      statusColor = Colors.red;
      statusIcon = Icons.warning;
    } else {
      statusColor = Colors.orange;
      statusIcon = Icons.access_time;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: statusColor.withValues(alpha: 0.15),
              child: Icon(Icons.person, color: statusColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(record['name'] as String,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(record['email'] as String,
                      style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      _chip(record['semester'] as String, Colors.blue),
                      const SizedBox(width: 4),
                      _chip(record['academic_year'] as String, Colors.indigo),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Due: ${DateFormat('dd MMM yyyy').format(dueDate)}',
                      style: TextStyle(
                          fontSize: 11,
                          color: isOverdue ? Colors.red : Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(currency.format((record['total_fee'] as num).toDouble()),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: statusColor),
                      const SizedBox(width: 3),
                      Text(isOverdue ? 'Overdue' : status,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600)),
    );
  }
}