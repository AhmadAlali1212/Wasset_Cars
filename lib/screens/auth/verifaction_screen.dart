import 'package:flutter/material.dart';
import 'package:mators_car/ulits/colors.dart';

class VerificationScreen extends StatefulWidget {
  final int accountTypeId;
  final String token;

  const VerificationScreen({
    super.key,
    required this.accountTypeId,
    required this.token,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  List<String> _documents = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadRequiredDocuments();
  }

  void _loadRequiredDocuments() {
    // Based on account type, load different documents
    if (widget.accountTypeId == 2) {
      // Company
      _documents = [
        'صورة عن السجل التجاري',
        'صورة عن الهوية',
        'صورة عن العقد الإيجاري للمقر',
      ];
    } else if (widget.accountTypeId == 3) {
      // Workshop
      _documents = [
        'صورة عن الرخصة المهنية',
        'صورة عن الهوية',
        'صورة عن العقد الإيجاري للورشة',
      ];
    }
  }

  Future<void> _uploadDocuments() async {
    setState(() => _isLoading = true);

    // TODO: Implement document upload
    await Future.delayed(const Duration(seconds: 2)); // Simulate API call

    setState(() => _isLoading = false);

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('تم رفع المستندات بنجاح، سيتم مراجعتها من قبل الإدارة'),
      ),
    );

    // Navigate to home
    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'تحقق من الحساب',
          style: TextStyle(
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFE8F1FF,
                    ), // دائرة زرقاء ناعمة تناسب الهوية البصرية
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.verified_user_outlined,
                    size: 70,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 30),
              const Text(
                'لتفعيل حسابك، يرجى رفع المستندات المطلوبة أدناه للتحقق من الهوية.',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // قائمة المستندات بتنسيق عصري
              ..._documents.map((doc) => _buildDocumentItem(doc)).toList(),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _uploadDocuments,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      AppColors
                          .primary, // لون داكن موحد متناسق مع الأزرار بالصورة
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child:
                    _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                          'رفع المستندات وإرسالها',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
              ),
              const SizedBox(height: 24),
              Text(
                'سيتم مراجعة المستندات من قبل الإدارة خلال 24-48 ساعة',
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentItem(String documentName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            documentName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement document picker
                  },
                  icon: const Icon(Icons.file_upload_outlined, size: 18),
                  label: const Text('اختر ملف'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2937),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text('أو', style: TextStyle(color: Colors.grey[400])),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: Implement camera
                  },
                  icon: const Icon(Icons.camera_alt_outlined, size: 18),
                  label: const Text('التقاط صورة'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1F2937),
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
