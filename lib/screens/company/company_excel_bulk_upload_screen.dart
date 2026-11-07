import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mators_car/screens/company/map_location_picker_screen.dart';
import 'package:mators_car/services/api_exception.dart';
import 'package:mators_car/services/controllers/bulk_upload_service.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/ulits/adaptive_colors.dart';
import 'package:mators_car/ulits/localization/app_localizations.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';

/// شاشة "الرفع الجماعي عبر Excel" — الطريقة الرسمية المدعومة من السيرفر
/// (قسم "13 - الرفع الجماعي Excel" بملف Postman): تنزيل نموذج، اختيار
/// ملف Excel، معاينته قبل الإرسال (عدد الصفوف الصحيحة/الخاطئة)، ثم رفعه
/// فعلياً مع إحداثيات افتراضية تُستخدم للصفوف التي لا تحدد موقعاً خاصاً
/// بها، وأخيراً استعراض سجل الدفعات السابقة وحالتها لدى الأدمن.
///
/// ملاحظة تبعيات: هذه الشاشة تحتاج حزمة `file_picker` لاختيار ملف Excel
/// من الجهاز. إن لم تكن مضافة بعد في pubspec.yaml أضف السطر التالي ضمن
/// dependencies ثم نفّذ flutter pub get:
///   file_picker: ^8.1.2
class CompanyExcelBulkUploadScreen extends StatefulWidget {
  const CompanyExcelBulkUploadScreen({super.key});

  @override
  State<CompanyExcelBulkUploadScreen> createState() =>
      _CompanyExcelBulkUploadScreenState();
}

class _CompanyExcelBulkUploadScreenState
    extends State<CompanyExcelBulkUploadScreen> {
  final BulkUploadService _bulkUploadService = BulkUploadService();

  File? _selectedFile;
  Map<String, dynamic>? _previewResult;
  bool _isPreviewing = false;
  bool _isUploading = false;
  String? _errorMessage;
  Map<String, dynamic>? _uploadResult;

  double? _defaultLatitude;
  double? _defaultLongitude;
  String _locationLabel = 'لم يُحدَّد بعد';

  Future<void> _openTemplateLink() async {
    final uri = Uri.parse(_bulkUploadService.templateDownloadUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: context.tr('excel_template_open_error'),
      );
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx', 'xls'],
    );
    if (result.isEmpty) return;
    setState(() {
      _selectedFile = File(result.single.path!);
      _previewResult = null;
      _uploadResult = null;
      _errorMessage = null;
    });
  }

  Future<void> _pickDefaultLocation() async {
    final result = await Navigator.push<PickedLocation>(
      context,
      MaterialPageRoute(
        builder:
            (_) => MapLocationPickerScreen(
              initialLatitude: _defaultLatitude,
              initialLongitude: _defaultLongitude,
            ),
      ),
    );
    if (result == null) return;
    setState(() {
      _defaultLatitude = result.latitude;
      _defaultLongitude = result.longitude;
      _locationLabel = result.address;
    });
  }

  Future<void> _previewFile() async {
    if (_selectedFile == null) return;
    setState(() {
      _isPreviewing = true;
      _errorMessage = null;
    });
    try {
      final result = await _bulkUploadService.previewExcel(_selectedFile!);
      if (!mounted) return;
      setState(() => _previewResult = result);
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _errorMessage = ApiException.userMessage(
              e,
              fallback: 'تعذر معاينة الملف، يرجى المحاولة مرة أخرى',
            ),
      );
    } finally {
      if (mounted) setState(() => _isPreviewing = false);
    }
  }

  Future<void> _uploadFile() async {
    if (_selectedFile == null) return;
    if (_defaultLatitude == null || _defaultLongitude == null) {
      AppSnackbar.showWarning(
        context,
        title: context.tr('select_default_location_first'),
      );
      return;
    }
    setState(() {
      _isUploading = true;
      _errorMessage = null;
    });
    try {
      final result = await _bulkUploadService.uploadExcel(
        excelFile: _selectedFile!,
        defaultLatitude: _defaultLatitude!,
        defaultLongitude: _defaultLongitude!,
      );
      if (!mounted) return;
      setState(() => _uploadResult = result);
    } catch (e) {
      if (!mounted) return;
      setState(
        () =>
            _errorMessage = ApiException.userMessage(
              e,
              fallback: 'تعذر رفع الملف، يرجى المحاولة مرة أخرى',
            ),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.adaptiveScaffoldBg,
      appBar: AppBar(
        title: Text(context.tr('excel_upload_title')),
        centerTitle: true,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildStepCard(
            step: '1',
            title: context.tr('download_excel_template'),
            child: OutlinedButton.icon(
              onPressed: _openTemplateLink,
              icon: const Icon(Icons.download_outlined),
              label: Text(context.tr('download_template')),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildStepCard(
            step: '2',
            title: context.tr('select_default_car_location'),
            child: GestureDetector(
              onTap: _pickDefaultLocation,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.borderGrey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.location_on_outlined,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _locationLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildStepCard(
            step: '3',
            title: context.tr('select_completed_excel'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFile,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    _selectedFile != null
                        ? _selectedFile!.path.split(Platform.pathSeparator).last
                        : context.tr('choose_excel_file'),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
                if (_selectedFile != null) ...[
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: _isPreviewing ? null : _previewFile,
                    icon:
                        _isPreviewing
                            ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                            : const Icon(Icons.remove_red_eye_outlined),
                    label: Text(context.tr('preview_before_upload')),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: AppColors.primaryNavy,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (_previewResult != null) ...[
            const SizedBox(height: 14),
            _buildPreviewCard(_previewResult!),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _errorMessage!,
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ],
          if (_uploadResult != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                context.tr('excel_batch_uploaded'),
                style: TextStyle(
                  color: AppColors.success,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_selectedFile != null)
            ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              icon:
                  _isUploading
                      ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Icon(Icons.cloud_upload_outlined),
              label: Text(
                _isUploading
                    ? context.tr('uploading')
                    : context.tr('upload_file_now'),
              ),
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF0F4C81),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required String title,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.adaptiveCardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: AppColors.primary,
                child: Text(
                  step,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildPreviewCard(Map<String, dynamic> preview) {
    // نتعامل بمرونة مع تسمية الحقول المحتملة من السيرفر بدل افتراض شكل
    // واحد صارم، لأن Postman لم يوثّق بنية استجابة /bulk-upload/preview
    // بالتفصيل الكامل.
    final validCount =
        preview['valid_rows'] ?? preview['valid_count'] ?? preview['valid'];
    final invalidCount =
        preview['invalid_rows'] ??
        preview['invalid_count'] ??
        preview['invalid'];
    final errors = preview['errors'];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.tr('preview_result'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              if (validCount != null) ...[
                Icon(Icons.check_circle, color: AppColors.success, size: 18),
                const SizedBox(width: 4),
                Text('$validCount ${context.tr('valid_row')}'),
                const SizedBox(width: 16),
              ],
              if (invalidCount != null) ...[
                Icon(Icons.error_outline, color: AppColors.error, size: 18),
                const SizedBox(width: 4),
                Text('$invalidCount ${context.tr('invalid_row')}'),
              ],
            ],
          ),
          if (errors is List && errors.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...errors
                .take(10)
                .map(
                  (e) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      '• $e',
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 12.5,
                      ),
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}
