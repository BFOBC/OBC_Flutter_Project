import 'package:broker_flutter_pp/data/bridges/FirestoreService.dart';
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
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60.0),
        child: AppBar(
          automaticallyImplyLeading: true,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green, Colors.blueAccent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: const Text(
            'FAQs',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : faqs.isEmpty
            ? const Center(
          child: Text(
            'No FAQs available',
            style:
            TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        )
            : ListView.builder(
          itemCount: faqs.length,
          itemBuilder: (context, index) {
            final faq = faqs[index];
            return Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.symmetric(vertical: 8),
              child: ExpansionTile(
                leading: const Icon(Icons.help_outline,
                    color: Colors.blueAccent),
                title: Text(
                  faq['question'] ?? 'No Question',
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Text(
                      faq['answer'] ?? '',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
