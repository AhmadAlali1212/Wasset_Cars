import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:provider/provider.dart';
import 'package:mators_car/services/controllers/auth_serivces.dart';
import 'package:mators_car/services/controllers/profile_service.dart';
import 'package:mators_car/ulits/colors.dart';

/// شاشة "تعديل الملف الشخصي" — تغطي قسم "21 - الملف الشخصي" الجديد في
/// نسخة Postman المحدّثة (PUT /profile لتحديث الاسم/الهاتف، ورفع/حذف
/// صورة البروفايل، وإضافة/حذف صور معرض المستخدم). لم تكن هذه الميزة
/// موجودة سابقاً في التطبيق إطلاقاً.
class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final ProfileService _profileService = ProfileService();
  final ImagePicker _imagePicker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _phoneController;

  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    final user =
        Provider.of<AuthService>(context, listen: false).currentUser ?? {};
    _nameController = TextEditingController(
      text: (user['name'] ?? '').toString(),
    );
    _phoneController = TextEditingController(
      text: (user['phone_number'] ?? '').toString(),
    );
    final avatar =
        user['avatar'] ?? user['avatar_url'] ?? user['profile_image'];
    _avatarUrl = avatar?.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadAvatar() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      // ⬅️ جديد: تحديد أبعاد قصوى بالإضافة لجودة الضغط — صورة كاميرا حديثة
      // بدون هذا القيد تبقى ضخمة (بعشرات الميغابايت) حتى مع imageQuality
      // منخفضة، وهذا مؤثر جداً لسوق بإنترنت غير مستقر.
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (picked == null) return;

    setState(() => _isUploadingAvatar = true);
    try {
      final result = await _profileService.uploadAvatar(File(picked.path));
      final newAvatar =
          result['avatar'] ?? result['avatar_url'] ?? result['profile_image'];
      if (!mounted) return;
      setState(() {
        if (newAvatar != null) _avatarUrl = newAvatar.toString();
      });
      // نحدّث بيانات المستخدم المخزّنة محلياً حتى تنعكس الصورة الجديدة
      // في بقية شاشات التطبيق بدون الحاجة لإعادة تسجيل الدخول.
      if (mounted) {
        await Provider.of<AuthService>(context, listen: false).getCurrentUser();
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر رفع الصورة',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _deleteAvatar() async {
    setState(() => _isUploadingAvatar = true);
    try {
      await _profileService.deleteAvatar();
      if (!mounted) return;
      setState(() => _avatarUrl = null);
      if (mounted) {
        await Provider.of<AuthService>(context, listen: false).getCurrentUser();
      }
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حذف الصورة',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isUploadingAvatar = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _profileService.updateProfile(
        name: _nameController.text,
        phoneNumber: _phoneController.text,
      );
      if (!mounted) return;
      await Provider.of<AuthService>(context, listen: false).getCurrentUser();
      if (!mounted) return;
      AppSnackbar.showSuccess(context, title: 'تم حفظ التعديلات بنجاح');
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(
        context,
        title: 'تعذّر حفظ التعديلات',
        debugMessage: e,
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('تعديل الملف الشخصي'),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.surfaceLight,
                    backgroundImage:
                        _avatarUrl != null ? NetworkImage(_avatarUrl!) : null,
                    child:
                        _isUploadingAvatar
                            ? const CircularProgressIndicator()
                            : (_avatarUrl == null
                                ? const Icon(
                                  Icons.person,
                                  size: 44,
                                  color: Colors.grey,
                                )
                                : null),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _isUploadingAvatar ? null : _pickAndUploadAvatar,
                      child: const CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.primary,
                        child: Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (_avatarUrl != null) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton(
                  onPressed: _isUploadingAvatar ? null : _deleteAvatar,
                  child: const Text(
                    'حذف الصورة',
                    style: TextStyle(color: AppColors.error),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              decoration: InputDecoration(
                labelText: 'الاسم',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              validator:
                  (v) => (v == null || v.trim().isEmpty) ? 'مطلوب' : null,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 28),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF0F4C81),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child:
                  _isSaving
                      ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                      : const Text('حفظ التعديلات'),
            ),
          ],
        ),
      ),
    );
  }
}
