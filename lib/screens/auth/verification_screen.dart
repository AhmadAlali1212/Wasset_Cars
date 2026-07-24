import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:mators_car/services/auth_serivces.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/auth/auth_button.dart';
import 'package:mators_car/widgets/auth/custom_textfield.dart';

class VerificationScreen extends StatefulWidget {
  final int accountTypeId;
  final String email;

  const VerificationScreen({
    super.key,
    required this.accountTypeId,
    required this.email,
  });

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  bool _isResending = false;

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await _authService.verifyRegisterOtp(
        email: widget.email,
        otp: _otpController.text,
      );

      if (!mounted) {
        return;
      }

      final accessToken = response['access_token'];
      if (accessToken is String && accessToken.isNotEmpty) {
        Navigator.pushReplacementNamed(context, '/home');
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } on DioException catch (e) {
      final String message =
          ((e.response?.data is Map
                  ? (e.response!.data as Map)['message']
                  : null)
              ?.toString()) ??
          'حدث خطأ أثناء التفعيل';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    setState(() => _isResending = true);

    try {
      await _authService.resendRegisterOtp(email: widget.email);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إرسال رمز جديد إلى البريد الإلكتروني'),
        ),
      );
    } on DioException catch (e) {
      final String message =
          ((e.response?.data is Map
                  ? (e.response!.data as Map)['message']
                  : null)
              ?.toString()) ??
          'تعذر إعادة إرسال الرمز';
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: const BoxDecoration(
                    color: Color(0xFFF3F7FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    size: 70,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'تفعيل الحساب',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1F2937),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'أدخل رمز OTP المرسل إلى ${widget.email}',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                const SizedBox(height: 32),
                CustomTextField(
                  controller: _otpController,
                  hint: 'رمز OTP',
                  icon: Icons.pin_outlined,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'الرجاء إدخال رمز OTP';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                AuthButton(
                  text: 'تفعيل الحساب',
                  onPressed: _verifyOtp,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _isResending ? null : _resendOtp,
                  child: Text(
                    _isResending
                        ? 'جارٍ إعادة الإرسال...'
                        : 'إعادة إرسال الرمز',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'صلاحية الرمز 15 دقيقة. يمكن إعادة إرساله مرة كل دقيقة.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.accountTypeId == 1
                      ? 'بعد التفعيل ستنتقل مباشرة إلى الصفحة الرئيسية.'
                      : 'بعد التفعيل يمكن متابعة خطوات الحساب الخاصة بالنوع المختار.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }
}
