import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../models/curriculum.dart';

class ClaimActivityScreen extends StatefulWidget {
  final CurriculumActivityModel activity;

  const ClaimActivityScreen({super.key, required this.activity});

  @override
  State<ClaimActivityScreen> createState() => _ClaimActivityScreenState();
}

class _ClaimActivityScreenState extends State<ClaimActivityScreen> {
  final supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _remarkController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _currentStatus;
  // Removed unused _claimId field

  @override
  void initState() {
    super.initState();
    _checkExistingStatus();
  }

  @override
  void dispose() {
    _remarkController.dispose();
    super.dispose();
  }

  Future<void> _checkExistingStatus() async {
    setState(() => _isLoading = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) return;

      final response = await supabase
          .from('curriculum_claims')
          .select()
          .eq('profile_id', userId)
          .eq('activity_id', widget.activity.id)
          .maybeSingle();

      setState(() {
        if (response != null) {
          _currentStatus = response['status'];
        } else {
          _currentStatus = null;
        }
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _joinActivity() async {
    setState(() => _isSubmitting = true);
    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final existing = await supabase
          .from('curriculum_claims')
          .select()
          .eq('profile_id', userId)
          .eq('activity_id', widget.activity.id)
          .maybeSingle();

      if (existing != null) {
        setState(() {
          _currentStatus = existing['status'];
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('You have already joined this activity!'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() => _isSubmitting = false);
        return;
      }

      await supabase
          .from('curriculum_claims')
          .insert({
            'profile_id': userId,
            'activity_id': widget.activity.id,
            'status': 'registered',
            'joined_at': DateTime.now().toIso8601String(),
          });

      setState(() {
        _currentStatus = 'registered';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Successfully joined the activity!'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to join: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Future<void> _submitClaim() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      final userId = supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not logged in');

      final existingClaim = await supabase
          .from('curriculum_claims')
          .select()
          .eq('profile_id', userId)
          .eq('activity_id', widget.activity.id)
          .maybeSingle();
      
      if (existingClaim == null) {
        throw Exception('No registration found. Please join the activity first.');
      }
      
      final claimId = existingClaim['id'];

      await supabase
          .from('curriculum_claims')
          .update({
            'status': 'pending',
            'claimed_at': DateTime.now().toIso8601String(),
            'remark': _remarkController.text.trim(),
          })
          .eq('id', claimId);

      setState(() => _currentStatus = 'pending');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Claim submitted! Waiting for approval.'),
            backgroundColor: Color(0xFF2ECC71),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit claim: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
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
          'Activity Details',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 18),
        ),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildActivityCard(),
                    const SizedBox(height: 24),
                    _buildStatusIndicator(),
                    const SizedBox(height: 24),
                    _buildContent(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildActivityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E3A5F),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Activity',
            style: TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            widget.activity.name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (widget.activity.category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    widget.activity.category!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              const Icon(Icons.access_time, color: Colors.white60, size: 14),
              const SizedBox(width: 4),
              Text(
                '${widget.activity.hours} hours',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator() {
    final steps = ['Joined', 'Claimed', 'Approved'];
    int currentStep = -1;
    
    if (_currentStatus == 'registered') {
      currentStep = 0;
    } else if (_currentStatus == 'pending') {
      currentStep = 1;
    } else if (_currentStatus == 'approved') {
      currentStep = 2;
    }

    return Row(
      children: List.generate(steps.length, (i) {
        final isDone = i <= currentStep;
        return Expanded(
          child: Row(
            children: [
              Column(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: isDone
                        ? const Color(0xFF00838F)
                        : Colors.grey[300],
                    child: Icon(
                      isDone ? Icons.check : Icons.circle,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    steps[i],
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDone ? const Color(0xFF00838F) : Colors.grey[400],
                    ),
                  ),
                ],
              ),
              if (i < steps.length - 1)
                Expanded(
                  child: Container(
                    height: 2,
                    margin: const EdgeInsets.only(bottom: 20),
                    color: i < currentStep ? const Color(0xFF00838F) : Colors.grey[300],
                  ),
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildContent() {
    if (_currentStatus == null) {
      return Column(
        children: [
          _buildInfoBox(
            color: const Color(0xFFE3F2FD),
            borderColor: const Color(0xFF90CAF9),
            icon: Icons.info_outline,
            iconColor: const Color(0xFF1565C0),
            text: 'Join this activity first before you can claim your hours.',
          ),
          const SizedBox(height: 24),
          _buildJoinButton(),
        ],
      );
    } else if (_currentStatus == 'registered') {
      return Column(
        children: [
          _buildInfoBox(
            color: const Color(0xFFFFF8E1),
            borderColor: const Color(0xFFFFE082),
            icon: Icons.info_outline,
            iconColor: const Color(0xFFF9A825),
            text: 'You have joined this activity. After attending, submit your claim below.',
          ),
          const SizedBox(height: 20),
          const Text(
            'Claim Details',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E3A5F),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _remarkController,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: 'Remark (optional)',
              hintText: 'Describe your participation...',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF1E3A5F), width: 1.5),
              ),
            ),
          ),
          const SizedBox(height: 24),
          _buildClaimButton(),
        ],
      );
    } else if (_currentStatus == 'pending') {
      return _buildInfoBox(
        color: const Color(0xFFFFF8E1),
        borderColor: const Color(0xFFFFE082),
        icon: Icons.hourglass_empty,
        iconColor: const Color(0xFFF9A825),
        text: 'Your claim has been submitted and is waiting for approval.',
      );
    } else if (_currentStatus == 'approved') {
      return _buildInfoBox(
        color: const Color(0xFFE8F5E9),
        borderColor: const Color(0xFFA5D6A7),
        icon: Icons.check_circle,
        iconColor: const Color(0xFF2ECC71),
        text: 'Your claim has been approved! Hours have been added to your record.',
      );
    } else if (_currentStatus == 'rejected') {
      return _buildInfoBox(
        color: const Color(0xFFFFEBEE),
        borderColor: const Color(0xFFEF9A9A),
        icon: Icons.cancel,
        iconColor: Colors.redAccent,
        text: 'Your claim was rejected. Please contact Pusat Adab for more information.',
      );
    }
    return const SizedBox();
  }

  Widget _buildInfoBox({
    required Color color,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
    required String text,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF795548)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJoinButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _joinActivity,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.how_to_reg),
        label: Text(_isSubmitting ? 'Joining...' : 'Join Activity'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00838F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildClaimButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitClaim,
        icon: _isSubmitting
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send),
        label: Text(_isSubmitting ? 'Submitting...' : 'Submit Claim'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1E3A5F),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}