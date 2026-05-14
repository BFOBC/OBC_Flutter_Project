import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
import 'package:broker_flutter_pp/res/custom_colors.dart';
import 'package:broker_flutter_pp/ui/common/screens/NotificationDetailScreen.dart';
import 'package:broker_flutter_pp/ui/common/utils/RoleProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FAQSScreen extends StatefulWidget {
  const FAQSScreen({super.key});

  @override
  _FAQSScreenState createState() => _FAQSScreenState();
}

class _FAQSScreenState extends State<FAQSScreen> {
  List<Map<String, dynamic>> faqs = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchFaqs();
  }

  /// 🔹 Fetch FAQs from Firestore
  Future<void> fetchFaqs() async {
    setState(() {
      isLoading = true;
    });

    try {
      final roleProvider = Provider.of<RoleProvider>(context, listen: false);
      String selectedRole =
      roleProvider.role == UserRole.broker ? "Broker" : "Courier";

      print('🔵 Fetching FAQs for role: $selectedRole');

      List<Map<String, dynamic>> fetchedFaqs =
      await FirestoreService(context).readFAQs(selectedRole);

      print('📥 Total FAQs fetched: ${fetchedFaqs.length}');
      print('📥 Total FAQs fetched: ${fetchedFaqs.length}');

      setState(() {
        faqs = fetchedFaqs;
        isLoading = false;
      });
    } catch (e) {
      print('❌ Error fetching FAQs: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Palette.primaryColor,
        elevation: 0,
        title: const Text('FAQs', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      backgroundColor: Palette.backgroundLight,
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Palette.primaryColor))
            : faqs.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80, height: 80,
                      decoration: BoxDecoration(color: Palette.primaryColor.withOpacity(0.08), shape: BoxShape.circle),
                      child: const Icon(Icons.help_outline_rounded, size: 40, color: Palette.primaryColor),
                    ),
                    const SizedBox(height: 16),
                    const Text('No FAQs available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Palette.textPrimary)),
                  ],
                ),
              )
            : ListView.builder(
                itemCount: faqs.length,
                itemBuilder: (context, index) {
                  final faq = faqs[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Palette.surface,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [BoxShadow(color: Palette.primaryColor.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
                    ),
                    child: ExpansionTile(
                      leading: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Palette.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.help_outline_rounded, color: Palette.primaryColor, size: 20),
                      ),
                      title: Text(faq['question'] ?? 'No Question', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Palette.textPrimary)),
                      iconColor: Palette.primaryColor,
                      collapsedIconColor: Palette.textSecondary,
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      children: [
                        Text(faq['answer'] ?? '', style: const TextStyle(fontSize: 13, color: Palette.textSecondary, height: 1.5)),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
