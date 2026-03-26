import 'package:demoapp/Services/apiservice.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class ViewMedicalRecordScreen extends StatefulWidget {
  final int recordId;

  const ViewMedicalRecordScreen({super.key, required this.recordId});

  @override
  State<ViewMedicalRecordScreen> createState() => _ViewMedicalRecordScreenState();
}

class _ViewMedicalRecordScreenState extends State<ViewMedicalRecordScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _record;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    setState(() => _isLoading = true);
    try {
      final res = await _apiService.getMedicalHistory(singleId: widget.recordId.toString());
      if (res['status'] == true) {
        setState(() {
          _record = res['data'];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching record detail: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _openFile(String url) async {
    bool isImage = !url.toLowerCase().contains('.pdf');
    if (isImage) {
      _showFullScreenImage(url);
      return;
    }

    final uri = Uri.parse(url);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showFullScreenImage(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                height: double.infinity,
                color: Colors.black,
                child: InteractiveViewer(
                  child: Image.network(url, fit: BoxFit.contain),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
        body: const Center(child: CircularProgressIndicator(color: Color(0xFF1565C0))),
      );
    }

    if (_record == null) {
      return Scaffold(
        appBar: AppBar(elevation: 0, backgroundColor: Colors.white),
        body: const Center(child: Text("Record not found")),
      );
    }

    String dateStr = "";
    try {
      DateTime dt = DateTime.parse(_record!['date_of_report']).toLocal();
      dateStr = DateFormat('dd MMMM yyyy').format(dt);
    } catch (e) {
      dateStr = _record!['date_of_report'] ?? "";
    }

    List<String> images = List<String>.from(_record!['images'] ?? []);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          "Record Details",
          style: TextStyle(color: Color(0xFF263238), fontSize: 17, fontWeight: FontWeight.w900),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1565C0), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(dateStr),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ATTACHED DOCUMENTS",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: Color(0xFF546E7A), letterSpacing: 1),
                  ),
                  const SizedBox(height: 15),
                  if (images.isEmpty)
                    const Text("No documents attached.")
                  else
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: images.length,
                      itemBuilder: (context, index) => _buildImageCard(images[index], index + 1),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(String dateStr) {
    bool isReport = _record!['type'] == 'report';
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
      ),
      padding: const EdgeInsets.fromLTRB(25, 10, 25, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: (isReport ? Colors.blue : Colors.teal).withAlpha(12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isReport ? "MEDICAL REPORT" : "PRESCRIPTION",
                  style: TextStyle(color: isReport ? Colors.blue : Colors.teal, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            _record!['heading'] ?? "Untitled Record",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A237E), height: 1.2),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.event_note_rounded, size: 16, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(
                "Report Date: $dateStr",
                style: const TextStyle(color: Colors.blueGrey, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildImageCard(String url, int index) {
    bool isPdf = url.toLowerCase().contains('.pdf');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withAlpha(5), blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: Colors.blueGrey[50]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isPdf)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.network(
                url,
                width: double.infinity,
                height: 250,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 250,
                    color: Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            )
          else
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.picture_as_pdf_rounded, size: 50, color: Colors.red),
                  const SizedBox(height: 10),
                  Text("Digital Document #$index", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Attachment #$index", style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Color(0xFF263238))),
                ElevatedButton.icon(
                  onPressed: () => _openFile(url),
                  icon: Icon(isPdf ? Icons.open_in_new_rounded : Icons.fullscreen_rounded, size: 16),
                  label: Text(isPdf ? "OPEN PDF" : "VIEW FULL", style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
