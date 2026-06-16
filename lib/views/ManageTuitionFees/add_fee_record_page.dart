import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/supabase_fee_service.dart';

class AddFeeRecordPage extends StatefulWidget {
  const AddFeeRecordPage({super.key});

  @override
  State<AddFeeRecordPage> createState() => _AddFeeRecordPageState();
}

class _AddFeeRecordPageState extends State<AddFeeRecordPage> {
  static const _orange = Color(0xFFE65100);

  final _feeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<Map<String, dynamic>> _students = [];
  Map<String, dynamic>? _selectedStudent;
  String _semester = 'Semester 1';
  String _academicYear = '';
  DateTime _dueDate = DateTime.now().add(const Duration(days: 30));
  bool _loadingStudents = true;
  bool _submitting = false;

  static const _semesters = ['Semester 1', 'Semester 2', 'Semester 3'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _academicYear = '${now.year}/${now.year + 1}';
    _loadStudents();
  }

  @override
  void dispose() {
    _feeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStudents() async {
    try {
      final data = await SupabaseFeeService.getAllStudentProfiles();
      setState(() {
        _students = data;
        _loadingStudents = false;
      });
    } catch (e) {
      setState(() => _loadingStudents = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error loading students: $e')));
      }
    }
  }

  Future<void> _pickDueDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx)
            .copyWith(colorScheme: const ColorScheme.light(primary: _orange)),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudent == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Please select a student.')));
      return;
    }

    setState(() => _submitting = true);
    try {
      await SupabaseFeeService.createFeeRecord(
        studentId: _selectedStudent!['id'] as String,
        semester: _semester,
        academicYear: _academicYear,
        totalFee: double.parse(_feeCtrl.text.trim()),
        dueDate: _dueDate,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Fee record created successfully.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => _submitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Failed: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFmt = DateFormat('dd MMM yyyy');

    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0),
      appBar: AppBar(
        backgroundColor: _orange,
        foregroundColor: Colors.white,
        title: const Text('Add Fee Record',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _loadingStudents
          ? const Center(child: CircularProgressIndicator(color: _orange))
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Student picker
                  _label('Student'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    initialValue: _selectedStudent,
                    isExpanded: true,
                    decoration: _inputDeco('Select student'),
                    items: _students.map((s) {
                      final prog = s['programme'] as String? ?? '';
                      return DropdownMenuItem(
                        value: s,
                        child: Text(
                          prog.isNotEmpty
                              ? '${s['name']} ($prog)'
                              : s['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => _selectedStudent = v),
                    validator: (_) =>
                        _selectedStudent == null ? 'Required' : null,
                  ),

                  const SizedBox(height: 20),

                  // Semester
                  _label('Semester'),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _semester,
                    decoration: _inputDeco(''),
                    items: _semesters
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setState(() => _semester = v!),
                  ),

                  const SizedBox(height: 20),

                  // Academic Year
                  _label('Academic Year'),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _academicYear,
                    decoration: _inputDeco('e.g. 2024/2025'),
                    onChanged: (v) => _academicYear = v,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),

                  const SizedBox(height: 20),

                  // Total Fee
                  _label('Total Fee (RM)'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _feeCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true),
                    decoration: _inputDeco('e.g. 5200.00'),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid amount';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 20),

                  // Due Date
                  _label('Due Date'),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _pickDueDate,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border:
                            Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today,
                              color: _orange, size: 20),
                          const SizedBox(width: 12),
                          Text(dateFmt.format(_dueDate),
                              style: const TextStyle(fontSize: 15)),
                          const Spacer(),
                          const Icon(Icons.chevron_right,
                              color: Colors.grey),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _orange,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                          : const Icon(Icons.save),
                      label: Text(
                        _submitting ? 'Saving...' : 'Create Fee Record',
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      onPressed: _submitting ? null : _submit,
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _label(String text) => Text(text,
      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14));

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: _orange)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      );
}