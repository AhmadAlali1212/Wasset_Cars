import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:mators_car/screens/auth/resetopassword_screen.dart';
import 'package:mators_car/services/controllers/auth_serivces.dart';
import 'package:mators_car/ulits/colors.dart';
import 'package:mators_car/widgets/auth/auth_button.dart';
import 'package:mators_car/widgets/common/app_snackbar.dart';
import 'package:mators_car/widgets/auth/custom_textfield.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  final AuthService _authService = AuthService();

  Future<void> _sendResetOtp() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        await _authService.requestPasswordResetOtp(
          email: _emailController.text,
        );

        if (!mounted) {
          return;
        }

        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResetPasswordScreen(email: _emailController.text),
          ),
        );
      } on DioException catch (e) {
        final String message =
            ((e.response?.data is Map
                    ? (e.response!.data as Map)['message']
                    : null)
                ?.toString()) ??
            'حدث خطأ أثناء إرسال رمز التحقق';
        if (mounted) {
          AppSnackbar.showError(
            context,
            title: 'تعذّر إرسال رمز التحقق',
            subtitle: message,
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // خلفية بيضاء نقية مثل الصورة
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              // أيقونة القفل الخلفية الدائرية الناعمة
              Center(
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: const Color(
                      0xFFF3F7FA,
                    ), // لون دائرة ناعم خلف الأيقونة
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.lock_person_outlined,
                    size: 70,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // عنوان واضح بدون تدرج لوني لتطابق التصميم الحديث
              const Text(
                'نسيت كلمة المرور؟',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'أدخل بريدك الإلكتروني وسنرسل لك رابطاً لإعادة تعيين كلمة المرور الخاصة بك.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // حقول الإدخال ممتدة بشكل نظيف
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    CustomTextField(
                      controller: _emailController,
                      hint: 'example@email.com',
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'الرجاء إدخال البريد الإلكتروني';
                        }
                        if (!RegExp(r'^.+@.+\..+$').hasMatch(value)) {
                          return 'البريد الإلكتروني غير صالح';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 32),
                    AuthButton(
                      text: 'إرسال رابط التعيين',
                      onPressed: _sendResetOtp,
                      isLoading: _isLoading,
                      gradient: AppColors.primaryGradient,
                    ),
                    const SizedBox(height: 24),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'تذكرت كلمة المرور؟ ',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                          const Text(
                            'تسجيل الدخول',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}
