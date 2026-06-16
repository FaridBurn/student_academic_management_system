import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../controllers/registration_controller.dart';
import 'subject_detail_page.dart';
import 'registration_cart_page.dart';

class SubjectListPage extends StatefulWidget {
  const SubjectListPage({super.key});

  @override
  State<SubjectListPage> createState() => _SubjectListPageState();
}

class _SubjectListPageState extends State<SubjectListPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RegistrationController>().fetchSubjects();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text(
          'Available Subjects',
          style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
        ),
        backgroundColor: const Color(0xFF1A1F36),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          Consumer<RegistrationController>(
            builder: (context, controller, child) {
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: Badge(
                  label: Text(
                    '${controller.cartItems.length}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  isLabelVisible: controller.cartItems.isNotEmpty,
                  backgroundColor: const Color(0xFFD32F2F),
                  offset: const Offset(-4, 4),
                  child: IconButton(
                    icon: const Icon(Icons.shopping_cart_outlined, size: 24),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegistrationCartPage()),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(68),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search by subject code or name...',
                  hintStyle: const TextStyle(color: Colors.black38, fontSize: 14),
                  prefixIcon: const Icon(Icons.search_rounded, color: Colors.black45, size: 22),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            context.read<RegistrationController>().filterSubjects('');
                            setState(() {});
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) {
                  setState(() {});
                  context.read<RegistrationController>().filterSubjects(value);
                },
              ),
            ),
          ),
        ),
      ),
      body: Consumer<RegistrationController>(
        builder: (context, controller, child) {
          if (controller.isLoading) {
            return const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1A1F36)),
              ),
            );
          }

          if (controller.filteredSubjects.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off_rounded, size: 64, color: Colors.blueGrey),
                    SizedBox(height: 16),
                    Text(
                      'No Subjects Found',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1A1F36)),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Modify your verification parameters and try again.',
                      style: TextStyle(color: Colors.black45, fontSize: 13),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: controller.filteredSubjects.length,
            itemBuilder: (context, index) {
              final subject = controller.filteredSubjects[index];
              final isInCart = controller.cartItems.any((item) => item.subjectID == subject.subjectID);

              return Card(
                elevation: 1,
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SubjectDetailPage(subject: subject),
                      ),
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFFE3F2FD),
                        radius: 20,
                        child: Text(
                          '${subject.credit_hours}h',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1565C0),
                            fontSize: 13,
                          ),
                        ),
                      ),
                      title: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              subject.sub_code,
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4.0),
                        child: Text(
                          subject.sub_name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1A1F36),
                            fontSize: 14,
                          ),
                        ),
                      ),
                      trailing: isInCart
                          ? Container(
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Color(0xFFE8F5E9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded, color: Color(0xFF2E7D32), size: 18),
                            )
                          : SizedBox(
                              height: 34,
                              child: ElevatedButton(
                                onPressed: () async {
                                  final success = await controller.addToCart(subject);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          success
                                              ? '${subject.sub_code} added to transaction log'
                                              : 'Aborted: Load constraints broken or duplicated value.',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        backgroundColor: success ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF1A1F36),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Add', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              ),
                            ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}